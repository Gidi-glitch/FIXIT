import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatStore {
  ChatStore._();

  static String _messagesKey(String conversationId) =>
      'chat_messages_$conversationId';

  static Future<List<Map<String, dynamic>>> loadMessages(
    String conversationId, {
    List<Map<String, dynamic>> seedMessages = const [],
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _messagesKey(conversationId);
    final raw = prefs.getString(key);

    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((item) => item.cast<String, dynamic>())
              .toList();
        }
      } catch (_) {
        // Fall through and re-seed if persisted data is invalid.
      }
    }

    if (seedMessages.isNotEmpty) {
      await saveMessages(conversationId, seedMessages);
      return seedMessages
          .map((m) => Map<String, dynamic>.from(m))
          .toList(growable: true);
    }

    return <Map<String, dynamic>>[];
  }

  static Future<void> saveMessages(
    String conversationId,
    List<Map<String, dynamic>> messages,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _messagesKey(conversationId);
    await prefs.setString(key, jsonEncode(messages));
  }

  static Future<String> persistAttachment({
    required String conversationId,
    required String sourcePath,
    required String fileName,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) return sourcePath;

    final docsDir = await getApplicationDocumentsDirectory();
    final safeConversationId = conversationId.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
    final attachmentsDir = Directory(
      path.join(docsDir.path, 'chat_attachments', safeConversationId),
    );

    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    final extension = path.extension(fileName);
    final base = path
        .basenameWithoutExtension(fileName)
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final targetName =
        '${base.isEmpty ? 'attachment' : base}_$timestamp$extension';
    final targetPath = path.join(attachmentsDir.path, targetName);

    await source.copy(targetPath);
    return targetPath;
  }

  static Future<void> clearConversation(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_messagesKey(conversationId));

    final docsDir = await getApplicationDocumentsDirectory();
    final safeConversationId = conversationId.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
    final attachmentsDir = Directory(
      path.join(docsDir.path, 'chat_attachments', safeConversationId),
    );

    if (await attachmentsDir.exists()) {
      await attachmentsDir.delete(recursive: true);
    }
  }
}
