import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../views/shell/app_shell.dart';
import '../../bindings/shell/app_shell_binding.dart';
import '../../../data/providers/auth_provider.dart';
// AppShell is used as the shared UI shell with bottom navigation.

class LoginController extends GetxController {
  final RxBool isLoading = false.obs;

  /// Perform login using primitive string values supplied by the View.
  Future<void> login({required String email, required String password}) async {
    final e = email.trim();
    final p = password.trim();
    if (e.isEmpty || p.isEmpty) {
      Get.snackbar(
        'Missing fields',
        'Please enter email and password',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      final authProvider = Get.find<AuthProvider>();
      final res = await authProvider.login(e, p);

      final user = res.user;
      if (user != null) {
        // Successful login. Navigate to the main shell.
        Get.off(() => const AppShell(), binding: AppShellBinding());
      } else {
        // If user is null, show an error (res may include error message)
        Get.snackbar(
          'Login failed',
          'Unable to login',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Login error',
        e.toString(),
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Start the OAuth flow for Google. This will either open the system
  /// browser via the SDK or return an authorize URL (thrown as an Exception)
  /// which the UI can open with a URL launcher.
  Future<void> continueWithGoogle() async {
    isLoading.value = true;
    try {
      final authProvider = Get.find<AuthProvider>();
      await authProvider.signInWithGoogle();
    } catch (e) {
      // If the provider returned an authorize URL (via exception), surface
      // it so the UI can open it. Otherwise show a generic error.
      final msg = e.toString();
      if (msg.contains('Open this URL in a browser')) {
        Get.snackbar('Open browser', msg,
            backgroundColor: Colors.blueAccent, colorText: Colors.white);
      } else {
        Get.snackbar('Sign in error', msg,
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } finally {
      isLoading.value = false;
    }
  }
}
