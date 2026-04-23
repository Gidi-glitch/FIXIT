import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_fixit_application/screens/login_screen.dart';
import 'dart:io';
import 'package:flutter_fixit_application/services/api_service.dart';

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
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isUploadingFile = false;

  String? _selectedBarangay;
  String? _selectedIdType;
  PlatformFile? _uploadedIdFile;

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
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _errorRed = Color(0xFFEF4444);

  // ── Barangay List (Calauan, Laguna) ──────
  static const List<String> _barangayList = [
    'Balayhangin',
    'Bangyas',
    'Dayap',
    'Hanggan',
    'Imok',
    'Kanluran (Poblacion)',
    'Lamot 1',
    'Lamot 2',
    'Limao',
    'Mabacan',
    'Masiit',
    'Paliparan',
    'Perez',
    'Prinza',
    'San Isidro',
    'Silangan (Poblacion)',
    'Santo Tomas',
  ];

  // ── Valid ID Types ─────────────────────────────
  static const List<String> _idTypeList = [
    'PhilSys National ID',
    'Driver\'s License',
    'Postal ID',
    'Voter\'s Certification',
    'Barangay ID',
    'Senior Citizen ID',
    'PWD ID',
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
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // REGISTER BUTTON LOGIC
  Future<void> _handleRegister() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_uploadedIdFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text('Please upload your ID document'),
              ],
            ),
            backgroundColor: _errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        await ApiService.registerHomeowner(
          firstName: _nameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          barangay: _selectedBarangay!,
          password: _passwordController.text,
          idType: _selectedIdType!,
          idDocument: File(_uploadedIdFile!.path!),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please log in.'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
            ),
          );
          _navigateToLogin();
        }
      } on HttpException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: _errorRed,
              behavior: SnackBarBehavior.floating,
