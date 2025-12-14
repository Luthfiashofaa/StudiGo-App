import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:studigo/app/routes/app_pages.dart';

class RegisterController extends GetxController {
  final RxBool isLoading = false.obs;

  /// Register using primitive values supplied by the View. The TextEditing
  /// controllers are owned by the StatefulWidget to avoid dispose/lifecycle
  /// races when GetX removes controllers during navigation.
  Future<void> register({
    required String first,
    required String last,
    required String email,
    required String pwd,
    String? birthdateIso,
    String? phoneNumber,
  }) async {
    if (first.isEmpty || last.isEmpty || email.isEmpty || pwd.isEmpty) {
      Get.snackbar(
        'Missing fields',
        'Please fill all required fields',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        borderRadius: 12,
        icon: const Icon(Icons.error_outline, color: Colors.white),
        snackStyle: SnackStyle.FLOATING,
      );
      return;
    }

    isLoading.value = true;
    try {
      // Create auth user
      final authProvider = Get.find<AuthProvider>();
      final AuthResponse authRes = await authProvider.register(email, pwd);

      final User? user = authRes.user;
      if (user == null) {
        final supa = Get.find<SupabaseService>();
        final sessionUser = supa.currentUser;
        if (sessionUser == null) {
          throw Exception('Registration failed: no user returned');
        }
      }

      final uid = user?.id ?? Get.find<SupabaseService>().currentUser?.id;
      if (uid == null)
        throw Exception('Unable to retrieve user id after signup');

      // Insert profile row into public.users table
      final supabase = Get.find<SupabaseService>().client;

      final insertData = {
        'id': uid,
        'firstname': first,
        'lastname': last,
        'name': '$first $last',
        'email': email,
        'birthdate': birthdateIso,
        'phone_number': phoneNumber != null && phoneNumber.trim().isNotEmpty
            ? phoneNumber.trim()
            : null,
        'photo_url': null,
      };

      final inserted = await supabase.from('users').insert(insertData).select();
      final List insertedList = inserted as List;
      if (insertedList.isEmpty) {
        throw Exception('Failed to create user profile');
      }

      Get.snackbar(
        'Registration Successful',
        'Your account was created successfully. Redirecting to login...',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blueAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        borderRadius: 12,
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
        snackStyle: SnackStyle.FLOATING,
        duration: const Duration(seconds: 3),
      );

      Future.delayed(const Duration(seconds: 2), () {
        Get.offAllNamed(Routes.login);
      });
    } catch (e) {
      Get.snackbar(
        'Registration error',
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        borderRadius: 12,
        icon: const Icon(Icons.error, color: Colors.white),
        snackStyle: SnackStyle.FLOATING,
        duration: const Duration(seconds: 6),
        mainButton: TextButton(
          onPressed: () {
            // Close the snackbar so the user can try again in the form.
            if (!isLoading.value) Get.back();
          },
          child: const Text(
            'Retry',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
