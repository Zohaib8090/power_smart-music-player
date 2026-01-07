package com.example.local_audio

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** LocalAudioPlugin */
class LocalAudioPlugin :
    FlutterPlugin,
    MethodCallHandler {
    // The MethodChannel that will the communication between Flutter and native Android
    //
    // This local reference serves to register the plugin with the Flutter Engine and unregister it
    // when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var context: android.content.Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "local_audio")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getTracks" -> {
                val tracks = getTracks()
                result.success(tracks)
            }
            else -> result.notImplemented()
        }
    }

    private fun getTracks(): List<Map<String, Any?>> {
        val trackList = mutableListOf<Map<String, Any?>>()
        val uri = android.provider.MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            android.provider.MediaStore.Audio.Media._ID,
            android.provider.MediaStore.Audio.Media.TITLE,
            android.provider.MediaStore.Audio.Media.ARTIST,
            android.provider.MediaStore.Audio.Media.ALBUM,
            android.provider.MediaStore.Audio.Media.DURATION,
            android.provider.MediaStore.Audio.Media.DATA,
            android.provider.MediaStore.Audio.Media.ALBUM_ID
        )

        val selection = "${android.provider.MediaStore.Audio.Media.IS_MUSIC} != 0"
        val sortOrder = "${android.provider.MediaStore.Audio.Media.TITLE} ASC"

        val cursor = context.contentResolver.query(uri, projection, selection, null, sortOrder)

        cursor?.use {
            val idColumn = it.getColumnIndexOrThrow(android.provider.MediaStore.Audio.Media._ID)
            val titleColumn = it.getColumnIndexOrThrow(android.provider.MediaStore.Audio.Media.TITLE)
            val artistColumn = it.getColumnIndexOrThrow(android.provider.MediaStore.Audio.Media.ARTIST)
            val albumColumn = it.getColumnIndexOrThrow(android.provider.MediaStore.Audio.Media.ALBUM)
            val durationColumn = it.getColumnIndexOrThrow(android.provider.MediaStore.Audio.Media.DURATION)
            val dataColumn = it.getColumnIndexOrThrow(android.provider.MediaStore.Audio.Media.DATA)
            val albumIdColumn = it.getColumnIndexOrThrow(android.provider.MediaStore.Audio.Media.ALBUM_ID)

            while (it.moveToNext()) {
                val id = it.getLong(idColumn)
                val title = it.getString(titleColumn)
                val artist = it.getString(artistColumn)
                val album = it.getString(albumColumn)
                val duration = it.getLong(durationColumn)
                val path = it.getString(dataColumn)
                val albumId = it.getLong(albumIdColumn)

                val contentUri = android.content.ContentUris.withAppendedId(
                    android.provider.MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                    id
                )

                val trackMap = mapOf(
                    "id" to id.toString(),
                    "title" to title,
                    "artist" to artist,
                    "album" to album,
                    "duration" to duration,
                    "path" to path,
                    "albumId" to albumId.toString(),
                    "uri" to contentUri.toString()
                )
                trackList.add(trackMap)
            }
        }
        return trackList
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
