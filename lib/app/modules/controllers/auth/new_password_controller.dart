import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../bindings/auth/login_binding.dart';
import '../../views/auth/login_view.dart';

class NewPasswordController extends GetxController {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  @override
  void onClose() {
    passwordController.dispose();
    confirmController.dispose();
    super.onClose();
  }

  Future<void> submit() async {
    final p1 = passwordController.text;
    final p2 = confirmController.text;
    if (p1.isEmpty || p2.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill both fields',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (p1.length < 6) {
      Get.snackbar(
        'Error',
        'Password must be at least 6 characters',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (p1 != p2) {
      Get.snackbar(
        'Error',
        'Passwords do not match',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    const primaryBlue = Color(0xFF0B61FF);

    // Helper: try to update password using recovery access token via
    // Supabase REST endpoint: PATCH {SUPABASE_URL}/auth/v1/user
    Future<bool> _tryUpdateWithToken(String token) async {
      final supabaseUrl =
          dotenv.env['SUPABASE_URL'] ??
          const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
      final anonKey =
          dotenv.env['SUPABASE_ANON_KEY'] ??
          const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
      if (supabaseUrl.isEmpty) return false;
      final uri = Uri.parse('$supabaseUrl/auth/v1/user');
      try {
        final res = await http.patch(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            if (anonKey.isNotEmpty) 'apikey': anonKey,
          },
          body: jsonEncode({'password': p1}),
        );
        if (res.statusCode >= 200 && res.statusCode < 300) {
          return true;
        }
        if (kDebugMode)
          debugPrint('Password update failed: ${res.statusCode} ${res.body}');
        return false;
      } catch (e, st) {
        if (kDebugMode) debugPrint('Password update exception: $e\n$st');
        return false;
      }
    }

    // If we have an access token from a deep link, try server update.
    final args = Get.arguments as Map<String, dynamic>?;
    final authParams = args?['authParams'] as Map<String, String>?;
    final token = authParams?['access_token'];
    var updated = false;
    if (token != null) {
      updated = await _tryUpdateWithToken(token);
      if (!updated) {
        Get.snackbar(
          'Error',
          'Unable to update password with recovery token. Please request a new reset link.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }

    // Show success dialog and navigate to login
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 4),
              const Text(
                'Successful',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                'Congratulations! Your password has been changed. Click continue to login',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Close the dialog first.
                    Get.back();
                    // Wait for the next frame so the pop is completed and widgets
                    // are not disposed while still being used by the framework.
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      try {
                        // Unfocus any text fields to avoid focus callbacks during dispose
                        FocusManager.instance.primaryFocus?.unfocus();
                        Get.offAll(
                          () => const LoginView(),
                          binding: LoginBinding(),
                        );
                      } catch (err, st) {
                        Get.snackbar(
                          'Navigation error',
                          err.toString(),
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        // ignore: avoid_print
                        print('Navigation error: $err\n$st');
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Update Password',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
