import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/verify_code_controller.dart';

class VerifyCodeView extends GetView<VerifyCodeController> {
  const VerifyCodeView({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF0B61FF);

    Widget codeBox(int index) {
      return SizedBox(
        width: 56,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back arrow shifted to the left to align with design
              Transform.translate(
                offset: const Offset(-12, 0),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back, size: 28),
                ),
              ),
              const SizedBox(height: 8),

              const Text(
                'Check your email',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Obx(() {
                final email = controller.email.value;
                return RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    children: [
                      const TextSpan(text: 'We sent a reset link to '),
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
                children: List.generate(5, (i) => codeBox(i)),
              ),

              const SizedBox(height: 16),
              // Centered countdown and resend below code boxes
              Center(
                child: Obx(() {
                  final rem = controller.remaining.value;
                  final isSending = controller.isSending.value;
                  String timerText;
                  if (rem > 0) {
                    final mins = (rem ~/ 60).toString().padLeft(2, '0');
                    final secs = (rem % 60).toString().padLeft(2, '0');
                    timerText = 'Kode berlaku: $mins:$secs';
                  } else {
                    timerText = 'Kode tidak aktif';
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timerText,
                        style: TextStyle(color: Colors.grey.shade700),
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

              ElevatedButton(
                onPressed: controller.verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Verify Code',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
