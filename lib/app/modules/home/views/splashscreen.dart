import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'home_view.dart'; // ganti sesuai halaman utama kamu

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Tunggu 3 detik lalu pindah ke HomePage
    Timer(const Duration(seconds: 3), () {
      Get.off(() => const HomeView());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orangeAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'web/icons/logo.png', // sesuaikan path asetmu
              width: 130,
              height: 130,
            ),
            const SizedBox(height: 20),
            const Text(
              'StudiGo',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
