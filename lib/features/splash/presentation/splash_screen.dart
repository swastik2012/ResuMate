import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A premium animated splash screen for ResuMate.
/// Shows a branded loading experience while the app initializes.
class SplashScreen extends StatefulWidget {
  /// Callback that performs async initialization work.
  /// Returns true if user is already signed in, false otherwise.
  final Future<bool> Function() onInitialize;

  /// Called when initialization is complete.
  final void Function(bool isSignedIn) onComplete;

  const SplashScreen({
    super.key,
    required this.onInitialize,
    required this.onComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // --- Animation Controllers ---
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _progressController;
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;

  // --- Animations ---
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _progressOpacity;
  late final Animation<double> _pulseScale;

  bool _initComplete = false;
  bool _minTimeElapsed = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startInitialization();
  }

  void _setupAnimations() {
    // Logo: scale up + fade in over 800ms
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    // Pulse glow on the logo (looping)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Text animations: staggered fade + slide
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    // Progress bar
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progressOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeIn),
    );

    // Shimmer effect on title
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Kick off the animation sequence
    _logoController.forward().then((_) {
      _pulseController.repeat(reverse: true);
      _textController.forward();
      _shimmerController.repeat();
      Future.delayed(const Duration(milliseconds: 400), () {
        _progressController.forward();
      });
    });
  }

  void _startInitialization() async {
    // Run init and minimum display timer in parallel
    final results = await Future.wait([
      widget.onInitialize().then((v) {
        _initComplete = true;
        return v;
      }),
      Future.delayed(const Duration(milliseconds: 2200), () {
        _minTimeElapsed = true;
        return false;
      }),
    ]);

    final isSignedIn = results[0];

    // If both are done, proceed. Otherwise wait for the other.
    if (_initComplete && _minTimeElapsed) {
      _completeTransition(isSignedIn);
    } else {
      // Poll briefly until both conditions met
      while (!_initComplete || !_minTimeElapsed) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      _completeTransition(isSignedIn);
    }
  }

  void _completeTransition(bool isSignedIn) {
    if (!mounted) return;
    widget.onComplete(isSignedIn);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1040), // Deep indigo
              Color(0xFF0D1B3E), // Dark navy
              Color(0xFF162447), // Midnight blue
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // --- Animated Logo ---
                AnimatedBuilder(
                  animation: Listenable.merge([_logoController, _pulseController]),
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value * _pulseScale.value,
                        child: child,
                      ),
                    );
                  },
                  child: _buildLogoWidget(),
                ),

                const SizedBox(height: 32),

                // --- Animated Title "ResuMate" ---
                AnimatedBuilder(
                  animation: Listenable.merge([_textController, _shimmerController]),
                  builder: (context, _) {
                    return SlideTransition(
                      position: _titleSlide,
                      child: Opacity(
                        opacity: _titleOpacity.value,
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            final shimmerOffset =
                                _shimmerController.value * 3.0 - 1.0;
                            return LinearGradient(
                              begin: Alignment(shimmerOffset - 0.3, 0),
                              end: Alignment(shimmerOffset + 0.3, 0),
                              colors: const [
                                Colors.white,
                                Color(0xFFB8C6FF),
                                Colors.white,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcIn,
                          child: const Text(
                            'ResuMate',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // --- Animated Tagline ---
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return SlideTransition(
                      position: _taglineSlide,
                      child: Opacity(
                        opacity: _taglineOpacity.value,
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    'AI-Powered Resume Builder',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.8,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // --- Animated Progress Indicator ---
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _progressOpacity.value,
                      child: child,
                    );
                  },
                  child: const _GradientProgressBar(),
                ),

                const SizedBox(height: 16),

                // --- Loading Text ---
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _progressOpacity.value,
                      child: child,
                    );
                  },
                  child: Text(
                    'Getting things ready...',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoWidget() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C6BC0).withValues(alpha: 0.4),
            blurRadius: 40,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: const Color(0xFF3F51B5).withValues(alpha: 0.2),
            blurRadius: 80,
            spreadRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF5C6BC0), // Indigo 400
                Color(0xFF3F51B5), // Indigo 500
                Color(0xFF303F9F), // Indigo 700
              ],
            ),
          ),
          child: const Center(
            child: Text(
              'R',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A custom gradient progress bar that animates indefinitely.
class _GradientProgressBar extends StatefulWidget {
  const _GradientProgressBar();

  @override
  State<_GradientProgressBar> createState() => _GradientProgressBarState();
}

class _GradientProgressBarState extends State<_GradientProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 80),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: const Size(double.infinity, 3),
            painter: _GradientProgressPainter(
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _GradientProgressPainter extends CustomPainter {
  final double progress;

  _GradientProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Track background
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    final trackRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(2),
    );
    canvas.drawRRect(trackRRect, trackPaint);

    // Animated gradient indicator
    final indicatorWidth = size.width * 0.4;
    final startX = (size.width + indicatorWidth) * progress - indicatorWidth;
    final endX = startX + indicatorWidth;

    final gradient = LinearGradient(
      colors: [
        Colors.white.withValues(alpha: 0.0),
        const Color(0xFF7986CB),
        const Color(0xFF5C6BC0),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );

    final indicatorPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(startX, 0, indicatorWidth, size.height),
      )
      ..style = PaintingStyle.fill;

    final clampedLeft = math.max(0.0, startX);
    final clampedRight = math.min(size.width, endX);
    if (clampedRight > clampedLeft) {
      final indicatorRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(clampedLeft, 0, clampedRight - clampedLeft, size.height),
        const Radius.circular(2),
      );
      canvas.drawRRect(indicatorRRect, indicatorPaint);
    }
  }

  @override
  bool shouldRepaint(_GradientProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
