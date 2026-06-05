import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'utils/app_colors.dart';
import 'screens/splash_screen.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/subscription_viewmodel.dart';
import 'viewmodels/portfolio_viewmodel.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  // ✅ ATT + Firebase + dotenv — all in the SAME zone (no runZonedGuarded wrapping these)
  if (Platform.isIOS) {
    debugPrint("📱 ATT: Requesting tracking authorization...");
    await Future.delayed(const Duration(milliseconds: 200));
    await AppTrackingTransparency.requestTrackingAuthorization();
  }

  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    dotenv.load(fileName: ".env"),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => SubscriptionViewModel()),
        ChangeNotifierProvider(create: (_) => PortfolioViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyperScreener',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.brandAccent,
          surface: AppColors.surfaceBright,
        ),
        textTheme: GoogleFonts.jetBrainsMonoTextTheme(
          Theme.of(context).textTheme.apply(
                bodyColor: Colors.white,
                displayColor: Colors.white,
              ),
        ),
      ),
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
      home: const SplashScreen(),
    );
  }
}
