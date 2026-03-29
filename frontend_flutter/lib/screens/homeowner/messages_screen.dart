import 'package:flutter/material.dart';
import 'chat_screen.dart';

/// Messages Screen for the Fix It Marketplace Homeowner App.
/// Displays a chat list UI similar to Messenger with conversations.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _conversations = _sampleConversations();
  }

  // ── Sample Messages Data ───────────────────────────────────────
  List<Map<String, dynamic>> _sampleConversations() => [
    {
      'id': '1',
      'name': 'Juan Dela Cruz',
      'avatar': 'JD',
      'lastMessage': 'I\'m on my way now. Will be there in 15 minutes.',
      'time': '2 min ago',
      'unreadCount': 2,
      'isOnline': true,
      'trade': 'Plumber',
    },
    {
      'id': '2',
      'name': 'Maria Santos',
      'avatar': 'MS',
      'lastMessage': 'Sure, I can check the wiring tomorrow morning.',
      'time': '1 hour ago',
      'unreadCount': 0,
      'isOnline': true,
      'trade': 'Electrician',
    },
    {
      'id': '3',
      'name': 'Pedro Reyes',
      'avatar': 'PR',
      'lastMessage':
          'The AC unit needs a new compressor. I\'ll send you a quote.',
      'time': '3 hours ago',
      'unreadCount': 1,
      'isOnline': false,
      'trade': 'HVAC Technician',
    },
    {
      'id': '4',
      'name': 'Jose Garcia',
      'avatar': 'JG',
      'lastMessage': 'Thank you for the review! Happy to help anytime.',
      'time': 'Yesterday',
      'unreadCount': 0,
      'isOnline': false,
      'trade': 'Plumber',
    },
    {
      'id': '5',
      'name': 'Antonio Cruz',
      'avatar': 'AC',
      'lastMessage':
          'The cabinet is all fixed now. Let me know if you need anything else.',
      'time': 'Mar 18',
      'unreadCount': 0,
      'isOnline': false,
      'trade': 'Carpenter',
    },
    {
      'id': '6',
      'name': 'Fix It Support',
      'avatar': 'FI',
      'lastMessage':
          'Welcome to Fix It Marketplace! How can we help you today?',
      'time': 'Mar 15',
      'unreadCount': 0,
      'isOnline': true,
      'trade': 'Support',
    },
  ];

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
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
                itemCount: _conversations.length,
                itemBuilder: (context, index) {
                  return _buildMessageTile(context, _conversations[index]);
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
        onTap: () async {
          final result = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(conversation: conversation),
            ),
          );

          if (!mounted || result == null) return;

          final deletedId = (result['deletedConversationId'] ?? '')
              .toString()
              .trim();
          if (deletedId.isEmpty) return;

          setState(() {
            _conversations.removeWhere(
              (item) => (item['id'] ?? '').toString() == deletedId,
            );
          });
        },
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

              // ── Message Content ───────────────────────────────────
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
