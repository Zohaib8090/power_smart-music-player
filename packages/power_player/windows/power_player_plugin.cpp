#include "power_player_plugin.h"

#include <windows.h>
#include <mfapi.h>
#include <mfmediaengine.h>
#include <mfidl.h>
#include <shlwapi.h>
#include <propvarutil.h>

#include <flutter/method_channel.h>
#include <flutter/event_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>
#include <iostream>
#include <vector>
#include <cstdint>
#include <functional>

#pragma comment(lib, "mfplat.lib")
#pragma comment(lib, "mfuuid.lib")
#pragma comment(lib, "shlwapi.lib")
#pragma comment(lib, "propsys.lib")

namespace power_player {

// --- WinPlayerNotify Implementation ---

WinPlayerNotify::WinPlayerNotify(std::function<void(DWORD, DWORD_PTR, DWORD)> callback)
    : callback_(callback), ref_count_(1) {}

STDMETHODIMP WinPlayerNotify::QueryInterface(REFIID riid, void** ppv) {
  if (riid == __uuidof(IUnknown) || riid == __uuidof(IMFMediaEngineNotify)) {
    *ppv = static_cast<IMFMediaEngineNotify*>(this);
    AddRef();
    return S_OK;
  }
  *ppv = nullptr;
  return E_NOINTERFACE;
}

STDMETHODIMP_(ULONG) WinPlayerNotify::AddRef() {
  return InterlockedIncrement(&ref_count_);
}

STDMETHODIMP_(ULONG) WinPlayerNotify::Release() {
  ULONG count = InterlockedDecrement(&ref_count_);
  if (count == 0) delete this;
  return count;
}

STDMETHODIMP WinPlayerNotify::EventNotify(DWORD event, DWORD_PTR param1, DWORD param2) {
  callback_(event, param1, param2);
  return S_OK;
}

// --- WinPlayer Implementation ---

WinPlayer::WinPlayer(std::string id, flutter::EventSink<flutter::EncodableValue>* sink)
    : player_id_(id), event_sink_(sink) {
  MFStartup(MF_VERSION);
  timer_queue_ = CreateTimerQueue();
  
  HRESULT hr = MFCreateAttributes(&attributes_, 1);
  if (SUCCEEDED(hr)) {
    auto callback = [this](DWORD event, DWORD_PTR p1, DWORD p2) {
      if (!this->event_sink_) return;
      
      flutter::EncodableMap data;
      data[flutter::EncodableValue("playerId")] = flutter::EncodableValue(this->player_id_);

      if (event == MF_MEDIA_ENGINE_EVENT_ERROR) {
        unsigned short code = 0;
        if (this->engine_) {
            IMFMediaError* err = nullptr;
            if (SUCCEEDED(this->engine_->GetError(&err)) && err) {
                code = err->GetErrorCode();
                err->Release();
            }
        }
        data[flutter::EncodableValue("type")] = flutter::EncodableValue("error");
        data[flutter::EncodableValue("message")] = flutter::EncodableValue("Media Foundation Playback Error");
        data[flutter::EncodableValue("errorCode")] = flutter::EncodableValue((int)code);
        this->event_sink_->Success(flutter::EncodableValue(data));
      } else if (event == MF_MEDIA_ENGINE_EVENT_CANPLAY) {
        data[flutter::EncodableValue("type")] = flutter::EncodableValue("duration");
        double duration = 0;
        if (this->engine_) duration = this->engine_->GetDuration();
        data[flutter::EncodableValue("duration")] = flutter::EncodableValue((int64_t)(duration * 1000));
        this->event_sink_->Success(flutter::EncodableValue(data));

        data[flutter::EncodableValue("type")] = flutter::EncodableValue("state");
        data[flutter::EncodableValue("state")] = flutter::EncodableValue("ready");
        this->event_sink_->Success(flutter::EncodableValue(data));
      } else if (event == MF_MEDIA_ENGINE_EVENT_PLAYING) {
        data[flutter::EncodableValue("type")] = flutter::EncodableValue("isPlaying");
        data[flutter::EncodableValue("isPlaying")] = flutter::EncodableValue(true);
        this->event_sink_->Success(flutter::EncodableValue(data));
      } else if (event == MF_MEDIA_ENGINE_EVENT_PAUSE) {
        data[flutter::EncodableValue("type")] = flutter::EncodableValue("isPlaying");
        data[flutter::EncodableValue("isPlaying")] = flutter::EncodableValue(false);
        this->event_sink_->Success(flutter::EncodableValue(data));
      } else if (event == MF_MEDIA_ENGINE_EVENT_ENDED) {
        data[flutter::EncodableValue("type")] = flutter::EncodableValue("state");
        data[flutter::EncodableValue("state")] = flutter::EncodableValue("ended");
        this->event_sink_->Success(flutter::EncodableValue(data));
      }
    };

    WinPlayerNotify* notify_impl = new WinPlayerNotify(callback);
    notify_obj_ = static_cast<IUnknown*>(notify_impl);
    
    attributes_->SetUnknown(MF_MEDIA_ENGINE_CALLBACK, notify_obj_);
    attributes_->SetUINT32(MF_MEDIA_ENGINE_VIDEO_OUTPUT_FORMAT, DXGI_FORMAT_B8G8R8A8_UNORM);
    
    IMFMediaEngineClassFactory* factory;
    if (SUCCEEDED(CoCreateInstance(CLSID_MFMediaEngineClassFactory, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&factory)))) {
      if (SUCCEEDED(factory->CreateInstance(0, attributes_, &engine_))) {
          if (engine_) engine_->SetVolume(1.0);
      }
      factory->Release();
    }
  }
}

