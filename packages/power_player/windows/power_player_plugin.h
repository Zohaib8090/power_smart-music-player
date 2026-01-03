#ifndef FLUTTER_PLUGIN_POWER_PLAYER_PLUGIN_H_
#define FLUTTER_PLUGIN_POWER_PLAYER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/event_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <windows.h>
#include <mfapi.h>
#include <mfmediaengine.h>
#include <mfidl.h>

#include <memory>
#include <map>
#include <string>
#include <functional>
#include <vector>

namespace power_player {

class WinPlayerNotify : public IMFMediaEngineNotify {
 public:
  WinPlayerNotify(std::function<void(DWORD, DWORD_PTR, DWORD)> callback);
  ~WinPlayerNotify() = default;

  STDMETHODIMP QueryInterface(REFIID riid, void** ppv) override;
  STDMETHODIMP_(ULONG) AddRef() override;
  STDMETHODIMP_(ULONG) Release() override;
  STDMETHODIMP EventNotify(DWORD event, DWORD_PTR param1, DWORD param2) override;

 private:
  std::function<void(DWORD, DWORD_PTR, DWORD)> callback_;
  long ref_count_;
};

class WinPlayer {
 public:
  WinPlayer(std::string id, flutter::EventSink<flutter::EncodableValue>* sink);
  ~WinPlayer();

  void SetDataSource(const std::string& url, const std::map<std::string, std::string>& headers);
  void Play();
  void Pause();
  void Stop();
  void Seek(long long pos_ms);
  void Dispose();

 private:
  void SendProgress();
  static void CALLBACK OnTimer(PVOID lpParameter, BOOLEAN TimerOrWaitFired);

  std::string player_id_;
  flutter::EventSink<flutter::EncodableValue>* event_sink_;
  IMFAttributes* attributes_ = nullptr;
  IMFMediaEngine* engine_ = nullptr;
  IUnknown* notify_obj_ = nullptr;
  HANDLE timer_queue_ = nullptr;
  HANDLE timer_ = nullptr;
};

class PowerPlayerPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);
  PowerPlayerPlugin();
  virtual ~PowerPlayerPlugin();
  void HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue> &call,
                        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

 private:
  std::map<std::string, std::unique_ptr<WinPlayer>> players_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;
};

class PlayerStreamHandler : public flutter::StreamHandler<flutter::EncodableValue> {
 public:
  PlayerStreamHandler(std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>* sink);
 protected:
  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> OnListenInternal(
      const flutter::EncodableValue* args, std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events) override;
  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> OnCancelInternal(const flutter::EncodableValue* args) override;
 private:
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>* sink_;
};

}  // namespace power_player

#endif  // FLUTTER_PLUGIN_POWER_PLAYER_PLUGIN_H_
