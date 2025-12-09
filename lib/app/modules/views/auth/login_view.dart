import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/login_controller.dart';
import 'register_view.dart';
import '../../bindings/auth/register_binding.dart';
import 'forgot_password_view.dart';
import '../../bindings/auth/forgot_password_binding.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final controller = Get.find<LoginController>();

  late TextEditingController emailController;
  late TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF0B61FF);

    InputDecoration fieldDecoration(String label, bool isTablet) =>
        InputDecoration(
          labelText: label,
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
        );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final bool isTablet = width >= 600;
            final horizontalPadding = isTablet ? 32.0 : 24.0;
            final titleSize = isTablet ? 36.0 : 30.0;
            final descSize = isTablet ? 16.0 : 14.0;
            final imageSize = isTablet ? 220.0 : 170.0;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 800 : double.infinity,
                ),
                child: ScrollConfiguration(
                  behavior: _NoGlowScrollBehavior(),
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: height),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 20,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Top content
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 8),
                                // Logo
                                Center(
                                  child: Image.asset(
                                    'assets/logo.png',
                                    width: imageSize,
                                    height: imageSize,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(height: 0),

                                // Title
                                Text(
                                  'Sign in to your\nAccount',
                                  style: TextStyle(
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Enter your email and password to login',
                                  style: TextStyle(
                                    fontSize: descSize,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Email
                                TextField(
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: fieldDecoration(
                                    'Email',
                                    isTablet,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Password
                                TextField(
                                  controller: passwordController,
                                  obscureText: true,
                                  decoration: fieldDecoration(
                                    'Password',
                                    isTablet,
                                  ),
                                ),
                                const SizedBox(height: 50),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Get.to(
                                        () => const ForgotPasswordView(),
                                        binding: ForgotPasswordBinding(),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 0),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      foregroundColor: Colors.black,
                                      textStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    child: const Text('Forgot Password?'),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Login button
                                Obx(
                                  () => ElevatedButton(
                                    onPressed: controller.isLoading.value
                                        ? null
                                        : () {
                                            String email;
                                            String password;
                                            try {
                                              email = emailController.text;
                                            } catch (e) {
                                              // Controller was disposed unexpectedly; recover with empty string
                                              email = '';
                                              emailController =
                                                  TextEditingController();
                                            }
                                            try {
                                              password =
                                                  passwordController.text;
                                            } catch (e) {
                                              password = '';
                                              passwordController =
                                                  TextEditingController();
                                            }

                                            controller.login(
                                              email: email,
                                              password: password,
                                            );
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryBlue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      minimumSize: Size.fromHeight(
                                        isTablet ? 60 : 52,
                                      ),
                                      elevation: 0,
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
                                            'Log in',
                                            style: TextStyle(
                                              fontSize: isTablet ? 18 : 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 18),

                                // Divider with Or
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        'Or',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                // Google sign-in
                                OutlinedButton.icon(
                                  onPressed: () {
                                    controller.continueWithGoogle();
                                  },
                                  icon: Image.asset(
                                    'assets/google.png',
                                    width: 22,
                                    height: 22,
                                    fit: BoxFit.contain,
                                  ),
                                  label: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    child: Text(
                                      'Continue with Google',
                                      style: TextStyle(color: Colors.black87),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),

                            // Bottom signup
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Don't have an account? "),
                                TextButton(
                                  onPressed: () {
                                    // Navigate to RegisterView with its binding so controller is available
                                    Get.to(
                                      () => const RegisterView(),
                                      binding: RegisterBinding(),
                                    );
                                  },
                                  child: const Text(
                                    'Sign up',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
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

// Remove glow/overscroll indicator on Android to reduce visual wobble
class _NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
