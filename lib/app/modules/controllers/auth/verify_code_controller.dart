import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/auth_provider.dart';
import '../../views/auth/reset_password_view.dart';
import '../../bindings/auth/reset_password_binding.dart';

class VerifyCodeController extends GetxController {
  final email = ''.obs;
  final List<TextEditingController> codeControllers = List.generate(
    5,
    (_) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(5, (_) => FocusNode());
  final RxInt remaining = 0.obs; // seconds remaining
  Timer? _timer;
  final RxBool isSending = false.obs;

  @override
  void onReady() {
    super.onReady();
    // Delay reactive updates to next frame to avoid "setState during build" error
    Future.delayed(Duration.zero, () {
      final args = Get.arguments;
      if (args is Map && args['email'] != null) {
        email.value = args['email'] as String;
      }
      // Start a 15-minute countdown when arriving at this screen. This is UI-only
      // and will be restarted when the user requests a resend.
      startTimer(15 * 60);
    });
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

  void startTimer(int seconds) {
    _timer?.cancel();
    remaining.value = seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remaining.value <= 0) {
        _timer?.cancel();
      } else {
        remaining.value--;
      }
    });
  }

  Future<void> resendCode() async {
    final e = email.value.trim();
    if (e.isEmpty) {
      Get.snackbar(
        'Error',
        'Email kosong',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    try {
      isSending.value = true;
      final authProvider = Get.find<AuthProvider>();
      await authProvider.sendResetCode(e);
      Get.snackbar(
        'Sukses',
        'Kode dikirim ulang ke $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      // restart timer to 15 minutes
      startTimer(15 * 60);
    } catch (err) {
      Get.snackbar(
        'Error',
        err.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSending.value = false;
    }
  }

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
