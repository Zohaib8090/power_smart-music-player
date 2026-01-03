package com.example.power_player

import android.content.Context
import android.view.Surface
import androidx.annotation.OptIn
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.view.TextureRegistry

/** PowerPlayerPlugin */
class PowerPlayerPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context
    private lateinit var textureRegistry: TextureRegistry
    
    private var eventSink: EventChannel.EventSink? = null
    private val players = mutableMapOf<String, ExoPlayer>()
    private val textures = mutableMapOf<String, TextureRegistry.SurfaceTextureEntry>()
    private val handler = android.os.Handler(android.os.Looper.getMainLooper())
    private val progressRunnables = mutableMapOf<String, Runnable>()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "power_player")
        channel.setMethodCallHandler(this)
        
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "power_player_events")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                eventSink = sink
            }
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
        
        context = flutterPluginBinding.applicationContext
        textureRegistry = flutterPluginBinding.textureRegistry
    }

    @OptIn(UnstableApi::class)
    override fun onMethodCall(call: MethodCall, result: Result) {
        val playerId = call.argument<String>("playerId") ?: return result.error("400", "Missing playerId", null)

        when (call.method) {
            "initialize" -> {
                if (!players.containsKey(playerId)) {
                    val entry = textureRegistry.createSurfaceTexture()
                    val player = ExoPlayer.Builder(context).build()
                    
                    val audioAttributes = AudioAttributes.Builder()
                        .setUsage(C.USAGE_MEDIA)
                        .setContentType(C.AUDIO_CONTENT_TYPE_MUSIC)
                        .build()
                    player.setAudioAttributes(audioAttributes, true)

                    player.setVideoSurface(Surface(entry.surfaceTexture()))
                    
                    player.addListener(object : Player.Listener {
                        override fun onPlayerError(error: PlaybackException) {
                            sendEvent(playerId, "error", mapOf("message" to error.message, "errorCode" to error.errorCode))
                        }
                        
                        override fun onPlaybackStateChanged(state: Int) {
                            val stateStr = when(state) {
                                Player.STATE_BUFFERING -> "buffering"
                                Player.STATE_READY -> {
                                    sendEvent(playerId, "duration", mapOf("duration" to player.duration))
                                    "ready"
                                }
                                Player.STATE_ENDED -> "ended"
                                Player.STATE_IDLE -> "idle"
                                else -> "unknown"
                            }
                            sendEvent(playerId, "state", mapOf("state" to stateStr))
                            
                            if (state == Player.STATE_READY) {
                                startProgressUpdates(playerId)
                            } else {
                                stopProgressUpdates(playerId)
                            }
                        }

                        override fun onIsPlayingChanged(isPlaying: Boolean) {
                            sendEvent(playerId, "isPlaying", mapOf("isPlaying" to isPlaying))
                            if (isPlaying) {
                                startProgressUpdates(playerId)
                            } else {
                                stopProgressUpdates(playerId)
                            }
                        }
                    })
                    
                    players[playerId] = player
                    textures[playerId] = entry
                    
                    result.success(entry.id())
                } else {
                    result.success(textures[playerId]?.id())
                }
            }
            "setDataSource" -> {
                val url = call.argument<String>("url") ?: return result.error("400", "Missing url", null)
                val headers = call.argument<Map<String, String>>("headers")
                
                val player = players[playerId] ?: return result.error("404", "Player not initialized", null)
                
                val httpDataSourceFactory = DefaultHttpDataSource.Factory()
                headers?.let { 
                    httpDataSourceFactory.setDefaultRequestProperties(it) 
                }
                
                val mediaSourceFactory = DefaultMediaSourceFactory(context)
                    .setDataSourceFactory(httpDataSourceFactory)
                
                val mediaItem = MediaItem.fromUri(url)
                val mediaSource = mediaSourceFactory.createMediaSource(mediaItem)
                
                player.setMediaSource(mediaSource)
                player.prepare()
                result.success(null)
            }
            "play" -> {
                players[playerId]?.play()
                result.success(null)
            }
            "pause" -> {
                players[playerId]?.pause()
                result.success(null)
            }
            "stop" -> {
                players[playerId]?.stop()
                result.success(null)
            }
            "seek" -> {
                val position = call.argument<Int>("position")?.toLong() ?: 0L
                players[playerId]?.seekTo(position)
                result.success(null)
            }
            "setVolume" -> {
                val volume = call.argument<Double>("volume")?.toFloat() ?: 1.0f
                players[playerId]?.volume = volume
                result.success(null)
            }
            "setEngineConfig" -> {
                val config = call.argument<Map<String, Any>>("config") ?: return result.success(null)
                val playerId = call.argument<String>("playerId") ?: return result.error("400", "Missing playerId", null)
                val player = players[playerId] ?: return result.error("404", "Player not initialized", null)
                
                // 1. AAudio / Output Plugin selection
                // Note: Changing output sink usually requires re-initializing the player.
                // For now, we'll log it and prepare for next initialization.
                
                // 2. Gapless / Skip Silence
                val gapless = config["gapless"] as? Boolean ?: true
                player.skipSilenceEnabled = !gapless 
                
                // 3. Bit Depth & Sample Rate (Audiophile settings)
                val bitDepth = config["bit_depth"] as? String ?: "16"
                val sampleRate = config["sample_rate"] as? String ?: "44.1"
                
                // In a production app, these would be used to configure 
                // DefaultAudioSink.AudioProcessor or re-init the player.
                println("Acoustic Setting | Bit Depth: $bitDepth, Sample Rate: $sampleRate kHz")
                
                // 4. Simple Volume Sync
                val volume = (config["volume"] as? Double)?.toFloat() ?: 1.0f
                player.volume = volume
                
                result.success(null)
            }
            "dispose" -> {
                players[playerId]?.release()
                players.remove(playerId)
                textures[playerId]?.release()
                textures.remove(playerId)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun sendEvent(playerId: String, type: String, data: Map<String, Any?>) {
        val event = mutableMapOf<String, Any?>("playerId" to playerId, "type" to type)
        event.putAll(data)
        eventSink?.success(event)
    }

    private fun startProgressUpdates(playerId: String) {
        if (progressRunnables.containsKey(playerId)) return
        
        val runnable = object : Runnable {
            override fun run() {
                val player = players[playerId] ?: return
                if (player.isPlaying) {
                    sendEvent(playerId, "progress", mapOf(
                        "position" to player.currentPosition,
                        "duration" to player.duration
                    ))
                }
                handler.postDelayed(this, 1000)
            }
        }
        progressRunnables[playerId] = runnable
        handler.post(runnable)
    }

    private fun stopProgressUpdates(playerId: String) {
        progressRunnables[playerId]?.let { handler.removeCallbacks(it) }
        progressRunnables.remove(playerId)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        progressRunnables.values.forEach { handler.removeCallbacks(it) }
        progressRunnables.clear()
        players.values.forEach { it.release() }
        players.clear()
        textures.values.forEach { it.release() }
        textures.clear()
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }
}
