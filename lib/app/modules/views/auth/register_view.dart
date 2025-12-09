import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/register_controller.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final controller = Get.find<RegisterController>();

  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController emailController;
  late final TextEditingController birthDateController;
  late final TextEditingController phoneController;
  late final TextEditingController passwordController;

  DateTime? birthDate;

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    emailController = TextEditingController();
    birthDateController = TextEditingController();
    phoneController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    birthDateController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = birthDate ?? DateTime(now.year - 20);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (BuildContext context, Widget? child) {
        const primaryBlue = Color(0xFF0B61FF);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
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
    if (picked != null) {
      setState(() {
        birthDate = picked;
        birthDateController.text = _formatDate(picked);
      });
    }
  }

  InputDecoration fieldDecoration(
    String hint, {
    Widget? suffix,
    bool isTablet = false,
  }) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(
      horizontal: isTablet ? 20 : 16,
      vertical: isTablet ? 18 : 14,
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

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF0B61FF);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final bool isTablet = width >= 600;
            final horizontalPadding = isTablet ? 32.0 : 24.0;
            final titleSize = isTablet ? 36.0 : 30.0;
            final descSize = isTablet ? 16.0 : 14.0;
            final buttonHeight = isTablet ? 60.0 : 52.0;
            final topSpacing = isTablet ? 40.0 : 60.0;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 700 : double.infinity,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: topSpacing),
                      Text(
                        'Register',
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create an account to continue !',
                        style: TextStyle(
                          fontSize: descSize,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // First name
                      TextField(
                        controller: firstNameController,
                        decoration: fieldDecoration(
                          'First Name',
                          isTablet: isTablet,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Last name
                      TextField(
                        controller: lastNameController,
                        decoration: fieldDecoration(
                          'Last Name',
                          isTablet: isTablet,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Email
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: fieldDecoration(
                          'Email',
                          isTablet: isTablet,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Birth date (read-only)
                      GestureDetector(
                        onTap: _pickDate,
                        child: AbsorbPointer(
                          child: TextField(
                            controller: birthDateController,
                            decoration: fieldDecoration(
                              'Birth date',
                              suffix: const Padding(
                                padding: EdgeInsets.only(right: 12.0),
                                child: Icon(
                                  Icons.calendar_today_outlined,
                                  size: 20,
                                ),
                              ),
                              isTablet: isTablet,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Phone
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: fieldDecoration(
                          'Phone Number',
                          isTablet: isTablet,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Password
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: fieldDecoration(
                          'Password',
                          isTablet: isTablet,
                        ),
                      ),

                      const SizedBox(height: 40),

                      Obx(
                        () => ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : () {
                                  controller.register(
                                    first: firstNameController.text.trim(),
                                    last: lastNameController.text.trim(),
                                    email: emailController.text.trim(),
                                    pwd: passwordController.text,
                                    birthdateIso: birthDate != null
                                        ? birthDate!
                                              .toIso8601String()
                                              .split('T')
                                              .first
                                        : null,
                                    phoneNumber:
                                        phoneController.text.trim().isNotEmpty
                                        ? phoneController.text.trim()
                                        : null,
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: Size.fromHeight(buttonHeight),
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Register',
                                  style: TextStyle(
                                    fontSize: isTablet ? 18 : 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
          },
        ),
      ),
    );
  }
}
