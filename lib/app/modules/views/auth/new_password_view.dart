import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/new_password_controller.dart';

class NewPasswordView extends GetView<NewPasswordController> {
  const NewPasswordView({super.key});

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
            final labelSize = isTablet ? 16.0 : 15.0;
            final buttonHeight = isTablet ? 60.0 : 52.0;
            final spacingLarge = isTablet ? 50.0 : 50.0;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 700 : double.infinity,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 16,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // show custom back button only on mobile
                            if (!isTablet)
                              Transform.translate(
                                offset: const Offset(-12, 0),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => Get.back(),
                                  icon: const Icon(Icons.arrow_back, size: 28),
                                ),
                              ),
                            SizedBox(height: isTablet ? 0 : 8),

                            Text(
                              'Set a new password',
                              style: TextStyle(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create a new password. Ensure it differs from previous ones for security',
                              style: TextStyle(
                                fontSize: descSize,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            SizedBox(height: spacingLarge),

                            Text(
                              'Password',
                              style: TextStyle(
                                fontSize: labelSize,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: controller.passwordController,
                              obscureText: true,
                              decoration: fieldDecoration(
                                'Enter your password',
                                isTablet,
                              ),
                            ),
                            const SizedBox(height: 12),

                            Text(
                              'Confirm Password',
                              style: TextStyle(
                                fontSize: labelSize,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: controller.confirmController,
                              obscureText: true,
                              decoration: fieldDecoration(
                                'Enter your new password',
                                isTablet,
                              ),
                            ),

                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: controller.submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  foregroundColor: Colors.white,
                                  minimumSize: Size.fromHeight(buttonHeight),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Update Password',
                                  style: TextStyle(
                                    fontSize: isTablet ? 18 : 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // show back button icon positioned on left for tablet
                    if (isTablet)
                      Positioned(
                        left: -(horizontalPadding + 48.0),
                        top: 8,
                        child: SizedBox(
                          width: horizontalPadding + 64.0,
                          height: 64.0,
                          child: Align(
                            alignment: Alignment.centerRight,
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
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