WinPlayer::~WinPlayer() {
  Dispose();
  if (engine_) { engine_->Shutdown(); engine_->Release(); }
  if (attributes_) attributes_->Release();
  if (notify_obj_) notify_obj_->Release();
  MFShutdown();
}

void WinPlayer::SetDataSource(const std::string& url, const std::map<std::string, std::string>& headers) {
  if (!engine_) return;
  size_t size = url.length() + 1;
  std::vector<wchar_t> wurl(size);
  MultiByteToWideChar(CP_UTF8, 0, url.c_str(), -1, wurl.data(), (int)size);
  BSTR bstr = SysAllocString(wurl.data());
  engine_->SetSource(bstr);
  engine_->Load();
  SysFreeString(bstr);
}

void WinPlayer::Play() { 
  if (engine_) {
    engine_->Play();
    if (!timer_) {
      CreateTimerQueueTimer(&timer_, timer_queue_, (WAITORTIMERCALLBACK)OnTimer, this, 0, 1000, WT_EXECUTEDEFAULT);
    }
  }
}
void WinPlayer::Pause() { 
  if (engine_) {
    engine_->Pause();
    if (timer_) {
      DeleteTimerQueueTimer(timer_queue_, timer_, nullptr);
      timer_ = nullptr;
    }
  }
}
void WinPlayer::Stop() { 
  if (engine_) {
    engine_->Pause();
    engine_->SetCurrentTime(0.0);
    if (timer_) {
      DeleteTimerQueueTimer(timer_queue_, timer_, nullptr);
      timer_ = nullptr;
    }
  }
}
void WinPlayer::Seek(long long pos_ms) { if (engine_) engine_->SetCurrentTime((double)pos_ms / 1000.0); }
void WinPlayer::Dispose() { 
  Stop(); 
  if (timer_queue_) {
    DeleteTimerQueue(timer_queue_);
    timer_queue_ = nullptr;
  }
}

void WinPlayer::OnTimer(PVOID lpParameter, BOOLEAN TimerOrWaitFired) {
  WinPlayer* player = static_cast<WinPlayer*>(lpParameter);
  player->SendProgress();
}

void WinPlayer::SendProgress() {
  if (!engine_ || !event_sink_) return;
  
  flutter::EncodableMap data;
  data[flutter::EncodableValue("playerId")] = flutter::EncodableValue(player_id_);
  data[flutter::EncodableValue("type")] = flutter::EncodableValue("progress");
  data[flutter::EncodableValue("position")] = flutter::EncodableValue((int64_t)(engine_->GetCurrentTime() * 1000));
  data[flutter::EncodableValue("duration")] = flutter::EncodableValue((int64_t)(engine_->GetDuration() * 1000));
  
  event_sink_->Success(flutter::EncodableValue(data));
}

// --- PowerPlayerPlugin Implementation ---

