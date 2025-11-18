import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../views/auth/reset_password_view.dart';
import '../../bindings/auth/reset_password_binding.dart';

class VerifyCodeController extends GetxController {
  final email = ''.obs;
  final List<TextEditingController> codeControllers = List.generate(
    5,
    (_) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(5, (_) => FocusNode());

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['email'] != null) {
      email.value = args['email'] as String;
    }
  }

  @override
  void onClose() {
    for (final c in codeControllers) {
      c.dispose();
    }
    for (final f in focusNodes) {
      f.dispose();
    }
    super.onClose();
  }

  String get code => codeControllers.map((c) => c.text).join();

  void verifyCode() {
    final entered = code;
    if (entered.length < 5) {
      Get.snackbar(
        'Invalid code',
        'Please enter the 5 digit code',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.snackbar(
      'Verified',
      'Code verified successfully',
      snackPosition: SnackPosition.BOTTOM,
    );

    // Navigate to reset password screen and pass email
    Get.to(
      () => const ResetPasswordView(),
      binding: ResetPasswordBinding(),
      arguments: {'email': email.value},
    );
  }
}
