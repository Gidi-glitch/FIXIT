import 'dart:io';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/attachment_saver.dart';
import '../../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // ── Color Palette ──────────────────────────────────────────────
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _accentOrange = Color(0xFFF97316);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _successGreen = Color(0xFF10B981);

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final AttachmentSaver _attachmentSaver = AttachmentSaver();
  bool _hasText = false;
  Map<String, dynamic>? _pendingAttachment;
  final Map<String, double> _imageAspectRatios = {};
  bool _hasConversationChanges = false;
  bool _isSending = false;
  String _authToken = '';
  int? _conversationIdInt;
  final Map<String, String> _downloadedAttachmentPaths = {};

  late List<Map<String, dynamic>> _messages;

  String get _conversationId {
    if (_conversationIdInt != null) {
      return _conversationIdInt.toString();
    }
    final id = (widget.conversation['id'] ?? '').toString().trim();
    if (id.isNotEmpty) return id;
    return (widget.conversation['name'] ?? 'chat').toString().trim();
  }

  String _lastMessagePreview(Map<String, dynamic> message) {
    final isAttachment = (message['isAttachment'] as bool?) ?? false;
    if (!isAttachment) {
      return (message['text'] ?? '').toString();
    }

    final type = (message['attachmentType'] ?? '').toString().toLowerCase();
    final attachmentName = (message['attachmentName'] ?? 'attachment')
        .toString()
        .trim();

    if (type == 'image') return 'Sent a photo';
    if (attachmentName.toLowerCase().endsWith('.pdf')) return 'Sent a PDF';
    return 'Sent an attachment';
  }

  Map<String, dynamic> _buildConversationUpdatePayload() {
    final latest = _messages.isNotEmpty ? _messages.last : null;

    return {
      'id': _conversationId,
      'name': (widget.conversation['name'] ?? '').toString(),
      'avatar': (widget.conversation['avatar'] ?? '').toString(),
      'trade': (widget.conversation['trade'] ?? '').toString(),
      'isOnline': widget.conversation['isOnline'] ?? false,
      'lastMessage': latest != null
          ? _lastMessagePreview(latest)
          : (widget.conversation['lastMessage'] ?? '').toString(),
      'time': latest != null
          ? (latest['time'] ?? '').toString()
          : (widget.conversation['time'] ?? '').toString(),
      'unreadCount': 0,
    };
  }

  void _closeChatWithResult() {
    if (_hasConversationChanges) {
      Navigator.of(
        context,
      ).pop({'conversationUpdate': _buildConversationUpdatePayload()});
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    _messages = <Map<String, dynamic>>[];
    _initializeChat();
    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  Future<void> _initializeChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = (prefs.getString('token') ?? '').trim();

      if (_authToken.isEmpty) {
        throw Exception('Authentication required. Please log in again.');
      }

      _conversationIdInt = int.tryParse(
        (widget.conversation['id'] ?? '').toString().trim(),
      );

      _conversationIdInt ??= await _findConversationIdByName(_authToken);
      await _loadMessages();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _accentOrange,
        ),
      );
    }
  }

  Future<int?> _findConversationIdByName(String token) async {
    final targetName = (widget.conversation['name'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (targetName.isEmpty) return null;

    final response = await ApiService.getConversations(token: token);
    final rows = (response['conversations'] as List?) ?? const [];
    for (final row in rows.whereType<Map>()) {
      final entry = row.cast<String, dynamic>();
      final name = (entry['name'] ?? '').toString().trim().toLowerCase();
      if (name != targetName) continue;
      final id = int.tryParse((entry['id'] ?? '').toString());
      if (id != null) return id;
    }
    return null;
  }

  Future<void> _loadMessages() async {
    if (_authToken.isEmpty || _conversationIdInt == null) {
      if (!mounted) return;
      setState(() => _messages = <Map<String, dynamic>>[]);
      return;
    }

    final response = await ApiService.getConversationMessages(
      token: _authToken,
      conversationId: _conversationIdInt!,
    );
    final rawMessages = (response['messages'] as List?) ?? const [];
    final loaded = rawMessages
        .whereType<Map>()
        .map((entry) => _normalizeMessage(entry.cast<String, dynamic>()))
        .toList();

    if (!mounted) return;
    setState(() {
      _messages = loaded;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Map<String, dynamic> _normalizeMessage(Map<String, dynamic> row) {
    final sender = (row['sender'] ?? 'other').toString().trim().toLowerCase();
    final text = (row['text'] ?? '').toString();
    final sentAtIso = (row['sentAtIso'] ?? row['sent_at_iso'] ?? '')
        .toString()
        .trim();
    final isAttachment = _asBool(row['isAttachment'] ?? row['is_attachment']);
    final attachmentType =
        (row['attachmentType'] ?? row['attachment_type'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

    return {
      'id': (row['id'] ?? '').toString(),
      'sender': sender == 'me' ? 'me' : 'other',
      'text': text,
      'time': _messageTimeLabel(row, sentAtIso),
      'sentAtIso': sentAtIso,
      'isAttachment': isAttachment,
      'attachmentType': attachmentType.isNotEmpty
          ? attachmentType
          : (isAttachment ? 'file' : ''),
      'attachmentName':
          (row['attachmentName'] ?? row['attachment_name'] ?? text).toString(),
      'attachmentPath': (row['attachmentPath'] ?? row['attachment_path'] ?? '')
          .toString(),
    };
  }

  String _messageTimeLabel(Map<String, dynamic> row, String sentAtIso) {
    final existing = (row['time'] ?? '').toString().trim();
    if (existing.isNotEmpty) return existing;

    final parsed = DateTime.tryParse(sentAtIso);
    if (parsed == null) return '';

    final local = parsed.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    final raw = (value ?? '').toString().trim().toLowerCase();
    return raw == '1' || raw == 'true' || raw == 'yes';
  }

  bool _isRemotePath(String path) {
    final normalized = path.trim().toLowerCase();
    return normalized.startsWith('http://') ||
        normalized.startsWith('https://');
  }

  Future<String?> _resolveAttachmentSourcePath(
    String sourcePath,
    String fileName,
  ) async {
    final normalized = sourcePath.trim();
    if (normalized.isEmpty) return null;

    if (!_isRemotePath(normalized)) {
      return File(normalized).existsSync() ? normalized : null;
    }

    final cachedPath = _downloadedAttachmentPaths[normalized];
    if (cachedPath != null && File(cachedPath).existsSync()) {
      return cachedPath;
    }

    final response = await http.get(Uri.parse(normalized));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final tempDir = await getTemporaryDirectory();
    final safeName = _extractFileName(
      fileName,
      fallback: 'attachment',
    ).replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final localPath =
        '${tempDir.path}/fixit_${DateTime.now().millisecondsSinceEpoch}_$safeName';

    final file = File(localPath);
    await file.writeAsBytes(response.bodyBytes, flush: true);
    _downloadedAttachmentPaths[normalized] = localPath;
    return localPath;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _showConversationStartDivider {
    if (_messages.isEmpty) return false;
    final firstMessageIso = (_messages.first['sentAtIso'] ?? '')
        .toString()
        .trim();
    return firstMessageIso.isNotEmpty;
  }

  String _formatConversationStartLabel(String isoText) {
    final parsed = DateTime.tryParse(isoText);
    if (parsed == null) return '';
    final local = parsed.toLocal();

    const months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final month = months[local.month - 1];
    final day = local.day;
    final year = local.year;
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$month $day, $year at $hour:$minute $period';
  }

  Widget _buildConversationStartDivider() {
    if (!_showConversationStartDivider) return const SizedBox.shrink();

    final label = _formatConversationStartLabel(
      (_messages.first['sentAtIso'] ?? '').toString(),
    );
    if (label.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _textMuted.withValues(alpha: 0.18)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _textMuted.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyConversationPrompt() {
    return Center(
      key: const ValueKey('empty-conversation-state'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                color: _primaryBlue.withValues(alpha: 0.85),
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ask about your project details',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Discuss pricing and schedule',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: _textMuted.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom({bool animated = false}) {
    if (!_scrollController.hasClients) return;
    if (animated) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;

    final text = _messageController.text.trim();
    if (text.isEmpty && _pendingAttachment == null) return;

    if (_authToken.isEmpty || _conversationIdInt == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Conversation is not ready yet. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _accentOrange,
        ),
      );
      return;
    }

    final pending = _pendingAttachment;
    final appended = <Map<String, dynamic>>[];
    _isSending = true;

    try {
      if (pending != null) {
        final originalPath = (pending['attachmentPath'] ?? '')
            .toString()
            .trim();
        final originalName = (pending['attachmentName'] ?? 'attachment')
            .toString()
            .trim();

        if (originalPath.isNotEmpty) {
          final attachmentResponse =
              await ApiService.sendConversationAttachment(
                token: _authToken,
                conversationId: _conversationIdInt!,
                filePath: originalPath,
                filename: originalName,
              );

          final rawAttachment = (attachmentResponse['chat_message'] as Map?)
              ?.cast<String, dynamic>();
          if (rawAttachment != null) {
            appended.add(_normalizeMessage(rawAttachment));
          }
        }
      }

      if (text.isNotEmpty) {
        final messageResponse = await ApiService.sendConversationMessage(
          token: _authToken,
          conversationId: _conversationIdInt!,
          text: text,
        );

        final rawMessage = (messageResponse['chat_message'] as Map?)
            ?.cast<String, dynamic>();
        if (rawMessage != null) {
          appended.add(_normalizeMessage(rawMessage));
        }
      }

      if (!mounted) return;

      setState(() {
        if (appended.isNotEmpty) {
          _messages.addAll(appended);
          _hasConversationChanges = true;
        }
        if (pending != null) {
          _pendingAttachment = null;
        }
        _messageController.clear();
      });

      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToBottom(animated: true),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not send message right now.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _accentOrange,
        ),
      );
    } finally {
      _isSending = false;
      if (mounted && pending == null && text.isNotEmpty && appended.isEmpty) {
        _messageController.clear();
      }
    }
  }

  Future<void> _promptDeleteConversation() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            decoration: BoxDecoration(
              color: _cardWhite,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Delete conversation?',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to delete this conversation?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: _textMuted.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textDark,
                          side: BorderSide(
                            color: _textMuted.withValues(alpha: 0.25),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    if (_authToken.isNotEmpty && _conversationIdInt != null) {
      try {
        await ApiService.deleteConversation(
          token: _authToken,
          conversationId: _conversationIdInt!,
        );
      } catch (error) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _accentOrange,
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    navigator.pop({'deletedConversationId': _conversationId});
  }

  Future<void> _openAttachmentSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            color: _cardWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _textMuted.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              _attachmentActionTile(
                icon: Icons.camera_alt_rounded,
                iconBackground: const Color(0xFFDBEAFE),
                iconColor: _primaryBlue,
                title: 'Capture Image',
                subtitle: 'Capture and review before sending',
                onTap: () async {
                  Navigator.of(context).pop();
                  await _captureImageAttachment();
                },
              ),
              const SizedBox(height: 10),
              _attachmentActionTile(
                icon: Icons.attach_file_rounded,
                iconBackground: const Color(0xFFFFEDD5),
                iconColor: _accentOrange,
                title: 'Choose File or Image',
                subtitle: 'Pick from your local device',
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pickFileOrImageAttachment();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _attachmentActionTile({
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _backgroundGray,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: _textMuted.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _captureImageAttachment() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 88,
        maxWidth: 1800,
      );

      if (picked == null) return;

      final imageName = picked.name.trim().isNotEmpty
          ? picked.name.trim()
          : _extractFileName(picked.path, fallback: 'captured_image.jpg');

      _setPendingAttachment(type: 'image', name: imageName, path: picked.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to capture image right now.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _accentOrange,
        ),
      );
    }
  }

  Future<void> _pickFileOrImageAttachment() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final picked = result.files.first;
      final filePath = picked.path ?? '';
      final fileName = picked.name.trim().isNotEmpty
          ? picked.name.trim()
          : _extractFileName(filePath, fallback: 'attachment');

      final ext = picked.extension?.toLowerCase() ?? '';
      final isImage = <String>{
        'jpg',
        'jpeg',
        'png',
        'webp',
        'gif',
        'bmp',
      }.contains(ext);

      _setPendingAttachment(
        type: isImage ? 'image' : 'file',
        name: fileName,
        path: filePath,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to open file picker right now.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _accentOrange,
        ),
      );
    }
  }

  void _setPendingAttachment({
    required String type,
    required String name,
    required String path,
  }) {
    setState(() {
      _pendingAttachment = {
        'attachmentType': type,
        'attachmentName': name,
        'attachmentPath': path,
      };
    });
  }

  Future<void> _onAttachmentTapped(Map<String, dynamic> msg) async {
    final type = (msg['attachmentType'] ?? 'image').toString();
    if (type == 'image') {
      await _showImagePreview(msg);
      return;
    }
    await _saveAttachmentAs(msg);
  }

  Future<void> _showImagePreview(Map<String, dynamic> msg) async {
    final path = (msg['attachmentPath'] ?? '').toString().trim();
    final hasLocalFile = path.isNotEmpty && File(path).existsSync();
    final hasRemoteFile = _isRemotePath(path);
    if (path.isEmpty || (!hasLocalFile && !hasRemoteFile)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Image preview is not available.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _accentOrange,
        ),
      );
      return;
    }

    final name = (msg['attachmentName'] ?? 'Image').toString();

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (_) {
        return Dialog.fullscreen(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: hasRemoteFile
                      ? Image.network(path, fit: BoxFit.contain)
                      : Image.file(File(path), fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 44,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    _floatingGlassButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _floatingGlassButton(
                      icon: Icons.download_rounded,
                      onTap: () => _saveAttachmentAs(msg),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _floatingGlassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Future<void> _saveAttachmentAs(Map<String, dynamic> msg) async {
    final sourcePath = (msg['attachmentPath'] ?? '').toString().trim();
    final fileName = (msg['attachmentName'] ?? 'attachment').toString();
    final type = (msg['attachmentType'] ?? 'file').toString();

    final localPath = await _resolveAttachmentSourcePath(sourcePath, fileName);
    if (localPath == null || !File(localPath).existsSync()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('File is not available to download.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _accentOrange,
        ),
      );
      return;
    }

    try {
      if (type == 'image') {
        await _attachmentSaver.saveImageToGallery(localPath, fileName);
      } else {
        await _attachmentSaver.saveFileToDownloads(localPath, fileName);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            type == 'image' ? 'Saved to Gallery' : 'Saved to Downloads',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _primaryBlue,
        ),
      );
    } on AttachmentSaveException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not save attachment right now.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _accentOrange,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not save attachment right now.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _accentOrange,
        ),
      );
    }
  }

  void _clearPendingAttachment() {
    if (_pendingAttachment == null) return;
    setState(() => _pendingAttachment = null);
  }

  Future<void> _cacheImageAspectRatio(String path) async {
    final normalizedPath = path.trim();
    if (normalizedPath.isEmpty ||
        _imageAspectRatios.containsKey(normalizedPath)) {
      return;
    }

    try {
      final file = File(normalizedPath);
      if (!await file.exists()) return;

      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final ratio = frame.image.width / frame.image.height;

      if (!mounted) return;
      setState(() {
        _imageAspectRatios[normalizedPath] = ratio;
      });
    } catch (_) {
      // Keep default ratio when image metadata cannot be parsed.
    }
  }

  Widget _buildPendingAttachmentPreview() {
    final pending = _pendingAttachment;
    if (pending == null) return const SizedBox.shrink();

    final type = (pending['attachmentType'] ?? 'file').toString();
    final isImage = type == 'image';
    final name = (pending['attachmentName'] ?? 'Attachment').toString();
    final path = (pending['attachmentPath'] ?? '').toString().trim();
    final hasImagePreview =
        isImage && path.isNotEmpty && File(path).existsSync();

    if (isImage) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _primaryBlue.withValues(alpha: 0.14),
                  ),
                  color: _backgroundGray,
                ),
                clipBehavior: Clip.antiAlias,
                child: hasImagePreview
                    ? Image.file(File(path), fit: BoxFit.cover)
                    : Icon(
                        Icons.image_rounded,
                        color: _primaryBlue.withValues(alpha: 0.85),
                        size: 22,
                      ),
              ),
              Positioned(
                top: -7,
                right: -7,
                child: Material(
                  color: _cardWhite,
                  shape: const CircleBorder(),
                  elevation: 1.5,
                  child: InkWell(
                    onTap: _clearPendingAttachment,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 22,
                      height: 22,
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: _textDark,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: _backgroundGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryBlue.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDBEAFE), Color(0xFFEFF6FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isImage ? Icons.image_rounded : Icons.insert_drive_file_rounded,
              color: _primaryBlue,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                Text(
                  isImage ? 'Image ready to send' : 'File ready to send',
                  style: TextStyle(
                    fontSize: 11,
                    color: _textMuted.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _clearPendingAttachment,
            icon: Icon(
              Icons.close_rounded,
              color: _textMuted.withValues(alpha: 0.8),
              size: 18,
            ),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  String _extractFileName(String path, {required String fallback}) {
    if (path.trim().isEmpty) return fallback;
    final segments = path.split(RegExp(r'[\\/]'));
    final last = segments.isNotEmpty ? segments.last.trim() : '';
    return last.isNotEmpty ? last : fallback;
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isOnline = widget.conversation['isOnline'] as bool;
    final isSupport = widget.conversation['trade'] == 'Support';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _closeChatWithResult();
        },
        child: Scaffold(
          backgroundColor: _backgroundGray,
          body: Column(
            children: [
              _buildHeader(context, isOnline, isSupport),
              Expanded(child: _buildMessageList()),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context, bool isOnline, bool isSupport) {
    final _ = isSupport ? _accentOrange : _primaryBlue;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSupport
              ? [_accentOrange, const Color(0xFFEA580C)]
              : [_primaryBlue, const Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
          child: Row(
            children: [
              // Back button
              IconButton(
                onPressed: _closeChatWithResult,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),

              // Avatar
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.conversation['avatar'] as String,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: _successGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Name & status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.conversation['name'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (isOnline)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: const BoxDecoration(
                              color: _successGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          isOnline
                              ? 'Online now'
                              : widget.conversation['trade'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Call button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.call_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),

              // More options
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: PopupMenuButton<String>(
                  tooltip: 'More options',
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  color: _cardWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 8,
                  onSelected: (value) {
                    if (value == 'delete') {
                      _promptDeleteConversation();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete conversation',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  MESSAGE LIST
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMessageList() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _messages.isEmpty
          ? _buildEmptyConversationPrompt()
          : ListView.builder(
              key: const ValueKey('conversation-message-list'),
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount:
                  _messages.length + (_showConversationStartDivider ? 1 : 0),
              itemBuilder: (context, index) {
                if (_showConversationStartDivider && index == 0) {
                  return _buildConversationStartDivider();
                }

                final messageIndex =
                    index - (_showConversationStartDivider ? 1 : 0);
                final msg = _messages[messageIndex];
                final isMe = msg['sender'] == 'me';
                final prevMsg = messageIndex > 0
                    ? _messages[messageIndex - 1]
                    : null;
                final nextMsg = messageIndex < _messages.length - 1
                    ? _messages[messageIndex + 1]
                    : null;

                // Group messages: show time only when sender changes or last in group
                final isFirstInGroup =
                    prevMsg == null || prevMsg['sender'] != msg['sender'];
                final isLastInGroup =
                    nextMsg == null || nextMsg['sender'] != msg['sender'];

                return _buildMessageBubble(
                  msg,
                  isMe: isMe,
                  isFirstInGroup: isFirstInGroup,
                  isLastInGroup: isLastInGroup,
                );
              },
            ),
    );
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> msg, {
    required bool isMe,
    required bool isFirstInGroup,
    required bool isLastInGroup,
  }) {
    final isAttachment = msg['isAttachment'] as bool? ?? false;
    final isImageAttachment =
        isAttachment && (msg['attachmentType'] ?? 'image') == 'image';

    return Padding(
      padding: EdgeInsets.only(
        top: isFirstInGroup ? 12 : 2,
        bottom: isLastInGroup ? 2 : 0,
      ),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Pro avatar (only on last bubble in a group)
          if (!isMe) ...[
            if (isLastInGroup)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primaryBlue, Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    widget.conversation['avatar'] as String,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: 32),
            const SizedBox(width: 8),
          ],

          // Bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.68,
                  ),
                  padding: isImageAttachment
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                  decoration: BoxDecoration(
                    color: isImageAttachment
                        ? Colors.transparent
                        : (isMe ? _primaryBlue : _cardWhite),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(
                        isMe
                            ? 18
                            : isLastInGroup
                            ? 4
                            : 18,
                      ),
                      bottomRight: Radius.circular(
                        isMe ? (isLastInGroup ? 4 : 18) : 18,
                      ),
                    ),
                    boxShadow: isImageAttachment
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: isAttachment
                      ? GestureDetector(
                          onTap: () => _onAttachmentTapped(msg),
                          child: _buildAttachmentBubble(msg, isMe),
                        )
                      : Text(
                          msg['text'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: isMe ? Colors.white : _textDark,
                            fontWeight: FontWeight.w400,
                            height: 1.45,
                          ),
                        ),
                ),

                // Timestamp — only on last bubble in group
                if (isLastInGroup)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                    child: Text(
                      msg['time'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: _textMuted.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildAttachmentBubble(Map<String, dynamic> msg, bool isMe) {
    final type = (msg['attachmentType'] ?? 'image').toString();
    final name = (msg['attachmentName'] ?? msg['text'] ?? 'Attachment')
        .toString();
    final isImage = type == 'image';
    final path = (msg['attachmentPath'] ?? '').toString().trim();
    final isRemoteImage = isImage && _isRemotePath(path);
    final hasImagePreview =
        isImage &&
        path.isNotEmpty &&
        (isRemoteImage || File(path).existsSync());

    if (isImage) {
      _cacheImageAspectRatio(path);
      final imageRatio = (_imageAspectRatios[path] ?? 0.82).clamp(0.68, 1.45);

      return Container(
        constraints: const BoxConstraints(maxWidth: 220, maxHeight: 280),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: hasImagePreview
              ? null
              : LinearGradient(
                  colors: [
                    _primaryBlue.withValues(alpha: 0.18),
                    _accentOrange.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: imageRatio.toDouble(),
          child: hasImagePreview
              ? (isRemoteImage
                    ? Image.network(path, fit: BoxFit.cover)
                    : Image.file(File(path), fit: BoxFit.cover))
              : Icon(
                  Icons.image_rounded,
                  size: 34,
                  color: isMe ? Colors.white : _primaryBlue,
                ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isMe
                  ? [
                      Colors.white.withValues(alpha: 0.24),
                      Colors.white.withValues(alpha: 0.15),
                    ]
                  : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: isMe
                  ? Colors.white.withValues(alpha: 0.35)
                  : _primaryBlue.withValues(alpha: 0.14),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasImagePreview
              ? (isRemoteImage
                    ? Image.network(path, fit: BoxFit.cover)
                    : Image.file(File(path), fit: BoxFit.cover))
              : Icon(
                  isImage
                      ? Icons.image_rounded
                      : Icons.insert_drive_file_rounded,
                  color: isMe ? Colors.white : _primaryBlue,
                  size: 20,
                ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isMe ? Colors.white : _textDark,
                ),
              ),
              Text(
                isImage ? 'Tap to view and save as' : 'Tap to save as',
                style: TextStyle(
                  fontSize: 11,
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.74)
                      : _textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  INPUT BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: _cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPendingAttachmentPreview(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attachment button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(13),
                      onTap: _openAttachmentSheet,
                      child: Ink(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _primaryBlue.withValues(alpha: 0.16),
                              _primaryBlue.withValues(alpha: 0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: _primaryBlue.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Icon(
                          Icons.attach_file_rounded,
                          color: _primaryBlue.withValues(alpha: 0.88),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Text field
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: _backgroundGray,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: _primaryBlue.withValues(alpha: 0.12),
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _textDark,
                          fontWeight: FontWeight.w400,
                        ),
                        decoration: InputDecoration(
                          hintText: _pendingAttachment == null
                              ? 'Type a message…'
                              : 'Add a message (optional)…',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: _textMuted.withValues(alpha: 0.55),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: (_hasText || _pendingAttachment != null)
                          ? _primaryBlue
                          : _primaryBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: (_hasText || _pendingAttachment != null)
                          ? [
                              BoxShadow(
                                color: _primaryBlue.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: GestureDetector(
                      onTap: (_hasText || _pendingAttachment != null)
                          ? _sendMessage
                          : null,
                      child: Icon(
                        Icons.send_rounded,
                        color: (_hasText || _pendingAttachment != null)
                            ? Colors.white
                            : _primaryBlue.withValues(alpha: 0.4),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
