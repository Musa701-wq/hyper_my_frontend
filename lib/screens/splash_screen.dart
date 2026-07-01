import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import '../utils/app_colors.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _attRequested = false;
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _mainController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestAtt());
    _startSplashTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_attRequested) {
      _requestAtt();
    }
  }

  static const _attChannel = MethodChannel('custom_att');

  Future<void> _requestAtt() async {
    if (!Platform.isIOS || _attRequested) return;

    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status != TrackingStatus.notDetermined) return;

    _attRequested = true;
    debugPrint("📱 ATT: Requesting tracking authorization...");

    final int raw;
    try {
      raw = await _attChannel.invokeMethod('requestAtt');
    } catch (_) {
      final fallback = await AppTrackingTransparency.requestTrackingAuthorization();
      debugPrint("📱 ATT: Authorization complete → $fallback.");
      if (fallback == TrackingStatus.notDetermined) _attRequested = false;
      return;
    }

    final result = TrackingStatus.values[raw];
    debugPrint("📱 ATT: Authorization complete → $result.");
    if (result == TrackingStatus.notDetermined) _attRequested = false;
  }

  Future<void> _startSplashTimer() async {
    await Future.delayed(const Duration(milliseconds: 5500));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (_, __, ___, child) => child,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.5,
            colors: [
              Color(0xFF1E2328),
              AppColors.background,
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Subtle background glow
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 250 * _pulseAnimation.value,
                  height: 250 * _pulseAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.brandAccent.withOpacity(0.04 * _pulseAnimation.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),

            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 7),
                    // Logo with breathing effect
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.brandAccent.withOpacity(0.12 * _pulseAnimation.value),
                                blurRadius: 35 * _pulseAnimation.value,
                                spreadRadius: 4 * _pulseAnimation.value,
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.brandAccent.withOpacity(0.15),
                            width: 1.5,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/LOGO.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 38),
                    
                    // Text branding
                    Text(
                      'HyperScreener',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        height: 1.0,
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.brandAccent.withOpacity(0.2), width: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'INSTITUTIONAL GRADE',
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.brandAccent.withOpacity(0.7),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2.2,
                        ),
                      ),
                    ),
                    const Spacer(flex: 10),
                  ],
                ),
              ),
            ),
            
            // Bottom loading/status
            Positioned(
              bottom: 64,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    SizedBox(
                      width: 100,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: const LinearProgressIndicator(
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandAccent),
                          minHeight: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Initializing markets...',
                      style: GoogleFonts.inter(
                        color: Colors.white24,
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
