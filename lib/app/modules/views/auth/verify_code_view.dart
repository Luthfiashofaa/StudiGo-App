import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/verify_code_controller.dart';

class VerifyCodeView extends GetView<VerifyCodeController> {
  const VerifyCodeView({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF0B61FF);

    Widget codeBox(int index, bool isTablet) {
      final boxSize = isTablet ? 64.0 : 56.0;
      return SizedBox(
        width: boxSize,
        child: TextField(
          controller: controller.codeControllers[index],
          focusNode: controller.focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          decoration: InputDecoration(
            counterText: '',
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 2.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primaryBlue, width: 2.4),
            ),
          ),
          onChanged: (val) {
            if (val.isNotEmpty) {
              if (index + 1 < controller.focusNodes.length) {
                controller.focusNodes[index + 1].requestFocus();
              } else {
                controller.focusNodes[index].unfocus();
              }
            } else {
              if (index - 1 >= 0)
                controller.focusNodes[index - 1].requestFocus();
            }
          },
        ),
      );
    }

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
            final buttonHeight = isTablet ? 60.0 : 52.0;

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
                              'Check your email',
                              style: TextStyle(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Obx(() {
                              final email = controller.email.value;
                              return RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: descSize,
                                    color: Colors.grey.shade600,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'We sent a reset link to ',
                                    ),
                                    TextSpan(
                                      text: email,
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const TextSpan(
                                      text:
                                          '\nenter 5 digit code that mentioned in the email',
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                5,
                                (i) => codeBox(i, isTablet),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Obx(() {
                                final rem = controller.remaining.value;
                                final isSending = controller.isSending.value;
                                String timerText;
                                if (rem > 0) {
                                  final mins = (rem ~/ 60).toString().padLeft(
                                    2,
                                    '0',
                                  );
                                  final secs = (rem % 60).toString().padLeft(
                                    2,
                                    '0',
                                  );
                                  timerText = 'Kode berlaku: $mins:$secs';
                                } else {
                                  timerText = 'Kode tidak aktif';
                                }
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      timerText,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: isTablet ? 16 : 14,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextButton(
                                      onPressed: (rem == 0 && !isSending)
                                          ? controller.resendCode
                                          : null,
                                      child: isSending
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text('Kirim ulang kode'),
                                    ),
                                  ],
                                );
                              }),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: controller.verifyCode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  foregroundColor: Colors.white,
                                  minimumSize: Size.fromHeight(buttonHeight),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Verify Code',
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
