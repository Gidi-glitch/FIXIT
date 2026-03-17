import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fixit_application/screens/login_screen.dart';

class HomeownerDashboardScreen extends StatefulWidget {
  const HomeownerDashboardScreen({super.key});

  @override
  State<HomeownerDashboardScreen> createState() =>
      _HomeownerDashboardScreenState();
}

class _HomeownerDashboardScreenState extends State<HomeownerDashboardScreen> {
  int _selectedNavIndex = 0;

  // ── Color Palette (mirrors UserLoginScreen) ──────────────────────
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _accentOrange = Color(0xFFF97316);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _inputFill = Color(0xFFFFFFFF);

  // ── Static demo data ─────────────────────────────────────────────
  String _userName = 'Maria Flores';
  String _userEmail = 'maria.flores@fixit.com';
  String _userLocation = 'San Pablo City, Laguna';
  final TextEditingController _postController = TextEditingController();
  String? _attachedPhotoLabel;
  final List<_MessageThread> _messageThreads = [
    _MessageThread(
      tradesmanName: 'Carlos Reyes',
      skill: 'Electrician',
      lastMessage: 'I can check your breaker panel this afternoon.',
      timeLabel: '5m',
      unreadCount: 1,
      messages: [
        _ChatMessage(
          sender: 'Carlos Reyes',
          text: 'Hi Maria, I saw your request.',
        ),
        _ChatMessage(
          sender: 'Carlos Reyes',
          text: 'I can check your breaker panel this afternoon.',
        ),
      ],
    ),
    _MessageThread(
      tradesmanName: 'Jose Dela Cruz',
      skill: 'Plumber',
      lastMessage: 'Please send a photo of the leaking faucet.',
      timeLabel: '22m',
      messages: [
        _ChatMessage(
          sender: 'Jose Dela Cruz',
          text: 'Good morning, I can help with your faucet issue.',
        ),
        _ChatMessage(
          sender: 'Jose Dela Cruz',
          text: 'Please send a photo of the leaking faucet.',
        ),
      ],
    ),
    _MessageThread(
      tradesmanName: 'Ramon Lim',
      skill: 'Appliance Repair',
      lastMessage: 'Your refrigerator repair is complete. Thank you.',
      timeLabel: '1h',
      messages: [
        _ChatMessage(
          sender: 'Ramon Lim',
          text: 'Your refrigerator repair is complete. Thank you.',
        ),
      ],
    ),
  ];

  late final List<_CommunityPost> _communityPosts = [
    const _CommunityPost(
      authorName: 'Angela Torres',
      category: 'Homeowner Request',
      message: 'Need a plumber for leaking kitchen sink near San Roque.',
      timeLabel: '14m ago',
    ),
    const _CommunityPost(
      authorName: 'Mario Cruz',
      category: 'Service Needed',
      message: 'Looking for aircon technician for cleaning and diagnostics.',
      timeLabel: '38m ago',
    ),
  ];

  final List<_ServiceCategory> _categories = const [
    _ServiceCategory(
      icon: Icons.electrical_services_rounded,
      label: 'Electrician',
    ),
    _ServiceCategory(icon: Icons.water_drop_rounded, label: 'Plumber'),
    _ServiceCategory(icon: Icons.kitchen_rounded, label: 'Appliance\nRepair'),
    _ServiceCategory(icon: Icons.ac_unit_rounded, label: 'Aircon\nTech'),
    _ServiceCategory(icon: Icons.chair_rounded, label: 'Furniture\nRepair'),
  ];

  final List<_Tradesman> _tradesmen = const [
    _Tradesman(
      name: 'Carlos Reyes',
      skill: 'Electrician',
      rating: 4.9,
      isAvailable: true,
      avatarColor: Color(0xFF3B82F6),
      initials: 'CR',
      achievements: ['Top Rated Electrician 2025', '200+ Repairs Completed'],
      certificates: ['TESDA NC II - Electrical Installation'],
      recentWorks: [
        'Panel rewiring for family home',
        'Smart breaker installation',
      ],
    ),
    _Tradesman(
      name: 'Jose Dela Cruz',
      skill: 'Plumber',
      rating: 4.7,
      isAvailable: true,
      avatarColor: Color(0xFF10B981),
      initials: 'JD',
      achievements: ['Fast Response Pro', '150+ Plumbing Jobs Completed'],
      certificates: ['TESDA NC II - Plumbing'],
      recentWorks: [
        'Leak repair for kitchen pipeline',
        'Bathroom repiping project',
      ],
    ),
    _Tradesman(
      name: 'Ramon Lim',
      skill: 'Appliance Repair',
      rating: 4.5,
      isAvailable: false,
      avatarColor: Color(0xFF8B5CF6),
      initials: 'RL',
      achievements: ['Trusted Appliance Technician'],
      certificates: ['Samsung Appliance Service Training'],
      recentWorks: ['Refrigerator inverter repair', 'Washer motor replacement'],
    ),
  ];

