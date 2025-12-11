import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;


class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

enum ForgotPasswordStage { email, otp, reset }

class _ForgotPasswordPageState extends State<ForgotPasswordPage> with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _otpCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _otpFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _backgroundAnimCtrl;
  
  ForgotPasswordStage _currentStage = ForgotPasswordStage.email;
  bool _isSubmitting = false;
  bool _passwordVisible = false;
  bool _confirmVisible = false;
  
  Timer? _resendTimer;
  int _resendSeconds = 0;
  double _scrollParallax = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _backgroundAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _emailFocus.dispose();
    _otpFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _scrollController.dispose();
    _backgroundAnimCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollParallax = _scrollController.offset;
    });
  }

  void _startResendTimer() {
    _resendSeconds = 180; // 3 minutes
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() {
          _resendSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      if (_currentStage == ForgotPasswordStage.email) {
        await _sendOtp();
      } else if (_currentStage == ForgotPasswordStage.otp) {
        await _verifyOtp();
      } else {
        await _resetPassword();
      }
    } catch (e) {
      if (mounted) _showToast(e.toString().replaceAll("Exception: ", ""), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    final url = Uri.parse('http://10.186.66.138:8080/api/auth/send');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'purpose': 'FORGOT_PASSWORD'}),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      if (mounted) {
        _showToast(data['message'] ?? "OTP sent to $email");
        setState(() {
          _currentStage = ForgotPasswordStage.otp;
          _startResendTimer();
        });
      }
    } else {
      throw data['message'] ?? "Failed to send OTP";
    }
  }

  Future<void> _resendOtp() async {
     setState(() => _isSubmitting = true);
     try {
       await _sendOtp();
     } catch(e) {
       _showToast(e.toString().replaceAll("Exception: ", ""), isError: true);
     } finally {
       setState(() => _isSubmitting = false);
     }
  }

  Future<void> _verifyOtp() async {
    final email = _emailCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    final url = Uri.parse('http://10.186.66.138:8080/api/auth/verify');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp, 'purpose': 'FORGOT_PASSWORD'}),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      if (mounted) {
        _showToast(data['message'] ?? "OTP Verified");
        setState(() {
          _currentStage = ForgotPasswordStage.reset;
        });
      }
    } else {
       throw data['message'] ?? "Invalid OTP";
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final url = Uri.parse('http://10.186.66.138:8080/api/auth/reset-password');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'newPassword': password}),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      if (mounted) {
        _showToast(data['message'] ?? "Password reset successfully!");
        Navigator.pop(context); // Go back to login
      }
    } else {
      throw data['message'] ?? "Failed to reset password";
    }
  }

  void _showToast(String message, {bool isError = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: isError ? theme.colorScheme.error : theme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: theme.colorScheme.onSurface),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _buildAnimatedBackground(size, theme),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.white.withValues(alpha: 0.4)),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Forgot Password",
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getStageDescription(),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 40),
                                
                                ..._buildFields(theme),

                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isSubmitting ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        backgroundColor: theme.primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        elevation: 5,
                                    ),
                                    child: _isSubmitting 
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : Text(_getButtonText(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStageDescription() {
    switch (_currentStage) {
      case ForgotPasswordStage.email: return "Enter your email to receive a reset code.";
      case ForgotPasswordStage.otp: return "Enter the 4-digit code sent to ${_emailCtrl.text}";
      case ForgotPasswordStage.reset: return "Create a new strong password.";
    }
  }

  String _getButtonText() {
    switch (_currentStage) {
      case ForgotPasswordStage.email: return "Send Code";
      case ForgotPasswordStage.otp: return "Verify Code";
      case ForgotPasswordStage.reset: return "Reset Password";
    }
  }

  List<Widget> _buildFields(ThemeData theme) {
    if (_currentStage == ForgotPasswordStage.email) {
      return [
        _buildGlassTextField(
          controller: _emailCtrl,
          focusNode: _emailFocus,
          label: "Email Address",
          icon: Icons.email_outlined,
          theme: theme,
          inputType: TextInputType.emailAddress,
          validator: (v) => v!.isEmpty || !v.contains('@') ? "Invalid email" : null,
        ),
      ];
    } else if (_currentStage == ForgotPasswordStage.otp) {
      return [
        _buildGlassTextField(
          controller: _otpCtrl,
          focusNode: _otpFocus,
          label: "OTP Code",
          icon: Icons.lock_clock_outlined,
          theme: theme,
          inputType: TextInputType.number,
          validator: (v) => v!.length < 4 ? "Invalid OTP" : null,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _resendSeconds == 0 ? _resendOtp : null,
          child: Text(
            _resendSeconds > 0
                ? "Resend in ${_resendSeconds ~/ 60}:${(_resendSeconds % 60).toString().padLeft(2, '0')}"
                : "Resend Code",
            style: TextStyle(
              color: _resendSeconds == 0 ? theme.primaryColor : theme.disabledColor,
            ),
          ),
        ),
      ];
    } else {
      return [
        _buildGlassTextField(
          controller: _passwordCtrl,
          focusNode: _passwordFocus,
          label: "New Password",
          icon: Icons.lock_outline,
          theme: theme,
          isPassword: true,
          isVisible: _passwordVisible,
          onVisibilityToggle: () => setState(() => _passwordVisible = !_passwordVisible),
          validator: (v) => v!.length < 6 ? "Minimum 6 chars" : null,
        ),
        const SizedBox(height: 16),
        _buildGlassTextField(
          controller: _confirmCtrl,
          focusNode: _confirmFocus,
          label: "Confirm Password",
          icon: Icons.lock_reset_outlined,
          theme: theme,
          isPassword: true,
          isVisible: _confirmVisible,
          onVisibilityToggle: () => setState(() => _confirmVisible = !_confirmVisible),
          validator: (v) => v != _passwordCtrl.text ? "Passwords do not match" : null,
        ),
      ];
    }
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    required ThemeData theme,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onVisibilityToggle,
    TextInputType inputType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
      final isDark = theme.brightness == Brightness.dark;
      return AnimatedBuilder(
          animation: focusNode,
          builder: (context, child) {
            final isActive = focusNode.hasFocus || controller.text.isNotEmpty;
            return Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive ? theme.primaryColor.withValues(alpha: 0.6) : theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                obscureText: isPassword && !isVisible,
                keyboardType: inputType,
                style: theme.textTheme.bodyLarge,
                cursorColor: theme.primaryColor,
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: TextStyle(
                    color: isActive ? theme.primaryColor : theme.hintColor,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                  prefixIcon: Icon(icon, color: isActive ? theme.primaryColor : theme.iconTheme.color?.withValues(alpha: 0.5)),
                  suffixIcon: isPassword
                      ? IconButton(
                          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: theme.hintColor),
                          onPressed: onVisibilityToggle,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                ),
                validator: validator,
              ),
            );
          }
      );
  }

  Widget _buildAnimatedBackground(Size size, ThemeData theme) {
      return AnimatedBuilder(
          animation: _backgroundAnimCtrl,
          builder: (context, child) {
              return Container(color: theme.scaffoldBackgroundColor); 
          }
      );
  }
}
