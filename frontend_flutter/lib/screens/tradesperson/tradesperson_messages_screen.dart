import 'package:flutter/material.dart';

import 'tradesperson_chat_screen.dart';

/// Messages Screen for the Fix It Marketplace Tradesperson App.
/// Displays a chat list UI similar to Messenger with conversations.
class TradespersonMessagesScreen extends StatefulWidget {
  final String? initialHomeownerName;
  final String? initialService;
  final String? initialAvatar;
  final bool autoOpenChat;
  final int chatRequestId;

  const TradespersonMessagesScreen({
    super.key,
    this.initialHomeownerName,
    this.initialService,
    this.initialAvatar,
    this.autoOpenChat = false,
    this.chatRequestId = 0,
  });

  @override
  State<TradespersonMessagesScreen> createState() =>
      _TradespersonMessagesScreenState();
}

class _TradespersonMessagesScreenState
    extends State<TradespersonMessagesScreen> {
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

  @override
  void initState() {
    super.initState();
    _conversations = _sampleConversations();

    if (widget.autoOpenChat) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _hasAutoOpenedChat) return;
        _openChatForInitialHomeowner();
      });
    }
  }

  @override
  void didUpdateWidget(covariant TradespersonMessagesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final hasNewChatRequest = widget.chatRequestId != oldWidget.chatRequestId;
    if (!hasNewChatRequest || !widget.autoOpenChat) return;

    _hasAutoOpenedChat = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasAutoOpenedChat) return;
      _openChatForInitialHomeowner();
    });
  }

  Map<String, dynamic>? _findConversationByHomeowner(String name) {
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
    final name = (widget.initialHomeownerName ?? '').trim();
    final avatar = (widget.initialAvatar ?? '').trim();

    return {
      'id': 'booking-${DateTime.now().millisecondsSinceEpoch}',
      'name': name,
      'avatar': avatar.isNotEmpty ? avatar : 'HO',
      'lastMessage': 'Start your conversation with $name',
      'time': 'Just now',
      'unreadCount': 0,
      'isOnline': true,
      'service': (widget.initialService ?? '').trim().isNotEmpty
          ? widget.initialService!.trim()
          : 'Homeowner Request',
    };
  }

  Future<void> _openChatForInitialHomeowner() async {
    final name = (widget.initialHomeownerName ?? '').trim();
    if (name.isEmpty) return;

    final targetConversation =
        _findConversationByHomeowner(name) ?? _buildBookingConversation();

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
      MaterialPageRoute(
        builder: (_) => TradespersonChatScreen(conversation: conversation),
      ),
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
            'avatar': update['avatar'] ?? 'HO',
            'lastMessage': '',
            'time': '',
            'unreadCount': 0,
            'isOnline': true,
            'service': update['service'] ?? 'Homeowner Request',
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

  List<Map<String, dynamic>> _sampleConversations() => [
    {
      'id': 'tp-1',
      'name': 'Ana Santos',
      'avatar': 'AS',
      'lastMessage': 'Thanks! Please come by 10:30 AM.',
      'time': '2 min ago',
      'unreadCount': 2,
      'isOnline': true,
      'service': 'Water Heater Repair',
    },
    {
      'id': 'tp-2',
      'name': 'Mark Reyes',
      'avatar': 'MR',
      'lastMessage': 'Can you also check the kitchen faucet?',
      'time': '1 hour ago',
      'unreadCount': 0,
      'isOnline': true,
      'service': 'Pipe Leak Repair',
    },
    {
      'id': 'tp-3',
      'name': 'Liza Garcia',
      'avatar': 'LG',
      'lastMessage': 'I uploaded photos of the issue.',
      'time': '3 hours ago',
      'unreadCount': 1,
      'isOnline': false,
      'service': 'Bathroom Plumbing',
    },
    {
      'id': 'tp-4',
      'name': 'Fix It Support',
      'avatar': 'FI',
      'lastMessage': 'Reminder: keep all communication in-app.',
      'time': 'Yesterday',
      'unreadCount': 0,
      'isOnline': true,
      'service': 'Support',
    },
  ];

  List<Map<String, dynamic>> get _filteredConversations {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _conversations;

    return _conversations.where((conversation) {
      final name = (conversation['name'] ?? '').toString().toLowerCase();
      final service = (conversation['service'] ?? '').toString().toLowerCase();
      final lastMessage = (conversation['lastMessage'] ?? '')
          .toString()
          .toLowerCase();
      return name.contains(query) ||
          service.contains(query) ||
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
            _buildAppBar(),
            _buildSearchBar(),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
                itemCount: _filteredConversations.length,
                itemBuilder: (context, index) {
                  return _buildMessageTile(
                    context,
                    _filteredConversations[index],
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
    final hasUnread = (conversation['unreadCount'] as int) > 0;
    final isOnline = conversation['isOnline'] as bool;

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
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: conversation['service'] == 'Support'
                            ? [_accentOrange, const Color(0xFFFB923C)]
                            : [_primaryBlue, const Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        conversation['avatar'] as String,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation['name'] as String,
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
                          conversation['time'] as String,
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
                            conversation['lastMessage'] as String,
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
