import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../bindings/auth/login_binding.dart';
import '../../views/auth/login_view.dart';

class ProfileController extends GetxController {
  final emailController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final dobController = TextEditingController();
  final phoneController = TextEditingController();

  DateTime? birthDate;
  String countryCode = 'ID';
  String countryDialCode = '+62';
  String? avatarPath;

  @override
  void onClose() {
    emailController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    dobController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  void setBirthDate(DateTime date) {
    birthDate = date;
    dobController.text = _formatDate(date);
    update();
  }

  void setCountry(String code, String dialCode) {
    countryCode = code;
    countryDialCode = dialCode;
    update();
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} - ${d.month.toString().padLeft(2, '0')} - ${d.year}';

  Future<void> pickImage(ImageSource source) async {
    // Request runtime permissions first
    try {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          Get.snackbar(
            'Permission denied',
            'Camera permission is required to take photos',
          );
          return;
        }
      } else {
        if (Platform.isAndroid) {
          final statuses = await [
            Permission.photos,
            Permission.storage,
          ].request();
          final granted = statuses.values.any((s) => s.isGranted);
          if (!granted) {
            Get.snackbar(
              'Permission denied',
              'Storage permission is required to select photos',
            );
            return;
          }
        } else if (Platform.isIOS) {
          final status = await Permission.photos.request();
          if (!status.isGranted) {
            Get.snackbar(
              'Permission denied',
              'Photos permission is required to select photos',
            );
            return;
          }
        }
      }

      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        avatarPath = picked.path;
        update();
      }
    } catch (e) {
      Get.snackbar('Error', 'Unable to pick image: ${e.toString()}');
    }
  }

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0B61FF),
            ).copyWith(primary: const Color(0xFF0B61FF)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) setBirthDate(picked);
  }

  void updateProfile() {
    // TODO: send profile update to API
    Get.snackbar(
      'Success',
      'Profile updated',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void logout() {
    // Navigate to login and clear stack
    Get.offAll(() => const LoginView(), binding: LoginBinding());
  }
}
