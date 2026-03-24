import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fixit_application/screens/homeowner_registration.dart';
import 'package:flutter_fixit_application/screens/tradesperson_registration.dart';
import 'package:flutter_fixit_application/screens/forgot_password.dart';
import 'package:flutter_fixit_application/screens/homeowner/homeowner_dashboard.dart';
import 'package:flutter_fixit_application/screens/tradesperson/tradesperson_dashboard.dart';

/// Login screen for the Fix It Marketplace Android app.
/// This screen provides email/password authentication UI for users.
/// Navigation stubs are marked with TODO for service integration.
class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isCreateAccountAnimating = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _createAccountSkeletonController;

  // ── Color Palette ──────────────────────────────────────────────
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _accentOrange = Color(0xFFF97316);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _inputBorder = Color(0xFFD1D5DB);
  static const Color _inputFill = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _createAccountSkeletonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _createAccountSkeletonController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final result = await ApiService.loginUser(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', result['token'] as String);
        final role = (result['user'] as Map)['role'] as String;
        await prefs.setString('role', role);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome back! Logged in as $role'),
              backgroundColor: _primaryBlue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          final normalizedRole = role.toLowerCase();
          final Widget destination =
              normalizedRole == 'tradesperson' || normalizedRole == 'tradesman'
              ? const TradesmanDashboard()
              : const HomeownerDashboardScreen();

          Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute(builder: (_) => destination));
        }
      } on HttpException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connection error. Is the server running?'),
              backgroundColor: Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: EdgeInsets.all(16),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showAccountTypeDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header Icon ─────────────────────────────────
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _primaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_add_rounded,
                    size: 32,
                    color: _primaryBlue,
                  ),
                ),

                const SizedBox(height: 20),

                // ── Title ───────────────────────────────────────
                Text(
                  'Create an Account',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 8),

                // ── Subtitle ────────────────────────────────────
                Text(
                  'Choose your account type to get started',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: _textMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 28),

                // ── Homeowner Option ────────────────────────────
                _buildAccountTypeOption(
                  icon: Icons.home_rounded,
                  title: 'Homeowner',
                  description:
                      'Find trusted professionals for your home projects',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToHomeownerRegistration();
                  },
                ),

                const SizedBox(height: 12),

                // ── Tradesperson Option ─────────────────────────
                _buildAccountTypeOption(
                  icon: Icons.handyman_rounded,
                  title: 'Tradesperson',
                  description: 'Offer your services and grow your business',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToTradespersonRegistration();
                  },
                ),

                const SizedBox(height: 24),

                // ── Cancel Button ───────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textMuted,
                      side: BorderSide(color: _inputBorder, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleCreateAccountTap() async {
    if (_isCreateAccountAnimating) return;

    setState(() => _isCreateAccountAnimating = true);
    await _createAccountSkeletonController.forward(from: 0);

    if (!mounted) return;

    setState(() => _isCreateAccountAnimating = false);
    _showAccountTypeDialog();
  }

  Widget _buildAccountTypeOption({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: _inputBorder, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // ── Icon Container ────────────────────────────────
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 26, color: _primaryBlue),
              ),

              const SizedBox(width: 14),

              // ── Text Content ──────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: _textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Arrow Icon ────────────────────────────────────
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: _accentOrange,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToHomeownerRegistration() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeownerRegistrationScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _navigateToTradespersonRegistration() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const TradespersonRegistrationScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ForgotPasswordScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _backgroundGray,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          SizedBox(height: constraints.maxHeight * 0.08),

                          // ── Logo & Branding ────────────────────
                          _buildBranding(),

                          SizedBox(height: constraints.maxHeight * 0.05),

                          // ── Login Form ─────────────────────────
                          _buildLoginForm(),

                          const SizedBox(height: 24),

                          // ── Login Button ───────────────────────
                          _buildLoginButton(),

                          const SizedBox(height: 20),

                          // ── Create Account Link ────────────────
                          _buildCreateAccountLink(),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  WIDGETS
  // ═══════════════════════════════════════════════════════════════

  /// Centered branding section: logo icon, app name, and tagline.
  Widget _buildBranding() {
    return Column(
      children: [
        // ── App Logo ────────────────────────────────────────────
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _primaryBlue.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'lib/assets/fixit_logo.png',
              width: 90,
              height: 90,
              fit: BoxFit.contain,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── App Name ───────────────────────────────────────────
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Fix It',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _primaryBlue,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: ' Marketplace',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: _textDark,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // ── Tagline: Fast . Verified . Local ───────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTaglineChip('Fast'),
            _buildTaglineDot(),
            _buildTaglineChip('Verified'),
            _buildTaglineDot(),
            _buildTaglineChip('Local'),
          ],
        ),
      ],
    );
  }

  Widget _buildTaglineChip(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _textMuted,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildTaglineDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 4,
        height: 4,
        decoration: const BoxDecoration(
          color: _accentOrange,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// Email and password form fields with validation.
  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Email Field ──────────────────────────────────────
          _buildFieldLabel('Email Address'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: TextStyle(
              fontSize: 15,
              color: _textDark,
              fontWeight: FontWeight.w500,
            ),
            decoration: _inputDecoration(
              hintText: 'Enter your email',
              prefixIcon: Icons.email_outlined,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email address';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // ── Password Field ───────────────────────────────────
          _buildFieldLabel('Password'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
            style: TextStyle(
              fontSize: 15,
              color: _textDark,
              fontWeight: FontWeight.w500,
            ),
            decoration: _inputDecoration(
              hintText: 'Enter your password',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _textMuted,
                  size: 20,
                ),
                splashRadius: 20,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          // ── Forgot Password ──────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _navigateToForgotPassword,
              style: TextButton.styleFrom(
                foregroundColor: _primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _primaryBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _textDark,
        letterSpacing: 0.2,
      ),
    );
  }

  /// Shared input decoration for all TextFormField widgets.
  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 14,
        color: _textMuted.withValues(alpha: 0.7),
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 16, right: 12),
        child: Icon(prefixIcon, size: 20, color: _textMuted),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _inputBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _inputBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      errorStyle: const TextStyle(fontSize: 12),
    );
  }

  /// Full-width LOGIN button with loading spinner state.
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primaryBlue.withValues(alpha: 0.6),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'LOGIN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }

  /// "Don't have an account? Create an Account" link row.
  Widget _buildCreateAccountLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(
            fontSize: 14,
            color: _textMuted.withValues(alpha: 0.7),
            fontWeight: FontWeight.w400,
          ),
        ),
        GestureDetector(
          onTap: _handleCreateAccountTap,
          child: _isCreateAccountAnimating
              ? AnimatedBuilder(
                  animation: _createAccountSkeletonController,
                  builder: (context, child) {
                    final pulse =
                        0.55 + (_createAccountSkeletonController.value * 0.25);

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        width: 132,
                        height: 18,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFD1D5DB,
                            ).withValues(alpha: pulse),
                          ),
                        ),
                      ),
                    );
                  },
                )
              : const Text(
                  'Create an Account',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _accentOrange,
                    decoration: TextDecoration.underline,
                    decorationColor: _accentOrange,
                  ),
                ),
        ),
      ],
    );
  }
}
