package com.zohaib.powersmart.power_smart

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity
import android.content.Intent
import android.net.Uri

// NewPipe Imports
import org.schabi.newpipe.extractor.NewPipe
import org.schabi.newpipe.extractor.ServiceList
import org.schabi.newpipe.extractor.downloader.Downloader
import org.schabi.newpipe.extractor.downloader.Response
import org.schabi.newpipe.extractor.services.youtube.extractors.YoutubeStreamExtractor
import org.schabi.newpipe.extractor.stream.StreamInfo
import org.schabi.newpipe.extractor.localization.Localization
import java.net.HttpURLConnection
import java.net.URL
import java.util.Locale

// Coroutines
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class SimpleDownloader : Downloader() {
    // The token extracted from your browser
    private val PO_TOKEN = "MlNU2dufnNaLA1Tl2-VST2cz5Db6popcgluBiNK5_D1cf7DJBhaMqtMBgi7Gj1pxs_WcsmWdsSjL1HBAzWkT3yKW2TJrE_wkHZZAAxc2lRB4Day5Zw=="
    
    // Mutable cookies that can be updated from Flutter
    var cookies: String? = null

    override fun execute(request: org.schabi.newpipe.extractor.downloader.Request): Response {
        val url = URL(request.url())
        val con = url.openConnection() as HttpURLConnection
        
        // Use a consistent User-Agent matching the latest 2026 Chrome version
        con.setRequestProperty("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36")
        
        // Add comprehensive browser headers to avoid bot detection
        con.setRequestProperty("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8")
        con.setRequestProperty("Accept-Language", "en-US,en;q=0.9")
        con.setRequestProperty("Accept-Encoding", "gzip, deflate, br")
        con.setRequestProperty("DNT", "1")
        con.setRequestProperty("Connection", "keep-alive")
        con.setRequestProperty("Upgrade-Insecure-Requests", "1")
        con.setRequestProperty("Sec-Fetch-Dest", "document")
        con.setRequestProperty("Sec-Fetch-Mode", "navigate")
        con.setRequestProperty("Sec-Fetch-Site", "none")
        con.setRequestProperty("Sec-Fetch-User", "?1")
        con.setRequestProperty("sec-ch-ua", "\"Chromium\";v=\"140\", \"Google Chrome\";v=\"140\", \"Not-A.Brand\";v=\"99\"")
        con.setRequestProperty("sec-ch-ua-mobile", "?0")
        con.setRequestProperty("sec-ch-ua-platform", "\"Windows\"")
        
        // Add Cookies if available
        cookies?.let {
            if (it.isNotEmpty()) {
                con.setRequestProperty("Cookie", it)
            }
        }
        
        // Pass PoToken and Origin/Referer for YouTube's internal API calls
        if (request.url().contains("youtube.com") || request.url().contains("googlevideo.com")) {
            con.setRequestProperty("X-YouTube-Po-Token", PO_TOKEN)
            con.setRequestProperty("Origin", "https://www.youtube.com")
            con.setRequestProperty("Referer", "https://www.youtube.com/")
        }

        request.headers().forEach { (key, value) -> con.setRequestProperty(key, value[0]) }
        
        val responseCode = con.responseCode
        val responseMessage = con.responseMessage
        val inputStream = if (responseCode in 200..299) con.inputStream else con.errorStream
        val responseBody = inputStream?.bufferedReader()?.use { it.readText() }
        
        return Response(responseCode, responseMessage, con.headerFields, responseBody, request.url())
    }
}

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "extractor_channel"
    private val INTENT_CHANNEL = "intent_channel"
    private var pendingIntentUri: String? = null
    private val simpleDownloader = SimpleDownloader()

    override fun onCreate(saved: android.os.Bundle?) {
        super.onCreate(saved)
        handleIntent(intent)
    }
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.action == Intent.ACTION_VIEW) {
            val uri: Uri? = intent.data
            uri?.let {
                pendingIntentUri = it.toString()
                println("📂 Received File Intent: $pendingIntentUri")
                // If engine is already configured, send immediately
                flutterEngine?.let { engine ->
                    MethodChannel(engine.dartExecutor.binaryMessenger, INTENT_CHANNEL)
                        .invokeMethod("onPlayFile", pendingIntentUri)
                }
            }
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INTENT_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getPendingFile") {
                result.success(pendingIntentUri)
                pendingIntentUri = null
            } else {
                result.notImplemented()
            }
        }
        try {
            NewPipe.init(simpleDownloader, Localization.fromLocale(Locale.US))
            println("✅ NewPipe initialized with 2026 User-Agent and poToken headers")
        } catch (e: Throwable) {
            println("❌ NewPipe.init Failed: ${e.message}")
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "extract") {
                val videoId = call.argument<String>("videoId") ?: ""
                val poToken = call.argument<String>("poToken") ?: "MlNU2dufnNaLA1Tl2-VST2cz5Db6popcgluBiNK5_D1cf7DJBhaMqtMBgi7Gj1pxs_WcsmWdsSjL1HBAzWkT3yKW2TJrE_wkHZZAAxc2lRB4Day5Zw=="
                val cookies = call.argument<String>("cookies")

                // Update cookies in the downloader if provided
                cookies?.let {
                     simpleDownloader.cookies = it
                     println("🍪 Updated Cookies for request")
                }
                
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        println("🔍 Starting NewPipe Extraction for: $videoId")
                        val service = ServiceList.YouTube
                        val url = "https://www.youtube.com/watch?v=$videoId"
                        
                        // Use explicit extractor for better control and logging
                        val extractor = service.getStreamExtractor(url) as YoutubeStreamExtractor
                        println("✅ Extractor created for $url")
                        
                        // Placeholder for PoToken if we find a way to set it on extractor
                        // extractor.setPoToken(poToken)
                        
                        // Use a specific IO context for the decoding/fetching process to be thread-safe
                        val streamInfo = withContext(Dispatchers.IO) {
                            StreamInfo.getInfo(extractor)
                        }
                        println("✅ StreamInfo extracted: ${streamInfo.name}")
                        
                        val audioStreams = streamInfo.audioStreams
                        val videoStreams = streamInfo.videoStreams

                        println("📊 Streams found: Audio=${audioStreams.size}, Video=${videoStreams.size}")

                        // Prioritize audio-only, fallback to video (muxed)
                        val bestAudio = audioStreams.maxByOrNull { it.bitrate } ?: videoStreams.maxByOrNull { it.bitrate }
                        val rawUrl = bestAudio?.url

                        if (rawUrl == null) {
                            println("❌ No playable streams found for $videoId")
                            withContext(Dispatchers.Main) {
                                result.error("NO_STREAMS", "YouTube returned 0 playable streams for ID: $videoId", null)
                            }
                            return@launch
                        }

                        // Append PoToken to bypass 403 blocks
                        val finalUrl = if (rawUrl.contains("?")) "$rawUrl&pot=$poToken" else "$rawUrl?pot=$poToken"
                        println("🚀 Final Playback URL: ${finalUrl.take(100)}...")

                        val responseMap = mapOf(
                            "url" to finalUrl,
                            "title" to streamInfo.name,
                            "uploader" to streamInfo.uploaderName,
                            "duration" to streamInfo.duration,
                            "poTokenUsed" to poToken,
                            "userAgent" to "Mozilla/5.0 (Linux; Android 13; SM-A266B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36"
                        )

                        withContext(Dispatchers.Main) {
                            result.success(responseMap)
                        }

                    } catch (e: Exception) {
                        println("❌ NewPipe Extraction Failed: ${e.javaClass.simpleName}: ${e.message}")
                        e.printStackTrace()
                        val detailedError = "${e.javaClass.simpleName}: ${e.message}"
                        withContext(Dispatchers.Main) {
                            result.error("EXTRACTION_EXCEPTION", detailedError, null)
                        }
                    }
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
