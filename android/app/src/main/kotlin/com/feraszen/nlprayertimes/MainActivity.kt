package com.feraszen.nlprayertimes

import android.content.ContentValues
import android.content.Intent
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val importer = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nl_prayer_times/custom_adhan")
            .setMethodCallHandler { call, result ->
                if (call.method != "importAudio") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val path = call.argument<String>("path")
                importer.execute {
                    try {
                        require(!path.isNullOrBlank()) { "Choose a local audio file" }
                        val audio = importAudio(File(path))
                        runOnUiThread { result.success(audio) }
                    } catch (error: Exception) {
                        runOnUiThread { result.error("AUDIO_IMPORT_FAILED", error.message, null) }
                    }
                }
            }
    }

    private fun importAudio(source: File): Map<String, String> {
        require(source.isFile && source.length() in 1..(50L * 1024 * 1024)) {
            "Choose an audio file smaller than 50 MB"
        }
        val extension = source.extension.lowercase()
        val mime = mapOf("mp3" to "audio/mpeg", "wav" to "audio/wav",
            "m4a" to "audio/mp4", "ogg" to "audio/ogg")[extension]
        require(mime != null) { "Supported audio: MP3, WAV, M4A, OGG" }
        val metadata = MediaMetadataRetriever()
        try {
            metadata.setDataSource(source.absolutePath)
            require((metadata.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                ?.toLongOrNull() ?: 0) > 0) { "This audio file cannot be played" }
        } finally {
            metadata.release()
        }
        val digest = MessageDigest.getInstance("SHA-256")
        source.inputStream().use { input ->
            val buffer = ByteArray(8192)
            while (true) {
                val count = input.read(buffer)
                if (count < 0) break
                digest.update(buffer, 0, count)
            }
        }
        val hash = digest.digest().joinToString("") { "%02x".format(it) }
        val directory = File(filesDir, "notification_audio").apply { mkdirs() }
        val copy = File(directory, "$hash.$extension")
        if (!copy.exists()) {
            val temporary = File(directory, "$hash.tmp")
            try {
                source.inputStream().use { input -> temporary.outputStream().use { input.copyTo(it) } }
                check(temporary.renameTo(copy)) { "Unable to save audio" }
            } finally { temporary.delete() }
        }
        val prefs = getSharedPreferences("imported_adhan", MODE_PRIVATE)
        val saved = prefs.getString(hash, null)?.let(Uri::parse)
        val existing = saved?.takeIf {
            try { contentResolver.openInputStream(it)?.use { true } ?: false }
            catch (_: Exception) { false }
        }
        val uri = existing ?: if (Build.VERSION.SDK_INT >= 29) {
            // App-owned MediaStore audio needs no broad storage permission and
            // remains readable by Android's notification player after reboot.
            val values = ContentValues().apply {
                put(MediaStore.Audio.Media.DISPLAY_NAME, "NL_Prayer_$hash.$extension")
                put(MediaStore.Audio.Media.MIME_TYPE, mime)
                put(MediaStore.Audio.Media.RELATIVE_PATH, "${Environment.DIRECTORY_NOTIFICATIONS}/NLPrayerTimes")
                put(MediaStore.Audio.Media.IS_NOTIFICATION, 1)
                put(MediaStore.Audio.Media.IS_PENDING, 1)
            }
            val inserted = checkNotNull(contentResolver.insert(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, values))
            try {
                checkNotNull(contentResolver.openOutputStream(inserted)).use { output ->
                    copy.inputStream().use { it.copyTo(output) }
                }
                contentResolver.update(inserted, ContentValues().apply {
                    put(MediaStore.Audio.Media.IS_PENDING, 0)
                }, null, null)
                inserted
            } catch (error: Exception) {
                contentResolver.delete(inserted, null, null)
                throw error
            }
        } else {
            FileProvider.getUriForFile(this, "$packageName.adhan_files", copy)
        }
        if (Build.VERSION.SDK_INT < 29) {
            for (pkg in listOf("android", "com.android.systemui")) {
                grantUriPermission(pkg, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
        }
        check(prefs.edit().putString(hash, uri.toString()).commit())
        // Include URI in identity: a deleted/reimported MediaStore item must
        // receive a new channel rather than reuse the channel's stale URI.
        val token = MessageDigest.getInstance("SHA-256").digest(uri.toString().toByteArray())
            .joinToString("") { "%02x".format(it) }
        return mapOf("uri" to uri.toString(), "token" to token, "path" to copy.absolutePath)
    }
}
