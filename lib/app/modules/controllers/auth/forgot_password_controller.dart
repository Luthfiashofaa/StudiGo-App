import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../views/auth/verify_code_view.dart';
import '../../bindings/auth/verify_code_binding.dart';

class ForgotPasswordController extends GetxController {
  final emailController = TextEditingController();

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

  void resetPassword() {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your email',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.snackbar(
      'Password reset',
      'If an account exists for $email, you will receive an email with reset instructions.',
      snackPosition: SnackPosition.BOTTOM,
    );

    Get.to(
      () => const VerifyCodeView(),
      binding: VerifyCodeBinding(),
      arguments: {'email': email},
    );
  }
}
