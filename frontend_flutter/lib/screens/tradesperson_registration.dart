import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_fixit_application/screens/login_screen.dart';
import 'dart:io';
import 'package:flutter_fixit_application/services/api_service.dart';
import '../shared/calauan_barangays.dart';

/// Multi-step tradesperson registration screen for the Fix It Marketplace.
/// Three steps: Basic Information, Professional Details, Verification & Documents.
/// Navigation stubs are marked with TODO for service integration.
class TradespersonRegistrationScreen extends StatefulWidget {
  const TradespersonRegistrationScreen({super.key});

  @override
  State<TradespersonRegistrationScreen> createState() =>
      _TradespersonRegistrationScreenState();
}

class _TradespersonRegistrationScreenState
    extends State<TradespersonRegistrationScreen>
    with SingleTickerProviderStateMixin {
  // ── Step management ────────────────────────────────────────────
  int _currentStep = 0;
  static const int _totalSteps = 3;

  // ── Form keys per step ─────────────────────────────────────────
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  // ── Step 1: Basic Information controllers ──────────────────────
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // ── Step 2: Professional Details ───────────────────────────────
  String? _selectedTradeCategory;
  final _experienceController = TextEditingController();
  String? _selectedBarangay;
  final _bioController = TextEditingController();

  // ── Step 3: Verification ───────────────────────────────────────
  String? _selectedGovernmentIdType;
  PlatformFile? _governmentIdFile;
  bool _isUploadingGovernmentId = false;

  String? _selectedLicenseType;
  PlatformFile? _professionalLicenseFile;
  bool _isUploadingLicense = false;

  bool _confirmAccuracy = false;
  bool _isSubmitting = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // ── Color Palette (matches project-wide) ───────────────────────
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _accentOrange = Color(0xFFF97316);
  static const Color _backgroundGray = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _inputBorder = Color(0xFFD1D5DB);
  static const Color _inputFill = Color(0xFFFFFFFF);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _errorRed = Color(0xFFEF4444);

  // ── Trade categories ───────────────────────────────────────────
  static const List<String> _tradeCategories = [
    'Plumbing',
    'Electrical',
    'HVAC',
    'Carpentry',
    'Appliance Repair',
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

  // ── Professional License Types ─────────────────
  static const List<String> _licenseTypeList = [
    'PRC License',
    'TESDA Certificate',
    'NTC License',
    'DTI Business Permit',
    'Barangay Business Clearance',
    'Other Certification',
  ];

  // ── Step titles ────────────────────────────────────────────────
  static const List<String> _stepTitles = [
    'Basic Information',
    'Professional Details',
    'Verification & Documents',
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
    _experienceController.dispose();
    _bioController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ── Step navigation ────────────────────────────────────────────

  void _nextStep() {
    final isValid = _validateCurrentStep();
    if (isValid) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _step1Key.currentState?.validate() ?? false;
      case 1:
        return _step2Key.currentState?.validate() ?? false;
      case 2:
        return _step3Key.currentState?.validate() ?? false;
      default:
        return false;
    }
  }

  Future<void> _handleSubmit() async {
    if (_step3Key.currentState?.validate() ?? false) {
      // Validate government ID upload
      if (_governmentIdFile == null) {
        _showErrorSnackBar('Please upload your Government ID');
        return;
      }

      // Validate professional license upload
      if (_professionalLicenseFile == null) {
        _showErrorSnackBar('Please upload your Professional License');
        return;
      }

      if (!_confirmAccuracy) {
        _showErrorSnackBar('Please confirm the information is accurate');
        return;
      }

      setState(() => _isSubmitting = true);

      try {
        await ApiService.registerTradesperson(
          firstName: _nameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          tradeCategory: _selectedTradeCategory!,
          yearsExperience: int.tryParse(_experienceController.text.trim()) ?? 0,
          serviceBarangay: _selectedBarangay!,
          bio: _bioController.text.trim(),
          governmentIdType: _selectedGovernmentIdType!,
          governmentIdDocument: File(_governmentIdFile!.path!),
          licenseType: _selectedLicenseType!,
          licenseDocument: File(_professionalLicenseFile!.path!),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Registration submitted! Your documents are pending verification.',
              ),
              backgroundColor: Color(0xFF1E3A8A),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
            ),
          );
          _navigateToLogin();
        }
      } on HttpException catch (e) {
        if (mounted) _showErrorSnackBar(e.message);
      } catch (_) {
        if (mounted) {
          _showErrorSnackBar('Connection error. Is the server running?');
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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

  // ── File Picker Functions ──────────────────────────────────────

  Future<void> _pickGovernmentId() async {
    if (_selectedGovernmentIdType == null) {
      _showErrorSnackBar('Please select an ID type first');
      return;
    }

    setState(() => _isUploadingGovernmentId = true);

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        final file = result.files.first;
        if (file.size > 5 * 1024 * 1024) {
          if (mounted) {
            _showErrorSnackBar('File size must be less than 5MB');
          }
          return;
        }
        setState(() => _governmentIdFile = file);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingGovernmentId = false);
      }
    }
  }

  Future<void> _pickProfessionalLicense() async {
    if (_selectedLicenseType == null) {
      _showErrorSnackBar('Please select a license type first');
      return;
    }

    setState(() => _isUploadingLicense = true);

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        final file = result.files.first;
        if (file.size > 5 * 1024 * 1024) {
          if (mounted) {
            _showErrorSnackBar('File size must be less than 5MB');
          }
          return;
        }
        setState(() => _professionalLicenseFile = file);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingLicense = false);
      }
    }
  }

  void _removeGovernmentId() {
    setState(() {
      _governmentIdFile = null;
    });
  }

  void _removeProfessionalLicense() {
    setState(() {
      _professionalLicenseFile = null;
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
            child: Column(
              children: [
                // ── Top header ──────────────────────────────────
                _buildHeader(),

                // ── Step indicator ──────────────────────────────
                _buildStepIndicator(),

                // ── Scrollable step content ─────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        _buildStepContent(),
                        const SizedBox(height: 32),
                        _buildNavigationButtons(),
                        const SizedBox(height: 20),
                        _buildLoginLink(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // ── Back button ──────────────────────────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextButton(
                onPressed: _currentStep > 0 ? _previousStep : _navigateToLogin,
                style: TextButton.styleFrom(
                  foregroundColor: _primaryBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 14,
                      color: _primaryBlue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _currentStep > 0 ? 'Back' : 'Back to Login',
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
          ),

          const SizedBox(height: 8),

          // ── Logo + Title ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'lib/assets/fixit_logo.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Tradesperson Registration',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _primaryBlue,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // ── Tradesperson badge ────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _accentOrange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _accentOrange.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, size: 12, color: _accentOrange),
                const SizedBox(width: 5),
                Text(
                  'Professional Verification',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _accentOrange,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  STEP INDICATOR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          // ── Step circles with connecting lines ────────────────
          Row(
            children: List.generate(_totalSteps * 2 - 1, (index) {
              if (index.isEven) {
                final stepIndex = index ~/ 2;
                final isActive = stepIndex == _currentStep;
                final isCompleted = stepIndex < _currentStep;
                return _buildStepCircle(
                  stepIndex: stepIndex,
                  isActive: isActive,
                  isCompleted: isCompleted,
                );
              } else {
                final beforeIndex = index ~/ 2;
                final isCompleted = beforeIndex < _currentStep;
                return Expanded(
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? _accentOrange
                          : _inputBorder.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }
            }),
          ),

          const SizedBox(height: 10),

          // ── Step labels ──────────────────────────────────────
          Row(
            children: List.generate(_totalSteps * 2 - 1, (index) {
              if (index.isEven) {
                final stepIndex = index ~/ 2;
                final isActive = stepIndex == _currentStep;
                final isCompleted = stepIndex < _currentStep;
                final double labelOffsetX = switch (stepIndex) {
                  0 => -24,
                  1 => 0,
                  _ => 24,
                };
                return Transform.translate(
                  offset: Offset(labelOffsetX, 0),
                  child: SizedBox(
                    width: 80,
                    child: Text(
                      _stepTitles[stepIndex],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: isActive || isCompleted
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isActive
                            ? _accentOrange
                            : isCompleted
                            ? _primaryBlue
                            : _textMuted,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                );
              } else {
                return const Expanded(child: SizedBox());
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle({
    required int stepIndex,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isCompleted
            ? _accentOrange
            : isActive
            ? _accentOrange
            : _inputFill,
        shape: BoxShape.circle,
        border: Border.all(
          color: isCompleted || isActive ? _accentOrange : _inputBorder,
          width: isActive ? 2.5 : 1.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: _accentOrange.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
            : Text(
                '${stepIndex + 1}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : _textMuted,
                ),
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  STEP CONTENT
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStepContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
            child: child,
          ),
        );
      },
      child: _currentStep == 0
          ? _buildStep1(key: const ValueKey(0))
          : _currentStep == 1
          ? _buildStep2(key: const ValueKey(1))
          : _buildStep3(key: const ValueKey(2)),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  STEP 1: Basic Information
  // ─────────────────────────────────────────────────────────────

  Widget _buildStep1({Key? key}) {
    return Form(
      key: _step1Key,
      child: Column(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Basic Information',
            'Let\'s start with your personal details',
          ),

          const SizedBox(height: 20),

          // First Name
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

          // Last Name
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

          // Email
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

          // Phone
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

          // Password
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
                return 'Must include an uppercase letter';
              }
              if (!RegExp(r'(?=.*[0-9])').hasMatch(value)) {
                return 'Must include a number';
              }
              return null;
            },
          ),

          const SizedBox(height: 18),

          // Confirm Password
          _buildFieldLabel('Confirm Password'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
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

  // ─────────────────────────────────────────────────────────────
  //  STEP 2: Professional Details
  // ─────────────────────────────────────────────────────────────

  Widget _buildStep2({Key? key}) {
    return Form(
      key: _step2Key,
      child: Column(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Professional Details',
            'Tell us about your trade expertise',
          ),

          const SizedBox(height: 20),

          // Trade Category
          _buildFieldLabel('Trade Category'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedTradeCategory,
            hint: Text(
              'Select your trade',
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
            decoration: _dropdownDecoration(
              prefixIcon: Icons.construction_rounded,
            ),
            items: _tradeCategories.map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedTradeCategory = value);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select your trade category';
              }
              return null;
            },
          ),

          const SizedBox(height: 18),

          // Years of Experience
          _buildFieldLabel('Years of Experience'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _experienceController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            style: _inputTextStyle(),
            decoration: _inputDecoration(
              hintText: 'e.g. 5',
              prefixIcon: Icons.work_outline_rounded,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your years of experience';
              }
              return null;
            },
          ),

          const SizedBox(height: 18),

          // Service Barangay
          _buildFieldLabel('Service Barangay'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedBarangay,
            hint: Text(
              'Select service area',
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
            decoration: _dropdownDecoration(
              prefixIcon: Icons.location_on_outlined,
            ),
            items: kCalauanBarangays.map((barangay) {
              return DropdownMenuItem<String>(
                value: barangay,
                child: Text(barangay),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedBarangay = value);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select your service barangay';
              }
              return null;
            },
          ),

          const SizedBox(height: 18),

          // Professional Bio
          _buildFieldLabel('Short Professional Bio'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _bioController,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            maxLines: 4,
            maxLength: 300,
            style: _inputTextStyle(),
            decoration: InputDecoration(
              hintText:
                  'Briefly describe your skills, specialties, and experience...',
              hintStyle: TextStyle(
                fontSize: 14,
                color: _textMuted.withValues(alpha: 0.7),
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: _inputFill,
              contentPadding: const EdgeInsets.all(16),
              counterStyle: TextStyle(fontSize: 11, color: _textMuted),
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
                borderSide: BorderSide(color: _accentOrange, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Colors.redAccent,
                  width: 1.5,
                ),
              ),
              errorStyle: const TextStyle(fontSize: 12),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please provide a short professional bio';
              }
              if (value.trim().length < 20) {
                return 'Bio should be at least 20 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  STEP 3: Verification & Documents
  // ─────────────────────────────────────────────────────────────

  Widget _buildStep3({Key? key}) {
    return Form(
      key: _step3Key,
      child: Column(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Verification & Documents',
            'Upload documents for professional verification',
          ),

          const SizedBox(height: 20),

          // ══════════════════════════════════════════════════════
          // Government ID Section
          // ══════════════════════════════════════════════════════
          _buildDocumentUploadSection(
            title: 'Government-Issued ID',
            subtitle: 'Upload a valid government ID for identity verification',
            icon: Icons.badge_outlined,
            iconColor: _primaryBlue,
            selectedType: _selectedGovernmentIdType,
            typeList: _idTypeList,
            typeHint: 'Select ID type',
            onTypeChanged: (value) {
              setState(() => _selectedGovernmentIdType = value);
            },
            uploadedFile: _governmentIdFile,
            isUploading: _isUploadingGovernmentId,
            onPickFile: _pickGovernmentId,
            onRemoveFile: _removeGovernmentId,
          ),

          const SizedBox(height: 24),

          // ══════════════════════════════════════════════════════
          // Professional License Section
          // ══════════════════════════════════════════════════════
          _buildDocumentUploadSection(
            title: 'Professional License or Certification',
            subtitle: 'Upload proof of your professional qualifications',
            icon: Icons.workspace_premium_outlined,
            iconColor: _accentOrange,
            selectedType: _selectedLicenseType,
            typeList: _licenseTypeList,
            typeHint: 'Select license type',
            onTypeChanged: (value) {
              setState(() => _selectedLicenseType = value);
            },
            uploadedFile: _professionalLicenseFile,
            isUploading: _isUploadingLicense,
            onPickFile: _pickProfessionalLicense,
            onRemoveFile: _removeProfessionalLicense,
          ),

          const SizedBox(height: 24),

          // Accuracy confirmation checkbox
          _buildConfirmCheckbox(),

          const SizedBox(height: 20),

          // Helper text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _primaryBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _primaryBlue.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: _primaryBlue.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Applications are reviewed within 24-48 hours for verification.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: _primaryBlue.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Enhanced Document Upload Section with ID Type Dropdown
  Widget _buildDocumentUploadSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String? selectedType,
    required List<String> typeList,
    required String typeHint,
    required ValueChanged<String?> onTypeChanged,
    required PlatformFile? uploadedFile,
    required bool isUploading,
    required VoidCallback onPickFile,
    required VoidCallback onRemoveFile,
  }) {
    final hasFile = uploadedFile != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _inputFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasFile
              ? _successGreen.withValues(alpha: 0.4)
              : _inputBorder.withValues(alpha: 0.6),
          width: hasFile ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(19),
                topRight: Radius.circular(19),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Icon(icon, size: 22, color: iconColor)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _textDark,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          if (hasFile) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _successGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 12,
                                    color: _successGreen,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Uploaded',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _successGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: _textMuted,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Content ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Document Type Dropdown ─────────────────────────
                Text(
                  'Document Type',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  hint: Text(
                    typeHint,
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
                  borderRadius: BorderRadius.circular(12),
                  style: _inputTextStyle(),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _backgroundGray,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _inputBorder.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _inputBorder.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: iconColor, width: 1.5),
                    ),
                  ),
                  items: typeList.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: onTypeChanged,
                ),

                const SizedBox(height: 16),

                // ── Upload Area ────────────────────────────────────
                if (!hasFile)
                  _buildUploadZone(
                    isUploading: isUploading,
                    onTap: onPickFile,
                    accentColor: iconColor,
                  )
                else
                  _buildUploadedFileCard(
                    file: uploadedFile,
                    onReplace: onPickFile,
                    onRemove: onRemoveFile,
                    accentColor: iconColor,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Upload zone with dashed border
  Widget _buildUploadZone({
    required bool isUploading,
    required VoidCallback onTap,
    required Color accentColor,
  }) {
    return InkWell(
      onTap: isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: _backgroundGray,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _inputBorder.withValues(alpha: 0.6),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: isUploading
            ? Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        size: 26,
                        color: accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Tap to upload your document',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'JPG, PNG, or PDF (max 5MB)',
                    style: TextStyle(
                      fontSize: 12,
                      color: _textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Browse Files',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Card showing uploaded file with actions
  Widget _buildUploadedFileCard({
    required PlatformFile file,
    required VoidCallback onReplace,
    required VoidCallback onRemove,
    required Color accentColor,
  }) {
    final ext = _getFileExtension(file.name);
    final isPdf = ext == 'PDF';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _successGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _successGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // File type icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isPdf
                  ? Colors.red.withValues(alpha: 0.12)
                  : Colors.blue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                size: 24,
                color: isPdf ? Colors.red : Colors.blue,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatFileSize(file.size),
                      style: TextStyle(
                        fontSize: 11,
                        color: _textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _textMuted.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ext,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
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
              _buildFileActionButton(
                icon: Icons.swap_horiz_rounded,
                color: accentColor,
                onTap: onReplace,
                tooltip: 'Replace',
              ),
              const SizedBox(width: 6),
              _buildFileActionButton(
                icon: Icons.delete_outline_rounded,
                color: _errorRed,
                onTap: onRemove,
                tooltip: 'Remove',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Icon(icon, size: 18, color: color)),
        ),
      ),
    );
  }

  Widget _buildConfirmCheckbox() {
    return InkWell(
      onTap: () => setState(() => _confirmAccuracy = !_confirmAccuracy),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: _confirmAccuracy,
              onChanged: (value) =>
                  setState(() => _confirmAccuracy = value ?? false),
              activeColor: _accentOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              side: BorderSide(color: _inputBorder, width: 1.5),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                'I confirm that the information provided is accurate.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: _textDark,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  NAVIGATION BUTTONS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildNavigationButtons() {
    final isLastStep = _currentStep == _totalSteps - 1;
    final isFirstStep = _currentStep == 0;

    return Column(
      children: [
        // ── Primary action button ──────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : (isLastStep ? _handleSubmit : _nextStep),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentOrange,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _accentOrange.withValues(alpha: 0.6),
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    isLastStep ? 'SUBMIT APPLICATION' : 'CONTINUE',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
          ),
        ),

        // ── Secondary back button (steps 2 & 3) ───────────────
        if (!isFirstStep) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _previousStep,
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryBlue,
                side: BorderSide(color: _primaryBlue.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'BACK',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  LOGIN LINK
  // ═══════════════════════════════════════════════════════════════

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

  // ═══════════════════════════════════════════════════════════════
  //  SHARED HELPERS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStepHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textDark,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: _textMuted,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
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
        borderSide: BorderSide(color: _accentOrange, width: 1.5),
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

  InputDecoration _dropdownDecoration({required IconData prefixIcon}) {
    return InputDecoration(
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 16, right: 12),
        child: Icon(prefixIcon, size: 20, color: _textMuted),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
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
        borderSide: BorderSide(color: _accentOrange, width: 1.5),
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
}
