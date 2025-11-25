import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';

class AuthProvider extends GetxService {
  final SupabaseService _supabaseService = Get.find();

  // Get current user
  User? get currentUser => _supabaseService.currentUser;

  // Get auth state changes stream
  Stream<AuthState> get authStateChanges => _supabaseService.authStateChanges;

  // Login
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _supabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('Login successful');
      return response;
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  // Register
  Future<AuthResponse> register(String email, String password) async {
    try {
      final response = await _supabaseService.client.auth.signUp(
        email: email,
        password: password,
      );
      debugPrint('Registration successful');
      return response;
    } catch (e) {
      debugPrint('Registration error: $e');
      rethrow;
    }
  }

  // Send password reset email
  // Returns the redirect URL that was used when sending the reset email.
  // This helps the caller confirm whether a mobile deep-link (scheme) was used
  // so reset links open the app instead of localhost/web.
  Future<String> resetPassword(String email, {String? redirectTo}) async {
    try {
      // If caller didn't provide a redirect URL, try to pick one from env.
      if (redirectTo == null || redirectTo.isEmpty) {
        final fromEnv =
            dotenv.env['RESET_PASSWORD_REDIRECT'] ??
            const String.fromEnvironment(
              'RESET_PASSWORD_REDIRECT',
              defaultValue: '',
            );
        if (fromEnv.isNotEmpty) redirectTo = fromEnv;
      }
      // Fallback to a sensible mobile deep-link if none configured.
      // NOTE: you should register this exact value in Supabase Dashboard
      // -> Authentication -> Settings -> Redirect URLs.
      if (redirectTo == null || redirectTo.isEmpty) {
        redirectTo = 'studigo://auth-callback';
      }
      // Supabase method to send reset password email. redirectTo is optional.
      await _supabaseService.client.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectTo,
      );

      // Supabase Dart SDK's resetPasswordForEmail doesn't return a value;
      // just log completion for debugging.
      debugPrint('Password reset request completed');
      return redirectTo;
    } catch (e, st) {
      debugPrint('Reset password error: $e');
      if (kDebugMode) debugPrint('$st');
      rethrow;
    }
  }

  // Send a numeric reset code to the user's email via a server endpoint.
  // The server should accept a POST JSON body { email } and return 200 on success.
  Future<void> sendResetCode(String email) async {
    try {
      // read endpoint from env
      final sendUrl =
          dotenv.env['RESET_SEND_URL'] ??
          const String.fromEnvironment('RESET_SEND_URL', defaultValue: '');
      if (sendUrl.isEmpty) {
        // If no custom endpoint is configured, fall back to Supabase's
        // reset email flow so the app doesn't throw. This keeps local dev
        // working when a send-reset-code function isn't deployed.
        debugPrint(
          'RESET_SEND_URL not configured, falling back to Supabase reset link',
        );
        await resetPassword(email);
        return;
      }

      final res = await http.post(
        Uri.parse(sendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (res.statusCode != 200) {
        throw Exception(
          'Failed to send reset code: ${res.statusCode} ${res.body}',
        );
      }
      debugPrint('Reset code sent via $sendUrl');
    } catch (e) {
      debugPrint('sendResetCode error: $e');
      // Re-throw so callers can show user-facing feedback as appropriate.
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _supabaseService.client.auth.signOut();
      debugPrint('User logged out');
    } catch (e) {
      debugPrint('Logout error: $e');
      rethrow;
    }
  }

  // Start Google OAuth sign-in flow.
  // On mobile, Google requires an https redirect registered in the Google
  // console (e.g. Supabase's https callback). The app should register the
  // custom scheme (e.g. 'studigo://auth-callback') in Supabase Redirect URLs
  // so Supabase forwards the finished auth back into the app.
  //
  // See README/notes: do NOT add the custom scheme to Google's redirect URIs;
  // instead add Supabase's https callback to Google and add the app scheme
  // to Supabase.
  Future<void> signInWithGoogle() async {
    try {
      // pick redirect from env or use deep link
      final redirectTo =
          dotenv.env['RESET_PASSWORD_REDIRECT'] ?? 'studigo://auth-callback';

      // Build an authorize URL that starts Supabase's OAuth flow. This
      // avoids depending on SDK-specific types (AuthOptions/Provider) which
      // can differ between SDK versions. The UI can open this URL in a
      // browser (via url_launcher) to start the flow.
      final supabaseUrl =
          dotenv.env['SUPABASE_URL'] ??
          const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
      if (supabaseUrl.isEmpty) {
        throw Exception('SUPABASE_URL not configured in .env');
      }
      final base = supabaseUrl.endsWith('/')
          ? supabaseUrl.substring(0, supabaseUrl.length - 1)
          : supabaseUrl;
      final authorize =
          '$base/auth/v1/authorize?provider=google&redirect_to=${Uri.encodeComponent(redirectTo)}';

      debugPrint('Google OAuth authorize URL: $authorize');

      // Open the authorize URL in the external browser. This gives a
      // user-friendly flow across platforms without depending on a
      // particular Supabase SDK helper name.
      final uri = Uri.parse(authorize);
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          throw Exception('Could not open browser for Google sign-in');
        }
      } catch (e) {
        debugPrint('Failed to launch authorize URL: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      rethrow;
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;
}
