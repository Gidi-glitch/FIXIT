import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AttachmentSaver {
  static const MethodChannel _channel = MethodChannel('fixit/attachment_saver');

  Future<String> saveImageToGallery(String path, String fileName) async {
    return _save(
      sourcePath: path,
      fileName: fileName,
      isImage: true,
      successFolderName: 'Pictures/FixIt',
    );
  }

  Future<String> saveFileToDownloads(String path, String fileName) async {
    return _save(
      sourcePath: path,
      fileName: fileName,
      isImage: false,
      successFolderName: 'Downloads/FixIt',
    );
  }

  Future<String> _save({
    required String sourcePath,
    required String fileName,
    required bool isImage,
    required String successFolderName,
  }) async {
    final normalizedSourcePath = sourcePath.trim();
    if (normalizedSourcePath.isEmpty) {
      throw const AttachmentSaveException('Invalid source file path.');
    }

    final sourceFile = File(normalizedSourcePath);
    if (!await sourceFile.exists()) {
      throw const AttachmentSaveException('Attachment file is missing.');
    }

    final normalizedFileName = _normalizeFileName(
      fileName,
      normalizedSourcePath,
    );
    final mimeType =
        lookupMimeType(
          normalizedSourcePath,
          headerBytes: isImage ? null : await _safeHeaderBytes(sourceFile),
        ) ??
        (isImage ? 'image/jpeg' : 'application/octet-stream');

    if (Platform.isAndroid) {
      try {
        final result = await _channel.invokeMethod<String>('saveAttachment', {
          'sourcePath': normalizedSourcePath,
          'fileName': normalizedFileName,
          'mimeType': mimeType,
          'isImage': isImage,
        });

        if (result == null || result.trim().isEmpty) {
          throw const AttachmentSaveException('Unable to save attachment.');
        }
        return result;
      } on PlatformException catch (error) {
        final message = (error.message ?? '').trim();
        throw AttachmentSaveException(
          message.isNotEmpty ? message : 'Unable to save attachment.',
        );
      }
    }

    final targetRoot = await _resolveFallbackRoot(isImage: isImage);
    final folder = Directory(p.join(targetRoot.path, 'FixIt'));
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final savePath = await _uniquePath(folder.path, normalizedFileName);
    await sourceFile.copy(savePath);
    return '$successFolderName/${p.basename(savePath)}';
  }

  Future<List<int>> _safeHeaderBytes(File file) async {
    try {
      final stream = file.openRead(0, 12);
      return await stream.expand((chunk) => chunk).take(12).toList();
    } catch (_) {
      return <int>[];
    }
  }

  String _normalizeFileName(String fileName, String sourcePath) {
    final trimmed = fileName.trim();
    if (trimmed.isNotEmpty) return trimmed;
    final fallback = p.basename(sourcePath).trim();
    return fallback.isNotEmpty ? fallback : 'attachment';
  }

  Future<Directory> _resolveFallbackRoot({required bool isImage}) async {
    if (isImage) {
      final pictures = await getApplicationDocumentsDirectory();
      return pictures;
    }
    final downloads = await getDownloadsDirectory();
    if (downloads != null) return downloads;
    return getApplicationDocumentsDirectory();
  }

  Future<String> _uniquePath(String folderPath, String fileName) async {
    final extension = p.extension(fileName);
    final base = extension.isEmpty
        ? fileName
        : fileName.substring(0, fileName.length - extension.length);

    var candidate = p.join(folderPath, fileName);
    var counter = 1;
    while (await File(candidate).exists()) {
      candidate = p.join(folderPath, '$base ($counter)$extension');
      counter++;
    }
    return candidate;
  }
}

class AttachmentSaveException implements Exception {
  final String message;

  const AttachmentSaveException(this.message);

  @override
  String toString() => message;
}
