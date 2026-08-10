import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';
import './services/language_provider.dart';
import './services/seed_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load persisted language before the first frame.
  await LanguageProvider.instance.load();

  // Initialize Firebase — wrapped in try/catch so the app still launches
  // on Flutter Web when google-services.json / FirebaseOptions are not yet
  // configured (avoids a silent blank-screen crash).
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (_) {
    // Firebase not configured yet — app runs in offline/demo mode.
  }

  // Seed data on first launch (only when Firebase is available)
  if (firebaseReady) {
    try {
      final seeded = await SeedDataService.instance.isSeeded();
      if (!seeded) {
        await SeedDataService.instance.seedAll();
      }
    } catch (_) {
      // Seed errors are non-fatal — app works with or without seed data
    }
  }

  bool hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(Duration(seconds: 5), () {
        hasShownError = false;
      });

      return CustomErrorWidget(message: details.exceptionAsString());
    }
    return SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - mobile only (SystemChrome
  // orientation APIs are not supported on Flutter Web and will throw
  // MissingPluginException, which would prevent runApp() from being called).
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild the entire widget tree when language changes so every screen
    // that reads LanguageProvider.instance.language gets the updated value.
    return ListenableBuilder(
      listenable: LanguageProvider.instance,
      builder: (context, _) {
        return Sizer(
          builder: (context, orientation, screenType) {
            return MaterialApp.router(
              title: 'kaarunyanursery',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeMode.light,
              // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(1.0)),
                  child: child!,
                );
              },
              // 🚨 END CRITICAL SECTION
              debugShowCheckedModeBanner: false,
              routerConfig: appRouter,
            );
          },
        );
      },
    );
  }
}
