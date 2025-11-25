import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/routes/app_pages.dart';
import 'app/data/services/supabase_service.dart';
import 'app/data/providers/auth_provider.dart';
import 'app/data/services/deeplink_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env early so any code that checks dotenv.env sees values.
  // This helps avoid timing issues where something tries to read the
  // env before SupabaseService loads it.
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // If loading fails, continue — SupabaseService.init will try again and
    // provide a helpful error message. We print the error in debug mode.
    // Note: avoid crashing here to allow builds that use --dart-define.
    // (dotenv.load can throw when .env is missing in some environments.)
    // The SupabaseService will validate presence of keys and throw if needed.
    // Keep this lightweight and non-blocking for environments that use
    // compile-time defines instead of a .env file.
    // ignore: avoid_print
    debugPrint('dotenv.load() warning: $e');
  }

  // Initialize SupabaseService (loads .env and initializes client)
  await Get.putAsync(() => SupabaseService().init());

  // Register AuthProvider after SupabaseService is ready
  Get.put(AuthProvider());
  // Start deep-link listener to handle incoming OAuth / recovery redirects.
  Get.put(DeepLinkService());
  runApp(
    GetMaterialApp(
      title: "Application",
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    ),
  );
}
