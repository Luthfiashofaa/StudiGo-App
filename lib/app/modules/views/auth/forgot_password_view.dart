import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/forgot_password_controller.dart';

class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF0B61FF);

    InputDecoration fieldDecoration(String hint, bool isTablet) =>
        InputDecoration(
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
        );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final bool isTablet = width >= 600;
            final horizontalPadding = isTablet ? 32.0 : 20.0;
            final titleSize = isTablet ? 34.0 : 28.0;
            final descSize = isTablet ? 16.0 : 14.0;
            final contentTextStyle = TextStyle(
              fontSize: descSize,
              color: Colors.grey.shade600,
            );

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 700 : double.infinity,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 16,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            onPressed: () => Get.back(),
                            icon: const Icon(Icons.arrow_back, size: 28),
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          'Forgot password',
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                                            Transform.translate(
                                              offset: Offset(isTablet ? -20 : -12, 0),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: IconButton(
                                                  padding: const EdgeInsets.all(8),
                                                  constraints: const BoxConstraints(
                                                    minWidth: 48,
                                                    minHeight: 48,
                                                  ),
                                                  onPressed: () => Get.back(),
                                                  icon: const Icon(Icons.arrow_back, size: 28),
                                                ),
                                              ),
                                            ),
                        Text(
                          'Please enter your email to reset the password',
                          style: contentTextStyle,
                        ),
                        SizedBox(height: isTablet ? 40 : 35),

                        Text(
                          'Your Email',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isTablet ? 16 : 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: controller.emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: fieldDecoration(
                            'Enter your email',
                            isTablet,
                          ),
                        ),

                        const SizedBox(height: 20),
                        Obx(
                          () => SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: controller.isLoading.value
                                  ? null
                                  : controller.resetPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                minimumSize: Size.fromHeight(
                                  isTablet ? 60 : 52,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                                      'Reset Password',
                                      style: TextStyle(
                                        fontSize: isTablet ? 18 : 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                      ],
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
