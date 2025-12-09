import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegistrationSuccessPage extends StatefulWidget {
  final Map<String, dynamic>? registrationData;

  const RegistrationSuccessPage({
    super.key,
    this.registrationData,
  });

  @override
  State<RegistrationSuccessPage> createState() =>
      _RegistrationSuccessPageState();
}

class _RegistrationSuccessPageState extends State<RegistrationSuccessPage>
    with TickerProviderStateMixin {
  // --- Animation Controllers ---
  late AnimationController _pageEntryCtrl;
  late AnimationController _checkmarkCtrl;
  late AnimationController _confettiCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _contentCtrl;
  late AnimationController _backgroundCtrl;

  // --- UI State ---
  bool _showConfetti = false;
  bool _animationComplete = false;
  int _countdownSeconds = 5;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    // Page entry animation (slide down from top)
    _pageEntryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Checkmark draw animation
    _checkmarkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Confetti burst animation
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Pulse animation for icon
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Content stagger animation
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Background animation
    _backgroundCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  void _startAnimationSequence() async {
    // Step 1: Page slides down from top (300ms)
    await _pageEntryCtrl.forward();
    HapticFeedback.mediumImpact();

    // Step 2: Checkmark animates (500ms) - starts at 400ms
    await Future.delayed(const Duration(milliseconds: 200));
    _checkmarkCtrl.forward();

    // Step 3: Confetti bursts (200ms) - starts at 900ms
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() => _showConfetti = true);
    _confettiCtrl.forward();
    HapticFeedback.heavyImpact();

    // Step 4: Content fades and slides in (300ms+)
    await Future.delayed(const Duration(milliseconds: 200));
    _contentCtrl.forward();

    // Mark animation complete
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _animationComplete = true);

    // Start countdown timer
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        setState(() => _countdownSeconds--);
      } else {
        _countdownTimer?.cancel();
        // Auto-navigate after countdown
        _navigateToDashboard();
      }
    });
  }

  void _navigateToDashboard() {
    // TODO: ensure /dashboard route exists later
    Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pageEntryCtrl.dispose();
    _checkmarkCtrl.dispose();
    _confettiCtrl.dispose();
    _pulseCtrl.dispose();
    _contentCtrl.dispose();
    _backgroundCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Animated background
          _buildAnimatedBackground(size, theme),

          // Main content - Slide down from top
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _pageEntryCtrl,
                curve: Curves.elasticOut,
              ),
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: _pageEntryCtrl,
                  curve: Curves.easeOut,
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: math.min(size.width * 0.95, 500),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Success Icon with animations
                        _buildSuccessIcon(theme),

                        const SizedBox(height: 40),

                        // Content section with stagger animations
                        _buildContent(theme),

                        const SizedBox(height: 48),

                        // Action buttons
                        _buildActionButtons(theme),

                        const SizedBox(height: 24),

                        // Countdown timer
                        _buildCountdownTimer(theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Confetti particles
          if (_showConfetti) _buildConfetti(size, theme),
        ],
      ),
    );
  }

  Widget _buildSuccessIcon(ThemeData theme) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _pageEntryCtrl,
          curve: const Interval(0.2, 0.6, curve: Curves.elasticOut),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing ring background
          ScaleTransition(
            scale: Tween<double>(begin: 1, end: 1.2).animate(
              CurvedAnimation(
                parent: _pulseCtrl,
                curve: Curves.easeInOut,
              ),
            ),
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor.withValues(alpha: 0.1),
              ),
            ),
          ),

          // Middle ring
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.primaryColor.withValues(alpha: 0.15),
            ),
          ),

          // Main icon container with gradient
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow effect
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withValues(alpha: 0.5),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                ),

                // Animated checkmark
                CustomPaint(
                  size: const Size(140, 140),
                  painter: CheckmarkPainter(
                    progress: _checkmarkCtrl.value,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Optional: Ripple effect rings
          ..._buildRippleRings(theme),
        ],
      ),
    );
  }

  List<Widget> _buildRippleRings(ThemeData theme) {
    return List.generate(2, (index) {
      final delay = index * 200;
      return Positioned(
        child: FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0).animate(
            CurvedAnimation(
              parent: _confettiCtrl,
              curve: Interval(
                (delay / 500).clamp(0.0, 1.0),
                ((delay + 400) / 500).clamp(0.0, 1.0),
                curve: Curves.easeOut,
              ),
            ),
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 2).animate(
              CurvedAnimation(
                parent: _confettiCtrl,
                curve: Interval(
                  (delay / 500).clamp(0.0, 1.0),
                  ((delay + 400) / 500).clamp(0.0, 1.0),
                  curve: Curves.easeOut,
                ),
              ),
            ),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.primaryColor
                      .withValues(alpha: 0.6 * (1 - index * 0.3)),
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildContent(ThemeData theme) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _contentCtrl,
          curve: const Interval(0.2, 1, curve: Curves.easeOutCubic),
        ),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _contentCtrl,
            curve: const Interval(0, 0.5, curve: Curves.easeOut),
          ),
        ),
        child: Column(
          children: [
            // Title
            Text(
              'Registration Successful!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: theme.colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              'Your account has been created. You are now\nready to start your journey into the world of\nautomation.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.6,
              ),
            ),

            const SizedBox(height: 24),

            // Success badge
            _buildSuccessBadge(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessBadge(ThemeData theme) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _contentCtrl,
          curve: const Interval(0.4, 1, curve: Curves.elasticOut),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_outlined,
              color: theme.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Email verified',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.4),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _contentCtrl,
          curve: const Interval(0.4, 1, curve: Curves.easeOutCubic),
        ),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _contentCtrl,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
          ),
        ),
        child: Column(
          children: [
            // Primary CTA button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _navigateToDashboard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: theme.primaryColor.withValues(alpha: 0.4),
                ),
                child: Text(
                  'Explore Courses',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Secondary action
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showToast('View profile (feature coming soon)');
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(
                    color: theme.primaryColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  'View Your Profile',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownTimer(ThemeData theme) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _contentCtrl,
          curve: const Interval(0.6, 1, curve: Curves.easeOut),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Redirecting in $_countdownSeconds seconds...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 4,
            width: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: _countdownSeconds / 5,
                backgroundColor:
                    theme.colorScheme.outline.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(
                  theme.primaryColor.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _navigateToDashboard,
            child: Text(
              'Skip',
              style: TextStyle(
                color: theme.primaryColor.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfetti(Size size, ThemeData theme) {
    return Positioned.fill(
      child: CustomPaint(
        painter: ConfettiPainter(
          progress: _confettiCtrl.value,
          theme: theme,
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground(Size size, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    final color1 = isDark
        ? const Color(0xFF7C3AED).withValues(alpha: 0.2)
        : const Color(0xFF4F46E5).withValues(alpha: 0.15);

    final color2 = isDark
        ? const Color(0xFF2D1B69).withValues(alpha: 0.3)
        : const Color(0xFFA5B4FC).withValues(alpha: 0.15);

    final color3 = isDark
        ? const Color(0xFF4C1D95).withValues(alpha: 0.2)
        : const Color(0xFFC4B5FD).withValues(alpha: 0.1);

    return AnimatedBuilder(
      animation: _backgroundCtrl,
      builder: (context, child) {
        return CustomPaint(
          size: size,
          painter: SuccessBackgroundPainter(
            animationValue: _backgroundCtrl.value,
            color1: color1,
            color2: color2,
            color3: color3,
          ),
        );
      },
    );
  }

  void _showToast(String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: theme.primaryColor.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Custom Checkmark Painter
class CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  CheckmarkPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    const radius = 45.0;

    // Draw checkmark path
    final path = Path();

    // Vertical part of checkmark
    const verticalStart = Offset(0.35, 0.55);
    const verticalEnd = Offset(0.50, 0.70);

    // Horizontal part of checkmark
    const horizontalEnd = Offset(0.80, 0.30);

    if (progress <= 0.5) {
      // Animate vertical line
      final t = progress / 0.5;
      path.moveTo(
        centerX + verticalStart.dx * radius * 2,
        centerY + verticalStart.dy * radius * 2,
      );
      path.lineTo(
        centerX +
            verticalStart.dx * radius * 2 +
            (verticalEnd.dx - verticalStart.dx) * radius * 2 * t,
        centerY +
            verticalStart.dy * radius * 2 +
            (verticalEnd.dy - verticalStart.dy) * radius * 2 * t,
      );
    } else {
      // Complete vertical line and animate horizontal line
      final t = (progress - 0.5) / 0.5;
      path.moveTo(
        centerX + verticalStart.dx * radius * 2,
        centerY + verticalStart.dy * radius * 2,
      );
      path.lineTo(
        centerX + verticalEnd.dx * radius * 2,
        centerY + verticalEnd.dy * radius * 2,
      );
      path.lineTo(
        centerX +
            verticalEnd.dx * radius * 2 +
            (horizontalEnd.dx - verticalEnd.dx) * radius * 2 * t,
        centerY +
            verticalEnd.dy * radius * 2 +
            (horizontalEnd.dy - verticalEnd.dy) * radius * 2 * t,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Confetti Particle Painter
class ConfettiPainter extends CustomPainter {
  final double progress;
  final ThemeData theme;

  ConfettiPainter({
    required this.progress,
    required this.theme,
  });

  late final List<ConfettiParticle> particles = _generateParticles();

  List<ConfettiParticle> _generateParticles() {
    final random = math.Random(42);
    final particles = <ConfettiParticle>[];

    for (int i = 0; i < 50; i++) {
      particles.add(
        ConfettiParticle(
          x: 0.5,
          y: 0.5,
          vx: (random.nextDouble() - 0.5) * 2,
          vy: -random.nextDouble() * 1.5,
          rotation: random.nextDouble() * 360,
          vRotation: (random.nextDouble() - 0.5) * 10,
          size: random.nextDouble() * 8 + 4,
          color: _getConfettiColor(i, random),
        ),
      );
    }

    return particles;
  }

  Color _getConfettiColor(int index, math.Random random) {
    final colors = [
      theme.primaryColor,
      theme.primaryColor.withValues(alpha: 0.8),
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
    ];
    return colors[index % colors.length];
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Update particle position based on progress (0 to 1)
      final x =
          particle.x * size.width + particle.vx * size.width * progress * 0.8;
      final y =
          particle.y * size.height + particle.vy * size.height * progress * 0.8;

      // Apply gravity
      final gravityY = y + (size.height * 0.4 * progress * progress);

      // Fade out as it falls
      final opacity = (1 - progress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity * 0.9)
        ..style = PaintingStyle.fill;

      // Draw particle
      canvas.save();
      canvas.translate(x, gravityY);
      canvas.rotate(
        (particle.rotation + particle.vRotation * progress * 360) *
            math.pi /
            180,
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Confetti Particle Model
class ConfettiParticle {
  final double x;
  final double y;
  final double vx;
  final double vy;
  final double rotation;
  final double vRotation;
  final double size;
  final Color color;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.vRotation,
    required this.size,
    required this.color,
  });
}

/// Success Background Painter
class SuccessBackgroundPainter extends CustomPainter {
  final double animationValue;
  final Color color1;
  final Color color2;
  final Color color3;

  SuccessBackgroundPainter({
    required this.animationValue,
    required this.color1,
    required this.color2,
    required this.color3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    // Orb 1 - Top left
    final offset1 = Offset(size.width * 0.15, size.height * 0.15);
    final move1 = Offset(
      math.sin(animationValue * 2 * math.pi) * 40,
      math.cos(animationValue * 2 * math.pi) * 40,
    );
    paint.color = color1;
    canvas.drawCircle(offset1 + move1, size.width * 0.4, paint);

    // Orb 2 - Bottom right
    final offset2 = Offset(size.width * 0.85, size.height * 0.75);
    final move2 = Offset(
      math.cos(animationValue * 2 * math.pi) * 50,
      math.sin(animationValue * 2 * math.pi) * 50,
    );
    paint.color = color2;
    canvas.drawCircle(offset2 + move2, size.width * 0.45, paint);

    // Orb 3 - Center
    final offset3 = Offset(size.width * 0.5, size.height * 0.5);
    final move3 = Offset(
      math.sin(animationValue * 2 * math.pi) * -30,
      math.cos(animationValue * 2 * math.pi) * -30,
    );
    paint.color = color3;
    canvas.drawCircle(offset3 + move3, size.width * 0.35, paint);
  }

  @override
  bool shouldRepaint(SuccessBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
