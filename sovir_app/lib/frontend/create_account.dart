import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Import the global theme notifier to allow toggling
import '../main.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage>
    with TickerProviderStateMixin {
  // --- Logic & State ---
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _entryAnimCtrl;
  late AnimationController _backgroundAnimCtrl;

  bool _agreeTerms = false;
  bool _isSubmitting = false;
  bool _passwordVisible = false;
  bool _confirmVisible = false;
  double _scrollParallax = 0.0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_onEmailChanged);
    _scrollController.addListener(_onScroll);

    _entryAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _backgroundAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _emailCtrl.removeListener(_onEmailChanged);
    _scrollController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _entryAnimCtrl.dispose();
    _backgroundAnimCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollParallax = _scrollController.offset;
    });
  }

  // --- Validation Helpers ---
  static bool isValidEmail(String v) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v);
  static bool hasMinLength(String v) => v.length >= 8;
  static bool hasUppercase(String v) => v.contains(RegExp(r'[A-Z]'));
  static bool hasNumber(String v) => v.contains(RegExp(r'\d'));
  static bool hasSpecialChar(String v) =>
      v.contains(RegExp(r'[!@#\\$%^&*(),.?":{}|<>]'));

  int passwordStrengthCount(String password) {
    return [
      hasMinLength(password),
      hasUppercase(password),
      hasNumber(password),
      hasSpecialChar(password)
    ].where((e) => e).length;
  }

  void _onEmailChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() {});
    });
  }

  bool get _isFormValid {
    final email = _emailCtrl.text.trim();
    final pw = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;
    final emailOk = email.isNotEmpty && isValidEmail(email);
    // Ideally require score == 4, but let's be lenient for demo
    final pwOk = passwordStrengthCount(pw) >= 3;
    final confirmOk = confirm.isNotEmpty && confirm == pw;
    return emailOk && pwOk && confirmOk && _agreeTerms;
  }

  Future<void> _submit() async {
    HapticFeedback.mediumImpact();
    if (!_formKey.currentState!.validate() || !_isFormValid) {
      HapticFeedback.vibrate();
      _showToast("Please check your inputs", isError: true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      // Simulate Network Call
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        _showToast("Account created successfully!");

        // ✅ Redirect to profile page
        Navigator.pushReplacementNamed(context, '/profile');
      }
    } catch (err) {
      if (mounted) _showToast("An error occurred", isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: isError ? theme.colorScheme.error : theme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  // --- UI Builders ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDark = theme.brightness == Brightness.dark;

    // Constraint width for larger screens (tablets/web) - improved responsiveness
    final double contentWidth = math.min(size.width * 0.92, 700);
    final double headerTextWidth = math.min(contentWidth * 0.9, 420);
    // Taller, but still adaptive to small screens
    final double containerMinHeight = math.min(size.height * 0.72, 920);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Dynamic Mesh Background
          _buildAnimatedBackground(size, theme),

          // 2. Glass Overlay & Content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: Column(
                  children: [
                    _buildHeader(theme, headerTextWidth),
                    // Make container slightly taller on most screens while keeping it responsive
                    Flexible(
                      fit: FlexFit.loose,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: containerMinHeight),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(
                                        alpha: 0.05) // was .withOpacity(0.05)
                                    : Colors.white.withValues(
                                        alpha: 0.6), // was .withOpacity(0.6)
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(
                                          alpha: 0.1, // was .withOpacity(0.1)
                                        )
                                      : Colors.white.withValues(
                                          alpha: 0.4, // was .withOpacity(0.4)
                                        ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.2 : 0.05,
                                    ), // was .withOpacity(...)
                                    blurRadius: 20,
                                    spreadRadius: 0,
                                  )
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: ListView(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 40),
                                  physics: const BouncingScrollPhysics(),
                                  children: _buildFormChildren(theme),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Loading Overlay
          if (_isSubmitting) _buildLoadingOverlay(theme),
        ],
      ),
    );
  }

  List<Widget> _buildFormChildren(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final subTextColor = theme.colorScheme.onSurface
        .withValues(alpha: 0.6); // was .withOpacity(0.6)

    final children = [
      const SizedBox(height: 8),

      _buildGlassTextField(
        controller: _emailCtrl,
        focusNode: _emailFocus,
        label: "Email Address",
        icon: Icons.email_outlined,
        theme: theme,
        inputType: TextInputType.emailAddress,
        validator: (v) => !isValidEmail(v ?? '') && (v ?? '').isNotEmpty
            ? 'Invalid email'
            : null,
      ),
      const SizedBox(height: 20),

      _buildGlassTextField(
        controller: _passwordCtrl,
        focusNode: _passwordFocus,
        label: "Password",
        icon: Icons.lock_outline,
        theme: theme,
        isPassword: true,
        isVisible: _passwordVisible,
        onVisibilityToggle: () =>
            setState(() => _passwordVisible = !_passwordVisible),
        onChanged: (_) => setState(() {}),
      ),

      // Strength + requirement checklist
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        child: _passwordCtrl.text.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStrengthIndicator(theme),
                    const SizedBox(height: 12),
                    _buildPasswordRequirements(theme),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),

      const SizedBox(height: 20),

      _buildGlassTextField(
        controller: _confirmCtrl,
        focusNode: _confirmFocus,
        label: "Confirm Password",
        icon: Icons.lock_reset_outlined,
        theme: theme,
        isPassword: true,
        isVisible: _confirmVisible,
        onVisibilityToggle: () =>
            setState(() => _confirmVisible = !_confirmVisible),
        validator: (v) =>
            v != _passwordCtrl.text ? 'Passwords do not match' : null,
      ),

      const SizedBox(height: 24),

      // Custom Checkbox Row
      GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _agreeTerms = !_agreeTerms);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _agreeTerms ? theme.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _agreeTerms
                      ? theme.primaryColor
                      : theme.colorScheme.outline.withValues(
                          alpha: 0.5,
                        ), // was .withOpacity(0.5)
                  width: 2,
                ),
              ),
              child: _agreeTerms
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: subTextColor),
                  children: [
                    const TextSpan(text: "I agree to the "),
                    TextSpan(
                      text: "Terms of Service",
                      style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: " and "),
                    TextSpan(
                      text: "Privacy Policy",
                      style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 32),

      // Submit Button
      _buildPremiumButton(theme),

      const SizedBox(height: 32),

      Row(
        children: [
          Expanded(child: Divider(color: theme.dividerColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child:
                Text("Or sign up with", style: TextStyle(color: subTextColor)),
          ),
          Expanded(child: Divider(color: theme.dividerColor)),
        ],
      ),

      const SizedBox(height: 24),

      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSocialButton(Icons.g_mobiledata, Colors.redAccent, theme),
          const SizedBox(width: 20),
          _buildSocialButton(
              Icons.apple, isDark ? Colors.white : Colors.black, theme),
          const SizedBox(width: 20),
          _buildSocialButton(Icons.facebook, const Color(0xFF1877F2), theme),
        ],
      ),

      const SizedBox(height: 40),

      Center(
        child: TextButton(
          onPressed: () {},
          child: RichText(
            text: TextSpan(
              text: "Already have an account? ",
              style: TextStyle(color: subTextColor),
              children: [
                TextSpan(
                  text: "Log In",
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];

    // Apply Staggered Animation
    return children.asMap().entries.map((entry) {
      final index = entry.key;
      final widget = entry.value;

      final start = (index * 0.05).clamp(0.0, 1.0);
      final end = (start + 0.4).clamp(0.0, 1.0);

      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _entryAnimCtrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        )),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
            parent: _entryAnimCtrl,
            curve: Interval(start, end, curve: Curves.easeOut),
          )),
          child: widget,
        ),
      );
    }).toList();
  }

  // --- Widget Components ---

  Widget _buildHeader(ThemeData theme, double textWidth) {
    // No back button, centered header like the reference design
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 10),
      child: Stack(
        children: [
          // Centered large title + subtitle
          Align(
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Get Started",
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: textWidth,
                  child: Text(
                    "Unlock access to our full library of automation courses.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.7), // was .withOpacity(0.7)
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Theme Toggle - top-right
          Align(
            alignment: Alignment.topRight,
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, mode, _) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return IconButton(
                  onPressed: () {
                    themeNotifier.value =
                        isDark ? ThemeMode.light : ThemeMode.dark;
                  },
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      isDark ? Icons.light_mode : Icons.dark_mode,
                      key: ValueKey(isDark),
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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
    Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        final isActive = focusNode.hasFocus || controller.text.isNotEmpty;
        final baseFill = isDark
            ? Colors.white.withValues(alpha: 0.08) // was .withOpacity(0.08)
            : Colors.grey.withValues(alpha: 0.1); // was .withOpacity(0.1)
        final activeFill = isDark
            ? Colors.white.withValues(alpha: 0.12) // was .withOpacity(0.12)
            : Colors.grey.withValues(alpha: 0.05); // was .withOpacity(0.05)

        return Container(
          decoration: BoxDecoration(
            color: isActive ? activeFill : baseFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? theme.primaryColor.withValues(
                      alpha: 0.6,
                    ) // was .withOpacity(0.6)
                  : theme.colorScheme.outline.withValues(
                      alpha: 0.2,
                    ), // was .withOpacity(0.2)
              width: 1.5,
            ),
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: isPassword && !isVisible,
            keyboardType: inputType,
            style: theme.textTheme.bodyLarge,
            onChanged: onChanged,
            cursorColor: theme.primaryColor,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: isActive ? theme.primaryColor : theme.hintColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
              prefixIcon: Icon(
                icon,
                color: isActive
                    ? theme.primaryColor
                    : theme.iconTheme.color?.withValues(
                        alpha: 0.5,
                      ), // was .withOpacity(0.5)
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isVisible ? Icons.visibility : Icons.visibility_off,
                        color: theme.hintColor,
                      ),
                      onPressed: onVisibilityToggle,
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              errorStyle:
                  TextStyle(color: theme.colorScheme.error, fontSize: 12),
            ),
            validator: validator,
          ),
        );
      },
    );
  }

  Widget _buildStrengthIndicator(ThemeData theme) {
    final pw = _passwordCtrl.text;
    final score = passwordStrengthCount(pw);

    Color barColor;
    String label;
    if (score <= 1) {
      barColor = theme.colorScheme.error;
      label = "Weak";
    } else if (score <= 3) {
      barColor = Colors.orange;
      label = "Medium";
    } else {
      barColor = Colors.greenAccent;
      label = "Strong";
    }

    if (theme.brightness == Brightness.light && score > 3) {
      barColor = Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Password Strength",
              style:
                  theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: barColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.disabledColor.withValues(
                  alpha: 0.2,
                ), // was .withOpacity(0.2)
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 300),
              widthFactor: (score / 4).clamp(0.05, 1.0),
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: barColor.withValues(
                        alpha: 0.4,
                      ), // was .withOpacity(0.4)
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements(ThemeData theme) {
    final pw = _passwordCtrl.text;
    final minLen = hasMinLength(pw);
    final hasUpper = hasUppercase(pw);
    final hasNum = hasNumber(pw);
    final hasSpec = hasSpecialChar(pw);

    Widget row(bool ok, String label) => Row(
          children: [
            Icon(
              ok ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18,
              color: ok
                  ? theme.primaryColor
                  : theme.hintColor.withValues(
                      alpha: 0.6,
                    ), // was .withOpacity(0.6)
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor.withValues(
                    alpha: 0.9,
                  ), // was .withOpacity(0.9)
                ),
              ),
            ),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row(minLen, 'At least 8 characters'),
        const SizedBox(height: 6),
        row(hasUpper, 'Contains an uppercase letter (A-Z)'),
        const SizedBox(height: 6),
        row(hasNum, 'Contains a number (0-9)'),
        const SizedBox(height: 6),
        row(hasSpec, 'Contains a special character (!@#...)'),
      ],
    );
  }

  Widget _buildPremiumButton(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: _isFormValid
              ? [
                  theme.primaryColor,
                  theme.primaryColor.withValues(alpha: 0.8),
                ] // was .withOpacity(0.8)
              : [
                  theme.disabledColor,
                  theme.disabledColor.withValues(alpha: 0.8),
                ],
        ),
        boxShadow: _isFormValid
            ? [
                BoxShadow(
                  color: theme.primaryColor.withValues(
                    alpha: 0.4,
                  ), // was .withOpacity(0.4)
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isFormValid && !_isSubmitting ? _submit : null,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(
            alpha: 0.2,
          ), // was .withOpacity(0.2)
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      "Create Account",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, Color brandColor, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.dividerColor,
        ),
      ),
      child: InkWell(
        onTap: () => HapticFeedback.selectionClick(),
        customBorder: const CircleBorder(),
        child: Icon(icon, color: brandColor),
      ),
    );
  }

  Widget _buildLoadingOverlay(ThemeData theme) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor.withValues(
                  alpha: 0.8,
                ), // was .withOpacity(0.8)
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: theme.primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    "Creating Account...",
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Background Painter ---
  Widget _buildAnimatedBackground(Size size, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    final color1 = isDark
        ? const Color(0xFF6C63FF).withValues(alpha: 0.4)
        : const Color(0xFF4F46E5).withValues(alpha: 0.3);

    final color2 = isDark
        ? const Color(0xFF2A2D3E).withValues(alpha: 0.6)
        : const Color(0xFFA5B4FC).withValues(alpha: 0.3);

    final color3 = isDark
        ? const Color(0xFF00C896).withValues(alpha: 0.3)
        : const Color(0xFFF472B6).withValues(alpha: 0.3);

    return AnimatedBuilder(
      animation: _backgroundAnimCtrl,
      builder: (context, child) {
        return CustomPaint(
          size: size,
          painter: MeshGradientPainter(
            animationValue: _backgroundAnimCtrl.value,
            scrollOffset: _scrollParallax,
            color1: color1,
            color2: color2,
            color3: color3,
          ),
        );
      },
    );
  }
}

