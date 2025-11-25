import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../bindings/auth/verify_code_binding.dart';
import '../../views/auth/verify_code_view.dart';

class ForgotPasswordController extends GetxController {
  final emailController = TextEditingController();
  final RxBool isLoading = false.obs;

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your email',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    try {
      Get.snackbar(
        'Sukses',
        'Jika akun ada, kode reset akan dikirim ke $email',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      // Navigate to the code entry screen (prefill email)
      Get.to(
        () => const VerifyCodeView(),
        binding: VerifyCodeBinding(),
        arguments: {'email': email},
      );
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}
