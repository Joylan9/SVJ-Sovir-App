import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Import global theme notifier and color scheme from main.dart
import '../main.dart';

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage>
    with TickerProviderStateMixin {
  // --- Form Controllers ---
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();

  // --- Focus Nodes ---
  final FocusNode _fullNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // --- Animation Controllers ---
  late AnimationController _entryAnimCtrl;
  late AnimationController _backgroundAnimCtrl;
  late AnimationController _profileImageAnimCtrl;
  late AnimationController _pulseAnimCtrl;

  // --- UI State ---
  bool _isEditMode = false;
  bool _isSubmitting = false;
  String _profileImagePath = '';
  bool _hasUnsavedChanges = false;
  int _selectedInterests = 0;
  double _scrollParallax = 0.0;
  Timer? _debounce;

  // Learning interests data
  final List<LearningInterest> _learningInterests = [
    LearningInterest(
        label: 'PLC Programming', icon: Icons.settings_input_svideo),
    LearningInterest(label: 'SCADA Systems', icon: Icons.dashboard),
    LearningInterest(label: 'HMI Design', icon: Icons.design_services),
    LearningInterest(label: 'Industrial Networks', icon: Icons.cloud_queue),
    LearningInterest(label: 'Robotics', icon: Icons.precision_manufacturing),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Initialize animations
    _entryAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _backgroundAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _profileImageAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Pre-fill with example data
    _fullNameCtrl.text = 'John Doe';
    _emailCtrl.text = 'joylan@gmail.com';

    _fullNameCtrl.addListener(_markUnsavedChanges);
    _emailCtrl.addListener(_markUnsavedChanges);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _entryAnimCtrl.dispose();
    _backgroundAnimCtrl.dispose();
    _profileImageAnimCtrl.dispose();
    _pulseAnimCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() => _scrollParallax = _scrollController.offset);
  }

  void _markUnsavedChanges() {
    setState(() => _hasUnsavedChanges = true);
  }

  // --- Validation Helpers ---
  static bool isValidEmail(String v) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v);

  // --- Profile Image Upload ---
  void _pickProfileImage() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.3), // was .withOpacity(0.3)
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _showToast('Camera functionality (to be implemented)');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _profileImagePath = 'assets/placeholder_profile.png';
                  _hasUnsavedChanges = true;
                });
                _profileImageAnimCtrl.forward(from: 0);
                _showToast('Profile picture updated');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Remove Photo',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _profileImagePath = '';
                  _hasUnsavedChanges = true;
                });
                _showToast('Profile picture removed');
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Form Submission ---
  Future<void> _saveProfile() async {
    HapticFeedback.mediumImpact();
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.vibrate();
      _showToast('Please fill all required fields', isError: true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _isEditMode = false;
          _hasUnsavedChanges = false;
        });
        _showToast('Profile saved successfully!');
        HapticFeedback.heavyImpact();

        // ✅ Navigate to registration_success.dart
        Navigator.of(context).pushReplacementNamed('/registration-success');
      }
    } catch (err) {
      if (mounted) _showToast('Error saving profile', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _toggleInterest(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _learningInterests[index].isSelected =
          !_learningInterests[index].isSelected;
      _selectedInterests = _learningInterests.where((i) => i.isSelected).length;
      _markUnsavedChanges();
    });
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
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? theme.colorScheme.error : theme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --- UI Builders ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDark = theme.brightness == Brightness.dark;
    final contentWidth = math.min(size.width * 0.92, 700.0);

    if (_hasUnsavedChanges && _isEditMode) {
      return WillPopScope(
        onWillPop: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Discard Changes?'),
              content: const Text(
                  'You have unsaved changes. Do you want to discard them?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Keep Editing'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Discard'),
                ),
              ],
            ),
          );
          return confirmed ?? false;
        },
        child: _buildScaffold(theme, size, isDark, contentWidth),
      );
    }

    return _buildScaffold(theme, size, isDark, contentWidth);
  }

  Widget _buildScaffold(
      ThemeData theme, Size size, bool isDark, double contentWidth) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Animated background
          _buildAnimatedBackground(size, theme),

          // Main content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: Column(
                  children: [
                    // Header
                    _buildHeader(theme),

                    // Content
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.white.withValues(alpha: 0.4),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.2 : 0.05,
                                  ),
                                  blurRadius: 20,
                                )
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: ListView(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 32,
                                ),
                                physics: const BouncingScrollPhysics(),
                                children: _buildFormContent(theme),
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

          // Loading overlay
          if (_isSubmitting) _buildLoadingOverlay(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 10),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Create Your Profile',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 420,
                  child: Text(
                    'This will help us personalize your learning experience.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  List<Widget> _buildFormContent(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final subTextColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    final children = <Widget>[
      // Profile Picture Section
      FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _entryAnimCtrl,
            curve: const Interval(0, 0.3, curve: Curves.easeOut),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _isEditMode ? _pickProfileImage : null,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1).animate(
                  CurvedAnimation(
                    parent: _entryAnimCtrl,
                    curve: const Interval(0, 0.4, curve: Curves.elasticOut),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulse ring animation
                    if (_isEditMode)
                      ScaleTransition(
                        scale: Tween<double>(begin: 1, end: 1.15).animate(
                          CurvedAnimation(
                            parent: _pulseAnimCtrl,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                              width: 2,
                            ),
                          ),
                        ),
                      ),

                    // Profile circle
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor,
                            theme.primaryColor.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: _profileImagePath.isEmpty
                          ? const Icon(
                              Icons.camera_alt,
                              size: 50,
                              color: Colors.white,
                            )
                          : null,
                    ),

                    // Edit overlay
                    if (_isEditMode)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.primaryColor,
                            boxShadow: [
                              BoxShadow(
                                color: theme.primaryColor.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Upload Profile Picture (Optional)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: subTextColor,
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 32),

      // Full Name Field
      _buildFormField(
        label: 'Full Name',
        controller: _fullNameCtrl,
        focusNode: _fullNameFocus,
        icon: Icons.person,
        theme: theme,
        isReadOnly: !_isEditMode,
        validator: (v) {
          final val = (v ?? '').trim();
          if (val.isEmpty) return 'Please enter your name';
          if (val.length < 2) return 'Name must be at least 2 characters';
          return null;
        },
      ),

      const SizedBox(height: 20),

      // Email Field
      _buildFormField(
        label: 'Email Address',
        controller: _emailCtrl,
        focusNode: _emailFocus,
        icon: Icons.email,
        theme: theme,
        isReadOnly: !_isEditMode,
        validator: (v) {
          final val = (v ?? '').trim();
          if (val.isEmpty) return 'Please enter your email';
          if (!isValidEmail(val)) return 'Please enter a valid email';
          return null;
        },
      ),

      const SizedBox(height: 32),

      // Learning Interests Section
      Text(
        'Learning Interests (Optional)',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),

      // Interest tags grid
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: List.generate(
          _learningInterests.length,
          (index) {
            final interest = _learningInterests[index];
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: FilterChip(
                label: Text(interest.label),
                selected: interest.isSelected,
                onSelected: _isEditMode ? (_) => _toggleInterest(index) : null,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.1),
                selectedColor: theme.primaryColor.withValues(alpha: 0.3),
                side: BorderSide(
                  color: interest.isSelected
                      ? theme.primaryColor
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
                  width: interest.isSelected ? 2 : 1,
                ),
                labelStyle: TextStyle(
                  color: interest.isSelected
                      ? theme.primaryColor
                      : theme.colorScheme.onSurface,
                  fontWeight:
                      interest.isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          },
        ),
      ),

      const SizedBox(height: 40),

      // Action Buttons
      if (!_isEditMode)
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => setState(() => _isEditMode = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
            ),
            child: Text(
              'Edit Profile',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        )
      else
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 54,
                child: OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          setState(() {
                            _isEditMode = false;
                            _hasUnsavedChanges = false;
                          });
                        },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Save and Continue',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),

      const SizedBox(height: 16),

      // Skip Button
      if (!_isEditMode)
        Center(
          child: TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              // ✅ Navigate directly to registration_success.dart
              Navigator.of(context)
                  .pushReplacementNamed('/registration-success');
            },
            child: Text(
              'Skip for now',
              style: TextStyle(
                color: subTextColor,
                fontSize: 14,
              ),
            ),
          ),
        ),
    ];

    // Apply staggered animations
    return children.asMap().entries.map((entry) {
      final index = entry.key;
      final widget = entry.value;

      final start = (index * 0.04).clamp(0.0, 1.0);
      final end = (start + 0.35).clamp(0.0, 1.0);

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

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required ThemeData theme,
    required String? Function(String?)? validator,
    bool isReadOnly = false,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        final isActive = focusNode.hasFocus || controller.text.isNotEmpty;
        final baseFill = isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.grey.withValues(alpha: 0.1);
        final activeFill = isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.grey.withValues(alpha: 0.05);

        return Container(
          decoration: BoxDecoration(
            color: isReadOnly
                ? isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.grey.withValues(alpha: 0.05)
                : isActive
                    ? activeFill
                    : baseFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? theme.primaryColor.withValues(alpha: 0.6)
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            readOnly: isReadOnly,
            style: theme.textTheme.bodyLarge,
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
                    : theme.iconTheme.color?.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              filled: false,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              errorStyle: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 12,
              ),
            ),
            validator: validator,
          ),
        );
      },
    );
  }

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
                color: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: theme.primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Saving Profile...',
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
}

/// Learning Interest Model
class LearningInterest {
  final String label;
  final IconData icon;
  bool isSelected;

  LearningInterest({
    required this.label,
    required this.icon,
    this.isSelected = false,
  });
}

/// Custom Mesh Gradient Painter
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
        oldDelegate.color1 != color1;
  }
}
