import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryBlue = const Color(0xFF0B61FF);

    InputDecoration fieldDecoration(String hint, {Widget? suffix}) =>
        InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          suffixIcon: suffix,
        );

    Future<void> _pickDate() async {
      final now = DateTime.now();
      final initial = controller.birthDate.value ?? DateTime(now.year - 20);
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(1900),
        lastDate: now,
        // Use builder to override the picker theme so the header/button color
        // uses your primaryBlue instead of the default purple.
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: primaryBlue, // header background color
                onPrimary: Colors.white, // header text color
                onSurface: Colors.black, // body text color
              ),
              dialogBackgroundColor: Colors.white,
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: primaryBlue),
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      );
      if (picked != null) controller.setBirthDate(picked);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              const Text(
                'Register',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Create an account to continue !',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),

              // First name
              TextField(
                controller: controller.firstNameController,
                decoration: fieldDecoration('First Name'),
              ),
              const SizedBox(height: 12),

              // Last name
              TextField(
                controller: controller.lastNameController,
                decoration: fieldDecoration('Last Name'),
              ),
              const SizedBox(height: 12),

              // Email
              TextField(
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: fieldDecoration('Email'),
              ),
              const SizedBox(height: 12),

              // Birth date (read-only)
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextField(
                    controller: controller.birthDateController,
                    decoration: fieldDecoration(
                      'Birth date',
                      suffix: const Padding(
                        padding: EdgeInsets.only(right: 12.0),
                        child: Icon(Icons.calendar_today_outlined, size: 20),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Phone
              TextField(
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
                decoration: fieldDecoration('Phone Number'),
              ),
              const SizedBox(height: 12),

              // Password
              TextField(
                controller: controller.passwordController,
                obscureText: true,
                decoration: fieldDecoration('Password'),
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: controller.register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text(
                  'Register',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 150),

              // Bottom login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextButton(
                    onPressed: () {
                      Get.back();
                    },
                    child: const Text(
                      'Log in',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
