package com.example.flutter_fixit_application

import android.content.ContentValues
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.IOException

class MainActivity : FlutterActivity() {
	private val channelName = "fixit/attachment_saver"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				if (call.method != "saveAttachment") {
					result.notImplemented()
					return@setMethodCallHandler
				}

				val sourcePath = call.argument<String>("sourcePath")?.trim().orEmpty()
				val requestedName = call.argument<String>("fileName")?.trim().orEmpty()
				val mimeType = call.argument<String>("mimeType")?.trim().orEmpty()
				val isImage = call.argument<Boolean>("isImage") ?: false

				if (sourcePath.isEmpty()) {
					result.error("INVALID_PATH", "Invalid source file path.", null)
					return@setMethodCallHandler
				}

				val sourceFile = File(sourcePath)
				if (!sourceFile.exists()) {
					result.error("MISSING_FILE", "Attachment file is missing.", null)
					return@setMethodCallHandler
				}

				try {
					val savedUri = saveToMediaStore(
						sourceFile = sourceFile,
						requestedName = if (requestedName.isEmpty()) sourceFile.name else requestedName,
						mimeType = if (mimeType.isEmpty()) "application/octet-stream" else mimeType,
						isImage = isImage,
					)
					result.success(savedUri.toString())
				} catch (error: Exception) {
					result.error("SAVE_FAILED", error.message ?: "Unable to save attachment.", null)
				}
			}
	}

	@Throws(IOException::class)
	private fun saveToMediaStore(
		sourceFile: File,
		requestedName: String,
		mimeType: String,
		isImage: Boolean,
	): Uri {
		val resolver = applicationContext.contentResolver
		val collectionUri = if (isImage) {
			MediaStore.Images.Media.EXTERNAL_CONTENT_URI
		} else {
			MediaStore.Downloads.EXTERNAL_CONTENT_URI
		}

		val relativePath = if (isImage) {
			Environment.DIRECTORY_PICTURES + "/FixIt"
		} else {
			Environment.DIRECTORY_DOWNLOADS + "/FixIt"
		}

		val uniqueName = buildUniqueDisplayName(
			resolver = resolver,
			collectionUri = collectionUri,
			requestedName = requestedName,
			relativePath = relativePath,
		)

		val values = ContentValues().apply {
			put(MediaStore.MediaColumns.DISPLAY_NAME, uniqueName)
			put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
				put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
				put(MediaStore.MediaColumns.IS_PENDING, 1)
			}
		}

		val insertedUri = resolver.insert(collectionUri, values)
			?: throw IOException("Unable to create destination file.")

		try {
			resolver.openOutputStream(insertedUri)?.use { output ->
				FileInputStream(sourceFile).use { input ->
					input.copyTo(output)
				}
			} ?: throw IOException("Unable to open destination stream.")

			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
				ContentValues().apply {
					put(MediaStore.MediaColumns.IS_PENDING, 0)
				}.also { pendingClear ->
					resolver.update(insertedUri, pendingClear, null, null)
				}
			}

			return insertedUri
		} catch (error: Exception) {
			resolver.delete(insertedUri, null, null)
			throw error
		}
	}

	private fun buildUniqueDisplayName(
		resolver: android.content.ContentResolver,
		collectionUri: Uri,
		requestedName: String,
		relativePath: String,
	): String {
		val dotIndex = requestedName.lastIndexOf('.')
		val hasExtension = dotIndex > 0 && dotIndex < requestedName.length - 1
		val baseName = if (hasExtension) requestedName.substring(0, dotIndex) else requestedName
		val extension = if (hasExtension) requestedName.substring(dotIndex) else ""

		var candidate = requestedName
		var index = 1
		while (nameExists(resolver, collectionUri, candidate, relativePath)) {
			candidate = "$baseName ($index)$extension"
			index++
		}
		return candidate
	}

	private fun nameExists(
		resolver: android.content.ContentResolver,
		collectionUri: Uri,
		displayName: String,
		relativePath: String,
	): Boolean {
		val projection = arrayOf(MediaStore.MediaColumns._ID)
		val selection = "${MediaStore.MediaColumns.DISPLAY_NAME} = ? AND ${MediaStore.MediaColumns.RELATIVE_PATH} = ?"
		val args = arrayOf(displayName, "$relativePath/")

		resolver.query(collectionUri, projection, selection, args, null).use { cursor ->
			return cursor != null && cursor.moveToFirst()
		}
	}
}