/// Custom Mesh Gradient Painter that accepts Theme colors
class MeshGradientPainter extends CustomPainter {
  final double animationValue;
  final double scrollOffset;
  final Color color1;
  final Color color2;
  final Color color3;

  MeshGradientPainter({
    required this.animationValue,
    required this.scrollOffset,
    required this.color1,
    required this.color2,
    required this.color3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    // Parallax factor
    final dy = -scrollOffset * 0.2;

    // Orb 1
    final offset1 = Offset(size.width * 0.2, size.height * 0.2 + dy);
    final move1 = Offset(
      math.sin(animationValue * 2 * math.pi) * 30,
      math.cos(animationValue * 2 * math.pi) * 30,
    );
    paint.color = color1;
    canvas.drawCircle(offset1 + move1, size.width * 0.6, paint);

    // Orb 2
    final offset2 = Offset(size.width * 0.8, size.height * 0.6 + dy);
    final move2 = Offset(
      math.cos(animationValue * 2 * math.pi) * 40,
      math.sin(animationValue * 2 * math.pi) * 40,
    );
    paint.color = color2;
    canvas.drawCircle(offset2 + move2, size.width * 0.7, paint);

    // Orb 3
    final offset3 = Offset(size.width * 0.5, size.height * 0.9 + dy);
    final move3 = Offset(math.sin(animationValue * 2 * math.pi) * -50, 0);
    paint.color = color3;
    canvas.drawCircle(offset3 + move3, size.width * 0.5, paint);
  }

  @override
  bool shouldRepaint(covariant MeshGradientPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.color1 != color1 ||
        oldDelegate.color2 != color2 ||
        oldDelegate.color3 != color3;
  }
}
