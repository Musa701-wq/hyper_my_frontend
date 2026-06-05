import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'utils/app_colors.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/subscription_viewmodel.dart';
import 'viewmodels/portfolio_viewmodel.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 📱 ATT: Ensure the dialog appears before any network operations.
  if (Platform.isIOS) {
    debugPrint("📱 ATT: Requesting tracking authorization...");
    // A small delay is still recommended by the package to ensure the app is in the foreground
    await Future.delayed(const Duration(milliseconds: 1000));
    await AppTrackingTransparency.requestTrackingAuthorization();
  }

  // 🚀 Start other services AFTER ATT is handled
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    dotenv.load(fileName: ".env"),
  ]);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeViewModel()), // Remove ..fetchTickers()
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
          Theme.of(context).textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
        ),
      ),
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
      home: const SplashScreen(),
    );
  }
}
