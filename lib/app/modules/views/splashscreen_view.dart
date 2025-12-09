import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:studigo/app/modules/views/auth/login_view.dart';
import 'package:studigo/app/modules/bindings/auth/login_binding.dart';
import 'package:studigo/app/modules/views/shell/app_shell.dart';
import 'package:studigo/app/modules/bindings/shell/app_shell_binding.dart';
import 'package:studigo/app/data/services/auth_persistence_service.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Get AuthPersistenceService to check login state
    final authPersistence = Get.find<AuthPersistenceService>();
    final isLoggedIn = authPersistence.isLoggedIn();

    if (mounted) {
      // Delay untuk menunjukkan splash screen selama 3 detik total
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          if (isLoggedIn) {
            // User sudah login (ada di SharedPreferences), ke AppShell (navbar)
            Get.off(() => const AppShell(), binding: AppShellBinding());
          } else {
            // User belum login, ke Login
            Get.off(() => LoginView(), binding: LoginBinding());
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          children: [
            const Spacer(flex: 5),
            Image.asset('assets/logo.png', width: 400, height: 400),
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
