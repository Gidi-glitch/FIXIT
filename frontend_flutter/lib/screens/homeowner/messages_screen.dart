import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import 'chat_screen.dart';

/// Messages Screen for the Fix It Marketplace Homeowner App.
/// Displays a chat list UI similar to Messenger with conversations.
class MessagesScreen extends StatefulWidget {
  final String? initialTradespersonName;
  final String? initialTrade;
  final String? initialAvatar;
  final bool autoOpenChat;
  final int chatRequestId;

  const MessagesScreen({
    super.key,
    this.initialTradespersonName,
    this.initialTrade,
    this.initialAvatar,
    this.autoOpenChat = false,
    this.chatRequestId = 0,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  // ── Color Palette ──────────────────────────────────────────────
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _accentOrange = Color(0xFFF97316);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _successGreen = Color(0xFF10B981);

  late List<Map<String, dynamic>> _conversations;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _hasAutoOpenedChat = false;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _conversations = [];
    _loadConversations();

    if (widget.autoOpenChat) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _hasAutoOpenedChat) return;
        _openChatForInitialTradesperson();
      });
    }
  }

  @override
  void didUpdateWidget(covariant MessagesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final hasNewChatRequest = widget.chatRequestId != oldWidget.chatRequestId;
    if (!hasNewChatRequest || !widget.autoOpenChat) return;

    _hasAutoOpenedChat = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasAutoOpenedChat) return;
      _openChatForInitialTradesperson();
    });
  }

  Map<String, dynamic>? _findConversationByTradesperson(String name) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    for (final conversation in _conversations) {
      final conversationName = (conversation['name'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      if (conversationName == normalized) return conversation;
    }
    return null;
  }

  Map<String, dynamic> _buildBookingConversation() {
    final name = (widget.initialTradespersonName ?? '').trim();
    final avatar = (widget.initialAvatar ?? '').trim();

    return {
      'id': 'booking-${DateTime.now().millisecondsSinceEpoch}',
      'name': name,
      'avatar': avatar.isNotEmpty ? avatar : 'TP',
      'lastMessage': 'Start your conversation with $name',
      'time': 'Just now',
      'unreadCount': 0,
      'isOnline': true,
      'trade': (widget.initialTrade ?? '').trim().isNotEmpty
          ? widget.initialTrade!.trim()
          : 'Tradesperson',
      'service': (widget.initialTrade ?? '').trim().isNotEmpty
          ? widget.initialTrade!.trim()
          : 'Tradesperson',
    };
  }

  Future<void> _loadConversations() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.trim().isEmpty) {
        throw Exception('Authentication required. Please log in again.');
      }

      final response = await ApiService.getConversations(token: token);
      final rawList = (response['conversations'] as List?) ?? const [];
      final loaded = rawList
          .whereType<Map>()
          .map(
            (row) => _normalizeConversation(
              row.cast<String, dynamic>(),
              fallbackTrade: 'Tradesperson',
            ),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _conversations = loaded;
        _isLoading = false;
      });

      if (widget.autoOpenChat && !_hasAutoOpenedChat) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _hasAutoOpenedChat) return;
          _openChatForInitialTradesperson();
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Map<String, dynamic> _normalizeConversation(
    Map<String, dynamic> row, {
    required String fallbackTrade,
  }) {
    final name = (row['name'] ?? '').toString().trim();
    final trade = (row['trade'] ?? row['service'] ?? '').toString().trim();

    return {
      'id': (row['id'] ?? '').toString(),
      'name': name.isNotEmpty ? name : 'Conversation',
      'avatar': (row['avatar'] ?? '').toString().trim().isNotEmpty
          ? (row['avatar'] ?? '').toString().trim()
          : _fallbackAvatar(name),
      'lastMessage':
          (row['lastMessage'] ?? row['last_message'] ?? '')
              .toString()
              .trim()
              .isNotEmpty
          ? (row['lastMessage'] ?? row['last_message']).toString().trim()
          : 'Start your conversation',
      'time': (row['time'] ?? '').toString().trim(),
      'unreadCount': _asInt(row['unreadCount'] ?? row['unread_count']),
      'isOnline': _asBool(row['isOnline'] ?? row['is_online']),
      'trade': trade.isNotEmpty ? trade : fallbackTrade,
      'service': trade.isNotEmpty ? trade : fallbackTrade,
    };
  }

  String _fallbackAvatar(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'TP';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    final raw = (value ?? '').toString().trim().toLowerCase();
    return raw == '1' || raw == 'true' || raw == 'yes';
  }

  Future<void> _openChatForInitialTradesperson() async {
    final name = (widget.initialTradespersonName ?? '').trim();
    if (name.isEmpty) return;

    final targetConversation =
        _findConversationByTradesperson(name) ?? _buildBookingConversation();

    if (!_conversations.any(
      (item) =>
          (item['id'] ?? '').toString() ==
          (targetConversation['id'] ?? '').toString(),
    )) {
      setState(() {
        _conversations.insert(0, targetConversation);
      });
    }

    _hasAutoOpenedChat = true;
    await _openConversationChat(targetConversation);
  }

  Future<void> _openConversationChat(Map<String, dynamic> conversation) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(conversation: conversation)),
    );

    if (!mounted || result == null) return;

    final deletedId = (result['deletedConversationId'] ?? '').toString().trim();
    if (deletedId.isNotEmpty) {
      setState(() {
        _conversations.removeWhere(
          (item) => (item['id'] ?? '').toString() == deletedId,
        );
      });
      return;
    }

    final conversationUpdate = result['conversationUpdate'];
    if (conversationUpdate is! Map) return;

    _upsertConversationToTop(conversationUpdate.cast<String, dynamic>());
  }

  void _upsertConversationToTop(Map<String, dynamic> update) {
    final updatedId = (update['id'] ?? '').toString().trim();
    final updatedName = (update['name'] ?? '').toString().trim().toLowerCase();

    if (updatedId.isEmpty && updatedName.isEmpty) return;

    final existingIndex = _conversations.indexWhere((item) {
      final itemId = (item['id'] ?? '').toString().trim();
      if (updatedId.isNotEmpty && itemId == updatedId) return true;

      if (updatedName.isNotEmpty) {
        final itemName = (item['name'] ?? '').toString().trim().toLowerCase();
        return itemName == updatedName;
      }

      return false;
    });

    final base = existingIndex >= 0
        ? Map<String, dynamic>.from(_conversations[existingIndex])
        : <String, dynamic>{
            'id': updatedId,
            'name': update['name'] ?? 'Conversation',
            'avatar': update['avatar'] ?? 'TP',
            'lastMessage': '',
            'time': '',
            'unreadCount': 0,
            'isOnline': true,
            'trade': update['trade'] ?? 'Tradesperson',
          };

    final merged = <String, dynamic>{...base, ...update};
    merged['unreadCount'] = 0;

    setState(() {
      if (existingIndex >= 0) {
        _conversations.removeAt(existingIndex);
      }
      _conversations.insert(0, merged);
    });
  }

  List<Map<String, dynamic>> get _filteredConversations {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _conversations;

    return _conversations.where((conversation) {
      final name = (conversation['name'] ?? '').toString().toLowerCase();
      final trade = (conversation['trade'] ?? '').toString().toLowerCase();
      final lastMessage = (conversation['lastMessage'] ?? '')
          .toString()
          .toLowerCase();
      return name.contains(query) ||
          trade.contains(query) ||
          lastMessage.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundGray,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App Bar ─────────────────────────────────────────────
            _buildAppBar(),

            // ── Search Bar ──────────────────────────────────────────
            _buildSearchBar(),

            // ── Messages List ───────────────────────────────────────
            Expanded(child: _buildConversationListBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationListBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryBlue),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 40,
                color: _textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadConversations,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredConversations.isEmpty) {
      return const Center(
        child: Text(
          'No conversations yet.',
          style: TextStyle(
            fontSize: 14,
            color: _textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
      itemCount: _filteredConversations.length,
      itemBuilder: (context, index) {
        return _buildMessageTile(context, _filteredConversations[index]);
      },
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Messages',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _textDark,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _cardWhite,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.edit_note_rounded,
                color: _textDark,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(
          fontSize: 15,
          color: _textDark,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle: TextStyle(
            fontSize: 15,
            color: _textMuted.withValues(alpha: 0.6),
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _textMuted.withValues(alpha: 0.6),
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: _textMuted.withValues(alpha: 0.7),
                    size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageTile(
    BuildContext context,
    Map<String, dynamic> conversation,
  ) {
    final hasUnread = _asInt(conversation['unreadCount']) > 0;
    final isOnline = _asBool(conversation['isOnline']);

    return Material(
      color: hasUnread
          ? _primaryBlue.withValues(alpha: 0.03)
          : Colors.transparent,
      child: InkWell(
        onTap: () => _openConversationChat(conversation),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              // ── Avatar with Online Indicator ──────────────────────
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: conversation['trade'] == 'Support'
                            ? [_accentOrange, const Color(0xFFFB923C)]
                            : [_primaryBlue, const Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        (conversation['avatar'] ?? 'TP').toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
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
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _successGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: _cardWhite, width: 2.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // ── Message Content ───────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (conversation['name'] ?? 'Conversation').toString(),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: hasUnread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: _textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          (conversation['time'] ?? '').toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: hasUnread ? _primaryBlue : _textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (conversation['lastMessage'] ?? '').toString(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: hasUnread
                                  ? _textDark.withValues(alpha: 0.8)
                                  : _textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _accentOrange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${conversation['unreadCount']}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
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
}
