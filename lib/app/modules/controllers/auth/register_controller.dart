import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterController extends GetxController {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final birthDateController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  final Rxn<DateTime> birthDate = Rxn<DateTime>();

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    birthDateController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void setBirthDate(DateTime? date) {
    birthDate.value = date;
    birthDateController.text = date != null ? _formatDate(date) : '';
  }

  String _formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void register() {
    final first = firstNameController.text.trim();
    final last = lastNameController.text.trim();
    final email = emailController.text.trim();
    final pwd = passwordController.text;

    if (first.isEmpty || last.isEmpty || email.isEmpty || pwd.isEmpty) {
      Get.snackbar(
        'Missing fields',
        'Please fill all required fields',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // TODO: integrate real registration logic (API call)
    Get.snackbar(
      'Success',
      'Account created',
      snackPosition: SnackPosition.BOTTOM,
    );
    // Optionally navigate back to login
    // Get.offAllNamed('/login');
  }
}