<<<<<<< HEAD
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
=======
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connection error. Is the server running?'),
              backgroundColor: Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // FILE PICKER FUNCTION
  Future<void> _pickIdFile() async {
    // Check if ID type is selected first
    if (_selectedIdType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Text('Please select an ID type first'),
            ],
          ),
          backgroundColor: _errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isUploadingFile = true);

    try {
<<<<<<< HEAD
      final result = await FilePicker.platform.pickFiles(
=======
      final result = await FilePicker.pickFiles(
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        final file = result.files.first;
        // Check file size (max 5MB)
        if (file.size > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    const Text('File size must be less than 5MB'),
                  ],
                ),
                backgroundColor: _errorRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
          return;
        }

        setState(() {
          _uploadedIdFile = file;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingFile = false);
      }
    }
  }

  void _removeUploadedFile() {
    setState(() {
      _uploadedIdFile = null;
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _getFileExtension(String filename) {
    return filename.split('.').last.toUpperCase();
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

  /// Registration form with all fields.
  Widget _buildRegistrationForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. First Name ─────────────────────────────────────
          _buildFieldLabel('First Name'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            style: _inputTextStyle(),
            decoration: _inputDecoration(
              hintText: 'Enter your first name',
              prefixIcon: Icons.person_outline_rounded,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your first name';
              }
              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 18),

          // ── 2. Last Name ─────────────────────────────────────
          _buildFieldLabel('Last Name'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _lastNameController,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            style: _inputTextStyle(),
            decoration: _inputDecoration(
              hintText: 'Enter your last name',
              prefixIcon: Icons.person_outline_rounded,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your last name';
              }
              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 18),

          // ── 3. Email Address ─────────────────────────────────
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

          // ── 4. Phone Number ──────────────────────────────────
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

          // ── 5. Barangay (Dropdown) ───────────────────────────
          _buildFieldLabel('Barangay'),
          const SizedBox(height: 8),
          _buildBarangayDropdown(),

          const SizedBox(height: 24),

          // ── 6. ID Verification Section ───────────────────────
          _buildIdVerificationSection(),

          const SizedBox(height: 18),

          // ── 7. Password ──────────────────────────────────────
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

          // ── 8. Confirm Password ──────────────────────────────
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

  /// Enhanced ID Verification Section with modern upload UI
  Widget _buildIdVerificationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _inputFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _uploadedIdFile != null
              ? _successGreen.withValues(alpha: 0.3)
              : _inputBorder.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.verified_user_outlined,
                  color: _primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Identity Verification',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Upload a valid government ID',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: _textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (_uploadedIdFile != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _successGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: _successGreen, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Uploaded',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _successGreen,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // ID Type Dropdown
          Text(
            'Select ID Type',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textDark.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedIdType,
            hint: Text(
              'Choose your ID type',
              style: TextStyle(
                fontSize: 14,
                color: _textMuted.withValues(alpha: 0.7),
              ),
            ),
            isExpanded: true,
            borderRadius: BorderRadius.circular(16),
            style: _inputTextStyle(),
            decoration: InputDecoration(
              filled: true,
              fillColor: _backgroundGray,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(Icons.badge_outlined, color: _textMuted, size: 20),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 48),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _inputBorder.withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _inputBorder.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _primaryBlue, width: 1.5),
              ),
            ),
            items: _idTypeList.map((id) {
              return DropdownMenuItem<String>(value: id, child: Text(id));
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedIdType = value);
            },
            validator: (value) {
              if (value == null) {
                return 'Please select an ID type';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Upload Area
          Text(
            'Upload Document',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textDark.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),

          // Conditional: Show upload zone or uploaded file card
          _uploadedIdFile == null
              ? _buildUploadZone()
              : _buildUploadedFileCard(),

          const SizedBox(height: 12),

          // Supported formats info
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: _textMuted.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Supported: PDF, JPG, PNG (Max 5MB)',
                  style: TextStyle(
                    fontSize: 11,
                    color: _textMuted.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Upload zone when no file is selected
  Widget _buildUploadZone() {
    return GestureDetector(
      onTap: _isUploadingFile ? null : _pickIdFile,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: _backgroundGray,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _primaryBlue.withValues(alpha: 0.2),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          children: [
            // Upload Icon with animated container
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _primaryBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: _isUploadingFile
                  ? Padding(
                      padding: const EdgeInsets.all(18),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: _primaryBlue,
                      ),
                    )
                  : Icon(
                      Icons.cloud_upload_outlined,
                      color: _primaryBlue,
                      size: 30,
                    ),
            ),

            const SizedBox(height: 16),

            // Upload text
            Text(
              _isUploadingFile ? 'Uploading...' : 'Tap to upload your ID',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Take a clear photo or select a file',
              style: TextStyle(fontSize: 12, color: _textMuted),
            ),

            const SizedBox(height: 16),

            // Browse button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _primaryBlue,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_open_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Browse Files',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card showing uploaded file details
  Widget _buildUploadedFileCard() {
    final file = _uploadedIdFile!;
    final extension = _getFileExtension(file.name);
    final isImage = ['JPG', 'JPEG', 'PNG'].contains(extension);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _successGreen.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _successGreen.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // File type icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isImage
                  ? _accentOrange.withValues(alpha: 0.1)
                  : _errorRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: isImage
                  ? Icon(Icons.image_outlined, color: _accentOrange, size: 26)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.picture_as_pdf, color: _errorRed, size: 24),
                        Text(
                          'PDF',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: _errorRed,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(width: 4),

          // File details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _textMuted.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        extension,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatFileSize(file.size),
                      style: TextStyle(fontSize: 12, color: _textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Replace button
              IconButton(
                onPressed: _pickIdFile,
                icon: Icon(
                  Icons.refresh_rounded,
                  color: _primaryBlue,
                  size: 20,
                ),
                tooltip: 'Replace file',
                style: IconButton.styleFrom(
                  backgroundColor: _primaryBlue.withValues(alpha: 0.08),
                  padding: const EdgeInsets.all(4),
                ),
              ),
              // Delete button
              IconButton(
                onPressed: _removeUploadedFile,
                icon: Icon(Icons.close_rounded, color: _errorRed, size: 20),
                tooltip: 'Remove file',
                style: IconButton.styleFrom(
                  backgroundColor: _errorRed.withValues(alpha: 0.08),
                  padding: const EdgeInsets.all(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Barangay dropdown styled to match other inputs.
  Widget _buildBarangayDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedBarangay,
      menuMaxHeight: 250,
      hint: Text(
        'Select your barangay',
        style: TextStyle(
          fontSize: 14,
          color: _textMuted.withValues(alpha: 0.7),
        ),
      ),
      isExpanded: true,
      borderRadius: BorderRadius.circular(16),
      style: _inputTextStyle(),
      decoration: _inputDecoration(
        hintText: '',
        prefixIcon: Icons.location_on_outlined,
      ),
      items: _barangayList.map((barangay) {
        return DropdownMenuItem<String>(value: barangay, child: Text(barangay));
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedBarangay = value);
      },
      validator: (value) {
        if (value == null) {
          return 'Please select your barangay';
        }
        return null;
      },
    );
  }

  /// Register button with loading state.
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
          shadowColor: _primaryBlue.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
      ),
    );
  }

  /// Link to navigate back to login screen.
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(fontSize: 14, color: _textMuted),
        ),
        GestureDetector(
          onTap: _navigateToLogin,
          child: Text(
            'Sign In',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _primaryBlue,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  /// Standard label for form fields.
  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _textDark,
        letterSpacing: 0.1,
      ),
    );
  }

  /// Reusable text style for input fields.
  TextStyle _inputTextStyle() {
    return TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: _textDark,
    );
  }

  /// Reusable input decoration for text fields.
  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: _textMuted.withValues(alpha: 0.7),
      ),
      filled: true,
      fillColor: _inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 14, right: 10),
        child: Icon(prefixIcon, color: _textMuted, size: 20),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 48),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _errorRed, width: 1.5),
      ),
      errorStyle: TextStyle(fontSize: 12, color: _errorRed),
    );
  }
}