void PowerPlayerPlugin::RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar) {
  const flutter::StandardMethodCodec& codec = flutter::StandardMethodCodec::GetInstance();
  
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "power_player", &codec);

  auto plugin_obj = std::make_unique<PowerPlayerPlugin>();

  auto event_channel = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          registrar->messenger(), "power_player_events", &codec);

  event_channel->SetStreamHandler(std::make_unique<PlayerStreamHandler>(&plugin_obj->event_sink_));

  channel->SetMethodCallHandler([plugin_pointer = plugin_obj.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin_obj));
}

PowerPlayerPlugin::PowerPlayerPlugin() {}
PowerPlayerPlugin::~PowerPlayerPlugin() {}

void PowerPlayerPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());
  if (!args) {
    result->Error("400", "Arguments must be a map");
    return;
  }

  auto playerId_it = args->find(flutter::EncodableValue("playerId"));
  if (playerId_it == args->end() || !std::holds_alternative<std::string>(playerId_it->second)) {
    result->Error("400", "Missing or invalid playerId");
    return;
  }
  std::string playerId = std::get<std::string>(playerId_it->second);

  if (method_call.method_name().compare("initialize") == 0) {
    if (players_.find(playerId) == players_.end()) {
        players_.emplace(playerId, std::make_unique<WinPlayer>(playerId, event_sink_.get())); 
    }
    result->Success(flutter::EncodableValue(0)); 
  } else if (method_call.method_name().compare("setDataSource") == 0) {
    auto url_it = args->find(flutter::EncodableValue("url"));
    if (url_it == args->end() || !std::holds_alternative<std::string>(url_it->second)) {
      result->Error("400", "Missing or invalid url");
      return;
    }
    std::string url = std::get<std::string>(url_it->second);
    
    std::map<std::string, std::string> headers;
    auto headers_it = args->find(flutter::EncodableValue("headers"));
    if (headers_it != args->end() && !headers_it->second.IsNull()) {
        const auto& enc_headers = std::get<flutter::EncodableMap>(headers_it->second);
        for (const auto& kv : enc_headers) {
            if (std::holds_alternative<std::string>(kv.first) && std::holds_alternative<std::string>(kv.second)) {
                headers[std::get<std::string>(kv.first)] = std::get<std::string>(kv.second);
            }
        }
    }

    auto it = players_.find(playerId);
    if (it != players_.end()) {
      it->second->SetDataSource(url, headers);
      result->Success(nullptr);
    } else {
      result->Error("404", "Player not initialized");
    }
  } else if (method_call.method_name().compare("play") == 0) {
    auto it = players_.find(playerId);
    if (it != players_.end()) {
      it->second->Play();
      result->Success(nullptr);
    }
  } else if (method_call.method_name().compare("pause") == 0) {
    auto it = players_.find(playerId);
    if (it != players_.end()) {
      it->second->Pause();
      result->Success(nullptr);
    }
  } else if (method_call.method_name().compare("stop") == 0) {
    auto it = players_.find(playerId);
    if (it != players_.end()) {
      it->second->Stop();
      result->Success(nullptr);
    }
  } else if (method_call.method_name().compare("seek") == 0) {
    auto pos_it = args->find(flutter::EncodableValue("position"));
    if (pos_it != args->end()) {
        int64_t pos = 0;
        if (std::holds_alternative<int32_t>(pos_it->second)) {
            pos = std::get<int32_t>(pos_it->second);
        } else if (std::holds_alternative<int64_t>(pos_it->second)) {
            pos = std::get<int64_t>(pos_it->second);
        }
        
        auto it = players_.find(playerId);
        if (it != players_.end()) {
          it->second->Seek(pos);
          result->Success(nullptr);
        }
    }
  } else if (method_call.method_name().compare("dispose") == 0) {
    players_.erase(playerId);
    result->Success(nullptr);
  } else {
    result->NotImplemented();
  }
}

// --- PlayerStreamHandler Implementation ---

PlayerStreamHandler::PlayerStreamHandler(std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>* sink) : sink_(sink) {}

std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> PlayerStreamHandler::OnListenInternal(
    const flutter::EncodableValue* args, std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events) {
  *sink_ = std::move(events);
  return nullptr;
}

std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> PlayerStreamHandler::OnCancelInternal(const flutter::EncodableValue* args) {
  *sink_ = nullptr;
  return nullptr;
}

}  // namespace power_player
