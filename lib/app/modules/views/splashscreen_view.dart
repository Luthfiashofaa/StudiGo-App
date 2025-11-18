import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:studigo/app/modules/views/auth/login_view.dart';
import 'package:studigo/app/modules/bindings/auth/login_binding.dart';
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
    Timer(const Duration(seconds: 3), () {
      Get.off(() => LoginView(), binding: LoginBinding());
    });
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
