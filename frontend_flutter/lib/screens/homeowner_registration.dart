import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fixit_application/screens/userlogin_screen.dart';

/// Homeowner registration screen for the Fix It Marketplace Android app.
/// Collects: Full Name, Email, Phone, Barangay, Password, Confirm Password.
/// Navigation stubs are marked with TODO for service integration.
class HomeownerRegistrationScreen extends StatefulWidget {
  const HomeownerRegistrationScreen({super.key});

  @override
  State<HomeownerRegistrationScreen> createState() =>
      _HomeownerRegistrationScreenState();
}

class _HomeownerRegistrationScreenState
    extends State<HomeownerRegistrationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  String? _selectedBarangay;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // ── Color Palette (matches login screens) ──────────────────────
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _accentOrange = Color(0xFFF97316);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _inputBorder = Color(0xFFD1D5DB);
  static const Color _inputFill = Color(0xFFFFFFFF);

  // ── Barangay List (sample – replace with your local data) ──────
  static const List<String> _barangayList = [
    'Atisan',
    'Bagong Bayan II-A',
    'Bagong Pook VI-C',
    'Barangay I-A',
    'Barangay I-B',
    'Barangay II-A',
    'Barangay II-B',
    'Barangay II-C',
    'Barangay II-D',
    'Barangay II-E',
    'Barangay II-F',
    'Barangay III-A',
    'Barangay III-B',
    'Barangay III-C',
    'Barangay III-D',
    'Barangay III-E',
    'Barangay III-F',
    'Barangay IV-A',
    'Barangay IV-B',
    'Barangay IV-C',
    'Barangay V-A',
    'Barangay V-B',
    'Barangay V-C',
    'Barangay V-D',
    'Barangay VI-A',
    'Barangay VI-B',
    'Barangay VI-D',
    'Barangay VI-E',
    'Barangay VII-A',
    'Barangay VII-B',
    'Barangay VII-C',
    'Barangay VII-D',
    'Barangay VII-E',
    'Bautista',
    'Concepcion',
    'Del Remedio',
    'Dolores',
    'San Antonio 1',
    'San Antonio 2',
    'San Bartolome',
    'San Buenaventura',
    'San Crispin',
    'San Cristobal',
    'San Diego',
    'San Francisco',
    'San Gabriel',
    'San Gregorio',
    'San Ignacio',
    'San Isidro',
    'San Joaquin',
    'San Jose',
    'San Juan',
    'San Lorenzo',
    'San Lucas 1',
    'San Lucas 2',
    'San Marcos',
    'San Mateo',
    'San Miguel',
    'San Nicolas',
    'San Pedro',
    'San Rafael',
    'San Roque',
    'San Vicente',
    'Santa Ana',
    'Santa Catalina',
    'Santa Cruz',
    'Santa Elena',
    'Santa Filomena',
    'Santa Isabel',
    'Santa Maria',
    'Santa Maria Magdalena',
    'Santa Monica',
    'Santa Veronica',
    'Santiago I',
    'Santiago II',
    'Santisimo Rosario',
    'Santo Angel',
    'Santo Cristo',
    'Santo Niño',
    'Soledad',
  ];

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
    _fadeController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      // TODO: Integrate registration service
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const UserLoginScreen(),
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
                          // ── Back to Login header ─────────────
                          _buildBackHeader(),

                          const SizedBox(height: 16),

                          // ── Logo & Branding ──────────────────
                          _buildBranding(),

                          const SizedBox(height: 28),

                          // ── Registration Form ────────────────
                          _buildRegistrationForm(),

                          const SizedBox(height: 28),

                          // ── Register Button ──────────────────
                          _buildRegisterButton(),

                          const SizedBox(height: 20),

                          // ── Login Link ───────────────────────
                          _buildLoginLink(),

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

  /// Top-left back button to return to login.
  Widget _buildBackHeader() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: TextButton(
          onPressed: _navigateToLogin,
          style: TextButton.styleFrom(
            foregroundColor: _primaryBlue,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_ios_rounded, size: 14, color: _primaryBlue),
              const SizedBox(width: 4),
              Text(
                'Back to Login',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _primaryBlue,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Centered branding: logo, app name, tagline, and registration badge.
  Widget _buildBranding() {
    return Column(
      children: [
        // ── App Logo ────────────────────────────────────────────
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _primaryBlue.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'lib/assets/fixit_logo.png',
              width: 72,
              height: 72,
              fit: BoxFit.contain,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Screen Title ───────────────────────────────────────
        Text(
          'Create Homeowner Account',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _primaryBlue,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 6),

        // ── Subtitle ───────────────────────────────────────────
        Text(
          'Join your local community of homeowners',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: _textMuted,
            letterSpacing: 0.1,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 10),

        // ── Homeowner badge ────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: _primaryBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.home_rounded, size: 14, color: _primaryBlue),
              const SizedBox(width: 6),
              Text(
                'Homeowner Registration',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _primaryBlue,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Registration form with all six fields.
  Widget _buildRegistrationForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Full Name ─────────────────────────────────────
          _buildFieldLabel('Full Name'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            style: _inputTextStyle(),
            decoration: _inputDecoration(
              hintText: 'Enter your full name',
              prefixIcon: Icons.person_outline_rounded,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your full name';
              }
              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 18),

          // ── 2. Email Address ─────────────────────────────────
          _buildFieldLabel('Email Address'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: _inputTextStyle(),
            decoration: _inputDecoration(
              hintText: 'Enter your email address',
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

          const SizedBox(height: 18),

          // ── 3. Phone Number ──────────────────────────────────
          _buildFieldLabel('Phone Number'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            style: _inputTextStyle(),
            decoration: _inputDecoration(
              hintText: 'e.g. 09171234567',
              prefixIcon: Icons.phone_outlined,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your phone number';
              }
              if (value.trim().length < 10) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),

          const SizedBox(height: 18),

          // ── 4. Barangay (Dropdown) ───────────────────────────
          _buildFieldLabel('Barangay'),
          const SizedBox(height: 8),
          _buildBarangayDropdown(),

          const SizedBox(height: 18),

          // ── 5. Password ──────────────────────────────────────
          _buildFieldLabel('Password'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            style: _inputTextStyle(),
            decoration: _inputDecoration(
              hintText: 'Create a password',
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
                return 'Please create a password';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
                return 'Password must include an uppercase letter';
              }
              if (!RegExp(r'(?=.*[0-9])').hasMatch(value)) {
                return 'Password must include a number';
              }
              return null;
            },
          ),

          const SizedBox(height: 18),

          // ── 6. Confirm Password ──────────────────────────────
          _buildFieldLabel('Confirm Password'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleRegister(),
            style: _inputTextStyle(),
            decoration: _inputDecoration(
              hintText: 'Re-enter your password',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
                icon: Icon(
                  _obscureConfirmPassword
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
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  /// Barangay dropdown styled to match the TextFormField inputs.
  Widget _buildBarangayDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedBarangay,
      hint: Text(
        'Select your barangay',
        style: TextStyle(
          fontSize: 14,
          color: _textMuted.withValues(alpha: 0.7),
          fontWeight: FontWeight.w400,
        ),
      ),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: _textMuted,
        size: 22,
      ),
      isExpanded: true,
      dropdownColor: _inputFill,
      borderRadius: BorderRadius.circular(16),
      style: _inputTextStyle(),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 12),
          child: Icon(Icons.location_on_outlined, size: 20, color: _textMuted),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: _inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
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
      ),
      items: _barangayList.map((barangay) {
        return DropdownMenuItem<String>(value: barangay, child: Text(barangay));
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedBarangay = value);
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select your barangay';
        }
        return null;
      },
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────

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

  TextStyle _inputTextStyle() {
    return TextStyle(
      fontSize: 15,
      color: _textDark,
      fontWeight: FontWeight.w500,
    );
  }

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

  /// Full-width REGISTER button with loading state.
  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
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
                'CREATE ACCOUNT',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }

  /// "Already have an account? Login" link row.
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
            fontSize: 14,
            color: _textMuted,
            fontWeight: FontWeight.w400,
          ),
        ),
        GestureDetector(
          onTap: _navigateToLogin,
          child: Text(
            'Login',
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
