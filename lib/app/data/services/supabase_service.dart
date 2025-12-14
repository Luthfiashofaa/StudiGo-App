import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService extends GetxService {
  SupabaseClient? _client;
  bool _initialized = false;

  /// Safe accessor for the Supabase client. Throws a clear error if the
  /// service hasn't been initialized yet. This helps surface misuse where
  /// client is accessed before calling/awaiting `SupabaseService.init()`.
  SupabaseClient get client {
    if (!_initialized || _client == null) {
      throw Exception(
        'Supabase client not initialized. Ensure you call and await SupabaseService.init() in main() before using Supabase features.',
      );
    }
    return _client!;
  }

  Future<SupabaseService> init() async {
    try {
      // Load environment variables with better error handling
      if (kDebugMode) {
        debugPrint('Loading .env file...');
      }

      // Try to load the .env file if available. If it's not found (for example
      // when running on a device where the file isn't present), we catch the
      // error and continue — later we try other sources (dart-define) before
      // failing with a user-friendly message.
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        if (kDebugMode) {
          debugPrint('.env file not found or failed to load: $e');
          debugPrint(
            'Falling back to compile-time environment (dart-define) if provided.',
          );
        }
      }

      // Prefer values from dotenv, otherwise allow compile-time values via
      // --dart-define (useful for CI/builds). This avoids importing
      // dart:io and is web-safe.
      final supabaseUrl =
          dotenv.env['SUPABASE_URL'] ??
          const String.fromEnvironment('SUPABASE_URL');
      final supabaseAnonKey =
          dotenv.env['SUPABASE_ANON_KEY'] ??
          const String.fromEnvironment('SUPABASE_ANON_KEY');

      if (supabaseUrl.isEmpty) {
        throw Exception(
          'SUPABASE_URL not found in .env file\n'
          'Please add: SUPABASE_URL=your_url',
        );
      }

      if (supabaseAnonKey.isEmpty) {
        throw Exception(
          'SUPABASE_ANON_KEY not found in .env file\n'
          'Please add: SUPABASE_ANON_KEY=your_key',
        );
      }

      if (kDebugMode) {
        debugPrint('Initializing Supabase...');
      }

      // Debug: print masked values so we can confirm keys were loaded without
      // leaking secrets to logs. Useful to diagnose NotInitializedError.
      String mask(String s) {
        if (s.length <= 12) return '************';
        return '${s.substring(0, 6)}...${s.substring(s.length - 6)}';
      }

      if (kDebugMode) {
        debugPrint('Supabase URL: ${mask(supabaseUrl)}');
        debugPrint('Supabase ANON key: ${mask(supabaseAnonKey)}');
      }

      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

      // Assign the instance client and mark initialized.
      _client = Supabase.instance.client;
      _initialized = true;

      if (kDebugMode) {
        debugPrint('Supabase initialized successfully');
        debugPrint('URL: $supabaseUrl');
      }

      return this;
    } catch (e, st) {
      final msg = e.toString();
      // Handle missing .env file with a friendly message
      if (msg.contains('FileSystemException') || msg.contains('.env')) {
        throw Exception(
          '.env file not found!\n\n'
          'Please create a .env file in the root directory with:\n'
          'SUPABASE_URL=your_supabase_url\n'
          'SUPABASE_ANON_KEY=your_anon_key\n\n'
          'You can copy from .env.example if available.',
        );
      }

      // Handle Supabase not-initialized errors and provide guidance
      if (msg.contains('NotInitialized') || msg.contains('not initialized')) {
        throw Exception(
          'Supabase client not initialized.\n\n'
          'This usually means Supabase.initialize failed (missing/invalid keys) or was not awaited.\n'
          'Ensure SUPABASE_URL and SUPABASE_ANON_KEY are set (in .env or via --dart-define) and that\n'
          'you await SupabaseService.init() before using Supabase features.\n\n'
          'Underlying error: $msg',
        );
      }

      // For other errors, rethrow but include stacktrace in debug logs
      if (kDebugMode) {
        debugPrint('SupabaseService.init error: $e');
        debugPrint('$st');
      }
      rethrow;
    }
  }

  // Auth helpers
  User? get currentUser => client.auth.currentUser;
  Session? get currentSession => client.auth.currentSession;
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // Database helpers
  SupabaseQueryBuilder from(String table) => client.from(table);
  SupabaseStorageClient get storage => client.storage;
}
