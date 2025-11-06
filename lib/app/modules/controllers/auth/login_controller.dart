import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../views/shell/app_shell.dart';
import '../../bindings/shell/app_shell_binding.dart';
// AppShell is used as the shared UI shell with bottom navigation.

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void login() {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email == 'admin@gmail.com' && password == '12345') {
      // Navigate to the AppShell after successful login so the bottom
      // navigation is shared across pages.
      Get.off(() => const AppShell(), binding: AppShellBinding());
    } else {
      Get.snackbar(
        'Error',
        'Invalid email or password',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
