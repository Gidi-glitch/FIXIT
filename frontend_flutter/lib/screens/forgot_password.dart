import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  // ── Controllers ───────────────────────────────────────────────
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  // ── Pagination ────────────────────────────────────────────────
  late PageController _pageController;
  int _currentStep = 0;

  // ── State variables ───────────────────────────────────────────
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _canResendOtp = false;
  int _resendCountdown = 60;
  String? _errorMessage;
  String? _verifiedOtp;

  // ── Color constants ───────────────────────────────────────────
  final Color _primaryBlue = const Color(0xFF0066CC);
  final Color _neutralGray = const Color(0xFFF5F5F5);
  final Color _textPrimary = const Color(0xFF1A1A1A);
  final Color _textMuted = const Color(0xFF757575);
  final Color _successGreen = const Color(0xFF4CAF50);
  final Color _errorRed = const Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────────
  void _goToStep(int step) {
    setState(() => _errorMessage = null);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _goToStep(_currentStep + 1);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  // ── API Mock Calls ────────────────────────────────────────────
  Future<void> _sendResetCode() async {
    setState(() => _errorMessage = null);

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address');
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.forgotPassword(email: email);
      if (!mounted) return;
      _showSuccessSnackbar('Verification code sent to $email');
      _nextStep();
      _startResendTimer();
    } on HttpException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
      _showErrorSnackbar(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Connection error. Please try again.');
      _showErrorSnackbar('Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.verifyResetCode(
        email: _emailController.text.trim(),
        otp: otp,
      );
      _verifiedOtp = otp;
      if (!mounted) return;
      _showSuccessSnackbar('Code verified successfully');
      _nextStep();
    } on HttpException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
      _showErrorSnackbar(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Connection error. Please try again.');
      _showErrorSnackbar('Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    setState(() => _errorMessage = null);

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      setState(
        () => _errorMessage =
            'Password must contain at least one uppercase letter',
      );
      return;
    }

    if (password.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    if (_verifiedOtp == null) {
      setState(() => _errorMessage = 'Please verify OTP first');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.resetPassword(
        email: _emailController.text.trim(),
        otp: _verifiedOtp!,
        newPassword: password,
      );
      if (!mounted) return;
      _showSuccessSnackbar('Password reset successfully!');
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.of(context).pop();
    } on HttpException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
      _showErrorSnackbar(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Connection error. Please try again.');
      _showErrorSnackbar('Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _canResendOtp = false;
      _resendCountdown = 60;
      _errorMessage = null;
    });

    try {
      await ApiService.forgotPassword(email: _emailController.text.trim());
      _startResendTimer();
      _showSuccessSnackbar('Code resent to ${_emailController.text.trim()}');
    } on HttpException catch (e) {
      setState(() => _errorMessage = e.message);
      _showErrorSnackbar(e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Connection error. Please try again.');
      _showErrorSnackbar('Connection error. Please try again.');
    }
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _resendCountdown--);
        if (_resendCountdown <= 0) {
          setState(() => _canResendOtp = true);
          return false;
        }
      }
      return true;
    });
  }

  // ── Validation ────────────────────────────────────────────────
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // ── Snackbars ─────────────────────────────────────────────────
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: _successGreen),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _successGreen.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── OTP Input Handler ─────────────────────────────────────────
  void _handleOtpInput(String value, int index) {
    if (value.isEmpty) return;

    if (value.length > 1) {
      // Paste functionality
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (int i = 0; i < digits.length && i < 6; i++) {
        _otpControllers[i].text = digits[i];
      }
      if (digits.length >= 6) {
        _otpFocusNodes[5].unfocus();
      }
    } else {
      // Single digit entered
      if (index < 5 && value.isNotEmpty) {
        _otpFocusNodes[index + 1].requestFocus();
      }
    }
  }

  void _handleOtpBackspace(String value, int index) {
    if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentStep > 0) {
          _previousStep();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: _textPrimary),
            onPressed: () {
              if (_currentStep > 0) {
                _previousStep();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: const Text(''),
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentStep = index),
          physics: const NeverScrollableScrollPhysics(),
          children: [_buildEmailStep(), _buildOtpStep(), _buildPasswordStep()],
        ),
      ),
    );
  }

  // ─── Step 1: Email ──────────────────────────────────────────
  Widget _buildEmailStep() {
    return _buildStepContainer(
      title: 'Forgot Password',
      subtitle:
          'Enter your registered email and we\'ll send you a verification code.',
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              enabled: !_isLoading,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Enter your email',
                hintStyle: TextStyle(color: _textMuted),
                filled: true,
                fillColor: _neutralGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _primaryBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: _textMuted,
                  size: 20,
                ),
              ),
              style: TextStyle(fontSize: 15, color: _textPrimary),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: _errorRed,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendResetCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  disabledBackgroundColor: _primaryBlue.withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Send Code',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Back to Login',
                style: TextStyle(color: _primaryBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step 2: OTP Verification ──────────────────────────────
  Widget _buildOtpStep() {
    return _buildStepContainer(
      title: 'Verify Code',
      subtitle: 'Enter the 6-digit verification code sent to your email.',
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 50,
                  height: 60,
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1a1a1a),
                    ),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        _handleOtpBackspace(value, index);
                      } else {
                        _handleOtpInput(value, index);
                      }
                    },
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: _neutralGray,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _primaryBlue, width: 2),
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: _errorRed,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  disabledBackgroundColor: _primaryBlue.withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Verify Code',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            if (!_canResendOtp)
              Text(
                'Resend code in ${_resendCountdown}s',
                style: TextStyle(color: _textMuted, fontSize: 13),
              )
            else
              TextButton(
                onPressed: _resendCode,
                child: Text(
                  'Resend Code',
                  style: TextStyle(color: _primaryBlue),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Step 3: Reset Password ────────────────────────────────
  Widget _buildPasswordStep() {
    return _buildStepContainer(
      title: 'Reset Password',
      subtitle: 'Create a new password for your account.',
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _passwordController,
              enabled: !_isLoading,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                hintText: 'New password',
                hintStyle: TextStyle(color: _textMuted),
                filled: true,
                fillColor: _neutralGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _primaryBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: _textMuted,
                  size: 20,
                ),
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _showPassword = !_showPassword),
                  child: Icon(
                    _showPassword ? Icons.visibility : Icons.visibility_off,
                    color: _textMuted,
                    size: 20,
                  ),
                ),
              ),
              style: TextStyle(fontSize: 15, color: _textPrimary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              enabled: !_isLoading,
              obscureText: !_showConfirmPassword,
              decoration: InputDecoration(
                hintText: 'Confirm password',
                hintStyle: TextStyle(color: _textMuted),
                filled: true,
                fillColor: _neutralGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _primaryBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: _textMuted,
                  size: 20,
                ),
                suffixIcon: GestureDetector(
                  onTap: () => setState(
                    () => _showConfirmPassword = !_showConfirmPassword,
                  ),
                  child: Icon(
                    _showConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: _textMuted,
                    size: 20,
                  ),
                ),
              ),
              style: TextStyle(fontSize: 15, color: _textPrimary),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: _errorRed,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  disabledBackgroundColor: _primaryBlue.withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Reset Password',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step Container ────────────────────────────────────────
  Widget _buildStepContainer({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.lock_reset_rounded,
                color: _primaryBlue,
                size: 28,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: _textMuted, height: 1.5),
            ),
            const SizedBox(height: 32),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
