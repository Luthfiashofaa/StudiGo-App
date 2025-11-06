import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../bindings/auth/new_password_binding.dart';
import '../../views/auth/new_password_view.dart';

class ResetPasswordController extends GetxController {
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void onClose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void confirm() {
    // Navigate to New Password screen so the user can set their new password.
    // The NewPasswordBinding will provide the required controller.
    Get.to(() => const NewPasswordView(), binding: NewPasswordBinding());
  }
}
