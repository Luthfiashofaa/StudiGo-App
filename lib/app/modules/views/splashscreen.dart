import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../views/shell/app_shell.dart'; // ganti sesuai halaman utama kamu
import '../bindings/shell/app_shell_binding.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Tunggu 3 detik lalu pindah ke AppShell (shared navbar)
    Timer(const Duration(seconds: 3), () {
      Get.off(() => const AppShell(), binding: AppShellBinding());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          // Use spacers to nudge the logo slightly down from the vertical center
          // which is more responsive than fixed padding.
          children: [
            const Spacer(flex: 5),
            Image.asset(
              'assets/logo.png', // sesuaikan path asetmu
              width: 400,
              height: 400,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}
