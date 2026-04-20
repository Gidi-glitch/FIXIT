import 'dart:io';

import 'package:flutter/services.dart';

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

    final normalizedFileName = _normalizeFileName(fileName, normalizedSourcePath);

    if (Platform.isAndroid) {
      try {
        final result = await _channel.invokeMethod<String>('saveAttachment', {
          'sourcePath': normalizedSourcePath,
          'fileName': normalizedFileName,
          'mimeType': _guessMimeType(normalizedFileName, isImage),
          'isImage': isImage,
        });
        if (result != null && result.trim().isNotEmpty) {
          return result;
        }
      } on PlatformException catch (error) {
        final message = (error.message ?? '').trim();
        if (message.isNotEmpty) {
          throw AttachmentSaveException(message);
        }
      }
    }

    final root = _resolveFallbackRoot(isImage: isImage);
    if (!await root.exists()) {
      await root.create(recursive: true);
    }

    final folder = Directory('${root.path}${Platform.pathSeparator}FixIt');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final savePath = await _uniquePath(folder.path, normalizedFileName);
    await sourceFile.copy(savePath);
    return '$successFolderName/${_basename(savePath)}';
  }

  String _normalizeFileName(String fileName, String sourcePath) {
    final trimmed = fileName.trim();
    if (trimmed.isNotEmpty) return trimmed;
    final fallback = _basename(sourcePath).trim();
    return fallback.isNotEmpty ? fallback : 'attachment';
  }

  Directory _resolveFallbackRoot({required bool isImage}) {
    if (Platform.isAndroid) {
      final path = isImage
          ? '/storage/emulated/0/Pictures'
          : '/storage/emulated/0/Download';
      return Directory(path);
    }

    final home = Platform.environment['HOME']?.trim() ?? '';
    if (home.isNotEmpty) {
      return Directory(
        '$home${Platform.pathSeparator}${isImage ? 'Pictures' : 'Downloads'}',
      );
    }

    return Directory.systemTemp;
  }

  String _guessMimeType(String fileName, bool isImage) {
    final ext = _extension(fileName).toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      default:
        return isImage ? 'image/jpeg' : 'application/octet-stream';
    }
  }

  String _extension(String fileName) {
    final name = fileName.trim();
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1);
  }

  String _basename(String path) {
    final normalized = path.trim();
    if (normalized.isEmpty) return '';
    final segments = normalized.split(RegExp(r'[\\/]'));
    return segments.isNotEmpty ? segments.last : normalized;
  }

  Future<String> _uniquePath(String folderPath, String fileName) async {
    final ext = _extension(fileName);
    final base = ext.isEmpty
        ? fileName
        : fileName.substring(0, fileName.length - ext.length - 1);

    var candidate = '$folderPath${Platform.pathSeparator}$fileName';
    var counter = 1;
    while (await File(candidate).exists()) {
      final suffix = ext.isEmpty ? '' : '.$ext';
      candidate = '$folderPath${Platform.pathSeparator}$base ($counter)$suffix';
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
