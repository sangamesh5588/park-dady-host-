import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;

  // Logo animations
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotateAnimation;

  // Text animations
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  // Progress animation
  late Animation<double> _progressAnimation;

  String _statusText = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
    _initializeApp();
  }

  void _initializeAnimations() {
    // Main controller for overall timing
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Logo controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Text controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Progress controller
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Logo animations
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoRotateAnimation = Tween<double>(
      begin: -0.15,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    ));

    // Text animations
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    // Progress animation
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimationSequence() {
    // Start main controller
    _mainController.forward();

    // Start logo animation after a brief delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _logoController.forward();
    });

    // Start text animation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _textController.forward();
    });

    // Start progress after logo is done
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _progressController.forward();
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    if (!mounted) return;

    try {
      // Step 1: Initialize
      if (mounted) setState(() => _statusText = 'Loading...');
      await Future.delayed(const Duration(milliseconds: 800));

      // Step 2: Ready
      if (mounted) setState(() => _statusText = 'Ready!');
      await Future.delayed(const Duration(milliseconds: 700));

      // Smoothly complete progress bar
      if (mounted) {
        await _progressController.animateTo(
          1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      // Silently handle errors - parent will handle navigation
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _logoController,
          _textController,
          _progressController,
        ]),
        builder: (context, child) {
          return Container(
            color: Colors.white,
            child: Stack(
              children: [
                // Minimal content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Clean P logo
                      _buildLogo(),

                      const SizedBox(height: 40),

                      // App name
                      _buildText(),

                      const SizedBox(height: 60),

                      // Clean progress indicator
                      _buildProgressIndicator(),

                      // Status text
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Padding(
                          key: ValueKey<String>(_statusText),
                          padding: const EdgeInsets.only(top: 32),
                          child: Text(
                            _statusText,
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.6),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Subtle bottom fade
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.8),
                          Colors.white,
                        ],
                        stops: const [0.0, 0.3, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    // Add a subtle pulse animation after the initial animation
    final pulseValue = _logoController.isCompleted
        ? (math.sin(DateTime.now().millisecondsSinceEpoch * 0.005) * 0.02 + 1.0)
        : 1.0;

    return Transform.scale(
      scale: _logoScaleAnimation.value * pulseValue,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 50,
              offset: const Offset(0, 12),
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Text(
            'P',
            style: TextStyle(
              color: Colors.white,
              fontSize: 72,
              fontWeight: FontWeight.w900,
              letterSpacing: -2.0,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildText() {
    return SlideTransition(
      position: _textSlideAnimation,
      child: FadeTransition(
        opacity: _textFadeAnimation,
        child: const Text(
          'PARKDADDY HOST',
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      width: 200,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: _progressAnimation.value,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.black.withOpacity(0.8),
          ),
        ),
      ),
    );
  }
}