  final List<_ServiceRequest> _requests = const [
    _ServiceRequest(
      description: 'Kitchen circuit breaker keeps tripping',
      status: 'In Progress',
      tradesmanName: 'Carlos Reyes',
      scheduledDate: 'Jun 12, 2025 · 10:00 AM',
    ),
    _ServiceRequest(
      description: 'Leaking bathroom faucet and low water pressure',
      status: 'Pending',
      tradesmanName: 'Unassigned',
      scheduledDate: 'Jun 14, 2025 · 2:00 PM',
    ),
    _ServiceRequest(
      description: 'Refrigerator not cooling properly',
      status: 'Completed',
      tradesmanName: 'Ramon Lim',
      scheduledDate: 'Jun 8, 2025 · 9:00 AM',
    ),
  ];

  // ── Status helpers ───────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return const Color(0xFFF59E0B);
      case 'Assigned':
        return const Color(0xFF3B82F6);
      case 'In Progress':
        return _accentOrange;
      case 'Completed':
        return const Color(0xFF10B981);
      default:
        return _textMuted;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.schedule_rounded;
      case 'Assigned':
        return Icons.assignment_ind_rounded;
      case 'In Progress':
        return Icons.build_rounded;
      case 'Completed':
        return Icons.check_circle_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _backgroundGray,
        appBar: _buildAppBar(),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  void _handleSignOut(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const UserLoginScreen()),
      (route) => false,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  APP BAR
  // ═══════════════════════════════════════════════════════════════
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _primaryBlue,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: Row(
        children: [
          // Logo pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.build_rounded, color: _accentOrange, size: 16),
                const SizedBox(width: 6),
                const Text(
                  'FIXit',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Notification bell with badge
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: _accentOrange,
                    shape: BoxShape.circle,
                    border: Border.all(color: _primaryBlue, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BODY
  // ═══════════════════════════════════════════════════════════════
  Widget _buildBody() {
    if (_selectedNavIndex == 3) {
      return _buildProfileTab(context);
    }

    if (_selectedNavIndex == 1) {
      return _buildRequestsTab();
    }

    if (_selectedNavIndex == 2) {
      return _buildMessagesTab();
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(),
          const SizedBox(height: 24),
          _buildRequestRepairButton(),
          const SizedBox(height: 28),
          _buildSectionTitle('Post Your Request'),
          const SizedBox(height: 12),
          _buildPostComposer(),
          const SizedBox(height: 28),
          _buildSectionTitle('Community Requests'),
          const SizedBox(height: 12),
          _buildCommunityPosts(),
          const SizedBox(height: 28),
          _buildSectionTitle('Service Categories'),
          const SizedBox(height: 12),
          _buildServiceCategories(),
          const SizedBox(height: 28),
          _buildSectionTitle('Available Tradesmen'),
          const SizedBox(height: 12),
          _buildTradesmenList(),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildSectionTitle('My Requests'),
          const SizedBox(height: 12),
          _buildRequestsList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _submitPost() {
    final text = _postController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _communityPosts.insert(
        0,
        _CommunityPost(
          authorName: _userName,
          category: 'Homeowner Request',
          message: text,
          timeLabel: 'Just now',
          photoLabel: _attachedPhotoLabel,
        ),
      );
    });
    _postController.clear();
    _attachedPhotoLabel = null;
    FocusScope.of(context).unfocus();
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _inputFill,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(
                      () => _attachedPhotoLabel = 'Camera photo attached',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(
                      () => _attachedPhotoLabel = 'Gallery photo attached',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostComposer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _inputFill,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            TextField(
              controller: _postController,
              maxLines: 3,
              minLines: 2,
              decoration: InputDecoration(
                hintText: 'What do you need fixed or what service do you need?',
                hintStyle: TextStyle(color: _textMuted, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _showPhotoSourceSheet,
                  icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                  label: const Text('Add Photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryBlue,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
                if (_attachedPhotoLabel != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.image_outlined,
                            size: 14,
                            color: _primaryBlue,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _attachedPhotoLabel!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _attachedPhotoLabel = null),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: _primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _submitPost,
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Post Request'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityPosts() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _communityPosts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final post = _communityPosts[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _inputFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      post.authorName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                  ),
                  Text(
                    post.timeLabel,
                    style: TextStyle(fontSize: 11, color: _textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                post.category,
                style: TextStyle(
                  fontSize: 11,
                  color: _primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                post.message,
                style: TextStyle(fontSize: 13, color: _textDark, height: 1.35),
              ),
              if (post.photoLabel != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.image_outlined, size: 14, color: _textMuted),
                    const SizedBox(width: 6),
                    Text(
                      post.photoLabel!,
                      style: TextStyle(
                        fontSize: 11,
                        color: _textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessagesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        _buildSectionTitle('Messages'),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: _messageThreads.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final thread = _messageThreads[index];
              return InkWell(
                onTap: () => _openMessageThread(index),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _inputFill,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: _primaryBlue.withValues(alpha: 0.12),
                        child: Text(
                          _initials(thread.tradesmanName),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              thread.tradesmanName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              thread.skill,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              thread.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: _textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            thread.timeLabel,
                            style: TextStyle(fontSize: 11, color: _textMuted),
                          ),
                          if (thread.unreadCount > 0) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _accentOrange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${thread.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _openMessageThread(int index) async {
    final thread = _messageThreads[index];
    if (thread.unreadCount > 0) {
      setState(() => thread.unreadCount = 0);
    }

    final TextEditingController replyController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _inputFill,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      thread.tradesmanName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      thread.skill,
                      style: TextStyle(
                        fontSize: 12,
                        color: _textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: thread.messages.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, messageIndex) {
                          final message = thread.messages[messageIndex];
                          final bool fromMe = message.sender == _userName;
                          return Align(
                            alignment: fromMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 280),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: fromMe
                                    ? _primaryBlue
                                    : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                message.text,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: fromMe ? Colors.white : _textDark,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: replyController,
                            decoration: InputDecoration(
                              hintText: 'Type your reply...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: _textMuted,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final text = replyController.text.trim();
                            if (text.isEmpty) return;

                            setModalState(() {
                              thread.messages.add(
                                _ChatMessage(sender: _userName, text: text),
                              );
                            });
                            setState(() {
                              thread.lastMessage = text;
                              thread.timeLabel = 'Now';
                            });
                            replyController.clear();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Send'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    replyController.dispose();
  }

  void _editHomeownerProfile() {
    final nameController = TextEditingController(text: _userName);
    final emailController = TextEditingController(text: _userEmail);
    final locationController = TextEditingController(text: _userLocation);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _inputFill,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final email = emailController.text.trim();
                    final location = locationController.text.trim();
                    if (name.isEmpty || email.isEmpty || location.isEmpty) {
                      return;
                    }
                    setState(() {
                      _userName = name;
                      _userEmail = email;
                      _userLocation = location;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      emailController.dispose();
      locationController.dispose();
    });
  }

  Widget _buildProfileTab(BuildContext context) {
    final int activeRequests = _requests
        .where((request) => request.status != 'Completed')
        .length;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.person_outline_rounded,
                size: 32,
                color: _primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(_userName, style: TextStyle(fontSize: 14, color: _textMuted)),
            const SizedBox(height: 4),
            Text(
              'Homeowner Account',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _primaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _editHomeownerProfile,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryBlue,
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _inputFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  _buildProfileInfoRow(
                    icon: Icons.mail_outline_rounded,
                    label: 'Email',
                    value: _userEmail,
                  ),
                  const SizedBox(height: 10),
                  _buildProfileInfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: _userLocation,
                  ),
                  const SizedBox(height: 10),
                  _buildProfileInfoRow(
                    icon: Icons.assignment_outlined,
                    label: 'Active Requests',
                    value: '$activeRequests',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _handleSignOut(context),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB91C1C),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _textMuted),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 12,
            color: _textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              color: _textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ── Welcome Header ───────────────────────────────────────────────
  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _primaryBlue,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'What needs fixing today?',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            child: Text(
              'MS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section title ────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: _accentOrange,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textDark,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Request Repair CTA ───────────────────────────────────────────
  Widget _buildRequestRepairButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF97316), Color(0xFFEA580C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _accentOrange.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.build_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Request a Repair',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Describe your issue & get matched fast',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Service Categories ───────────────────────────────────────────
  Widget _buildServiceCategories() {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return GestureDetector(
            onTap: () {},
            child: Container(
              width: 82,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: _inputFill,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(cat.icon, color: _primaryBlue, size: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Available Tradesmen ──────────────────────────────────────────
  Widget _buildTradesmenList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _tradesmen.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final t = _tradesmen[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _inputFill,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 26,
                backgroundColor: t.avatarColor.withValues(alpha: 0.15),
                child: Text(
                  t.initials,
                  style: TextStyle(
                    color: t.avatarColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          t.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: t.isAvailable
                                ? const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.12)
                                : _textMuted.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            t.isAvailable ? 'Available' : 'Busy',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: t.isAvailable
                                  ? const Color(0xFF10B981)
                                  : _textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.skill,
                      style: TextStyle(
                        fontSize: 12,
                        color: _textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: const Color(0xFFFBBF24),
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          t.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _textDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  SizedBox(
                    height: 32,
                    child: OutlinedButton(
                      onPressed: () => _showTradesmanProfile(t),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryBlue,
                        side: BorderSide(
                          color: _primaryBlue.withValues(alpha: 0.3),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('View Profile'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: t.isAvailable ? () {} : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _textMuted.withValues(
                          alpha: 0.15,
                        ),
                        disabledForegroundColor: _textMuted,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Request'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTradesmanProfile(_Tradesman tradesman) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _inputFill,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    tradesman.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tradesman.skill,
                    style: TextStyle(
                      fontSize: 13,
                      color: _textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTradesmanProfileSection(
                    'Achievements',
                    tradesman.achievements,
                  ),
                  const SizedBox(height: 12),
                  _buildTradesmanProfileSection(
                    'Certificates',
                    tradesman.certificates,
                  ),
                  const SizedBox(height: 12),
                  _buildTradesmanProfileSection(
                    'Recent Works',
                    tradesman.recentWorks,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTradesmanProfileSection(String title, List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 13)),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(fontSize: 13, color: _textDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── My Requests ──────────────────────────────────────────────────
  Widget _buildRequestsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final req = _requests[index];
        final statusColor = _statusColor(req.status);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _inputFill,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status badge row
              Row(
                children: [
                  Icon(_statusIcon(req.status), color: statusColor, size: 15),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      req.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Description
              Text(
                req.description,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              // Divider
              Divider(color: const Color(0xFFE5E7EB), thickness: 1, height: 1),
              const SizedBox(height: 10),
              // Meta row
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 13,
                    color: _textMuted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      req.tradesmanName,
                      style: TextStyle(
                        fontSize: 12,
                        color: _textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 12,
                    color: _textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    req.scheduledDate,
                    style: TextStyle(
                      fontSize: 11,
                      color: _textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Bottom Navigation Bar ────────────────────────────────────────
  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: _inputFill,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
              _buildNavItem(
                1,
                Icons.assignment_rounded,
                Icons.assignment_outlined,
                'Requests',
              ),
              _buildNavItem(
                2,
                Icons.chat_bubble_rounded,
                Icons.chat_bubble_outline_rounded,
                'Messages',
              ),
              _buildNavItem(
                3,
                Icons.person_rounded,
                Icons.person_outline_rounded,
                'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final isSelected = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedNavIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? _primaryBlue.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected ? _primaryBlue : _textMuted,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? _primaryBlue : _textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  DATA MODELS
// ═══════════════════════════════════════════════════════════════

class _ServiceCategory {
  final IconData icon;
  final String label;
  const _ServiceCategory({required this.icon, required this.label});
}

class _Tradesman {
  final String name;
  final String skill;
  final double rating;
  final bool isAvailable;
  final Color avatarColor;
  final String initials;
  final List<String> achievements;
  final List<String> certificates;
  final List<String> recentWorks;
  const _Tradesman({
    required this.name,
    required this.skill,
    required this.rating,
    required this.isAvailable,
    required this.avatarColor,
    required this.initials,
    required this.achievements,
    required this.certificates,
    required this.recentWorks,
  });
}

class _ServiceRequest {
  final String description;
  final String status;
  final String tradesmanName;
  final String scheduledDate;
  const _ServiceRequest({
    required this.description,
    required this.status,
    required this.tradesmanName,
    required this.scheduledDate,
  });
}

class _CommunityPost {
  final String authorName;
  final String category;
  final String message;
  final String timeLabel;
  final String? photoLabel;

  const _CommunityPost({
    required this.authorName,
    required this.category,
    required this.message,
    required this.timeLabel,
    this.photoLabel,
  });
}

class _MessageThread {
  final String tradesmanName;
  final String skill;
  String lastMessage;
  String timeLabel;
  int unreadCount;
  final List<_ChatMessage> messages;

  _MessageThread({
    required this.tradesmanName,
    required this.skill,
    required this.lastMessage,
    required this.timeLabel,
    this.unreadCount = 0,
    required this.messages,
  });
}

class _ChatMessage {
  final String sender;
  final String text;

  const _ChatMessage({required this.sender, required this.text});
}
