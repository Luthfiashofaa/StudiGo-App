import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../../data/services/supabase_service.dart';
import '../../../data/services/auth_persistence_service.dart';
import '../../bindings/shell/app_shell_binding.dart';
import '../shell/app_shell.dart';

// controller and supabase service are not referenced directly here to keep
// this callback view SDK-agnostic; tokens are verified via REST if needed.

class AuthCallbackView extends StatefulWidget {
  const AuthCallbackView({super.key});

  @override
  State<AuthCallbackView> createState() => _AuthCallbackViewState();
}

class _AuthCallbackViewState extends State<AuthCallbackView> {
  bool _processing = false;

  Future<void> _persistLoginState() async {
    debugPrint('[OAuth] _persistLoginState() called');
    try {
      final supa = Get.find<SupabaseService>();
      final authPersistence = Get.find<AuthPersistenceService>();
      final user = supa.currentUser;

      debugPrint('[OAuth] Current user: ${user?.email ?? "null"}');
      if (user == null) {
        debugPrint('[OAuth] ❌ User is null, cannot persist login state');
        return;
      }

      // Check if user exists in public.users table
      debugPrint('[OAuth] Checking if user exists in public.users...');
      try {
        final res = await supa.client
            .from('users')
            .select('id')
            .eq('id', user.id)
            .maybeSingle();

        if (res == null) {
          // User doesn't exist in public.users, create it from OAuth data
          final userMeta = user.userMetadata ?? {};
          final fullName =
              (userMeta['full_name'] ??
                      userMeta['name'] ??
                      user.email?.split('@').first ??
                      'User')
                  as String;
          final avatarUrl =
              (userMeta['avatar_url'] ?? userMeta['picture'] ?? '') as String;

          // Use auth.user.created_at as the account creation date (Day 1 date)
          final createdAt = user.createdAt ?? DateTime.now().toIso8601String();

          debugPrint('[OAuth] Creating user in public.users: ${user.email}');
          debugPrint(
            '[OAuth] User data: id=${user.id}, name=$fullName, created_at=$createdAt',
          );

          final insertResult = await supa.client.from('users').insert({
            'id': user.id,
            'email': user.email,
            'name': fullName,
            'photo_url': avatarUrl.isNotEmpty ? avatarUrl : null,
            'created_at': createdAt,
          }).select();

          debugPrint('[OAuth] Insert result: $insertResult');
          debugPrint('[OAuth] ✅ User created successfully in public.users');
        } else {
          debugPrint('[OAuth] User already exists in public.users');
        }
      } catch (e, stackTrace) {
        debugPrint('[OAuth] ❌ Error checking/creating user: $e');
        debugPrint('[OAuth] Stack trace: $stackTrace');
        // Re-throw to see error in console
        rethrow;
      }

      await authPersistence.saveLoginState(
        user.id,
        user.email ?? '',
        role: 'user', // Default role since table doesn't have role column
      );
      debugPrint('[OAuth] ✅ Login state saved to SharedPreferences');
    } catch (e, stackTrace) {
      debugPrint('[OAuth] ❌ Persist login state error: $e');
      debugPrint('[OAuth] Stack trace: $stackTrace');
      // Re-throw to make error visible
      rethrow;
    }
  }

  Future<void> _attemptCompleteSignIn(Map<String, String> fragmentMap) async {
    if (_processing) return;
    setState(() => _processing = true);
    final access = fragmentMap['access_token'];
    final refresh = fragmentMap['refresh_token'];
    final type =
        fragmentMap['type']; // Check if this is recovery or normal login

    if (access == null) {
      Get.snackbar(
        'No token',
        'No access_token found in deep link',
        snackPosition: SnackPosition.BOTTOM,
      );
      setState(() => _processing = false);
      return;
    }

    // Try SDK setSession first using SupabaseService registered in main.dart
    try {
      final supabaseService = Get.find<SupabaseService>();
      final client = supabaseService.client;
      final authDyn = client.auth as dynamic; // keep dynamic to avoid API drift
      try {
        // Supabase Flutter v2 setSession expects refresh token (it will refresh access token)
        if (refresh == null || refresh.isEmpty) {
          throw Exception('refresh_token missing in deep link');
        }
        await authDyn.setSession(refresh);

        // Persist login info locally for splash auto-login
        await _persistLoginState();

        // Check if this is password recovery
        if (type == 'recovery') {
          Get.snackbar(
            'Recovery Session Active',
            'Please set your new password',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.blue,
            colorText: Colors.white,
          );
          // Navigate to new password screen with recovery token
          Get.offAllNamed(
            '/new-password',
            arguments: {
              'access_token': access,
              'refresh_token': refresh,
              'type': type,
            },
          );
        } else {
          Get.snackbar(
            'Signed in',
            'Sign-in completed successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          Get.offAll(() => const AppShell(), binding: AppShellBinding());
        }

        setState(() => _processing = false);
        return;
      } catch (e) {
        if (kDebugMode) debugPrint('setSession dynamic failed: $e');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('SupabaseService not available: $e');
    }

    // Fallback verify via REST
    final supabaseUrl =
        dotenv.env['SUPABASE_URL'] ??
        const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    final anon =
        dotenv.env['SUPABASE_ANON_KEY'] ??
        const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    if (supabaseUrl.isEmpty) {
      Get.snackbar(
        'Config error',
        'SUPABASE_URL not configured',
        snackPosition: SnackPosition.BOTTOM,
      );
      setState(() => _processing = false);
      return;
    }
    final uri = Uri.parse('$supabaseUrl/auth/v1/user');
    try {
      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $access',
          if (anon.isNotEmpty) 'apikey': anon,
        },
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        Get.snackbar(
          'Signed in',
          'Access token verified',
          snackPosition: SnackPosition.BOTTOM,
        );
        await _persistLoginState();
        Get.offAll(() => const AppShell(), binding: AppShellBinding());
      } else {
        if (kDebugMode)
          debugPrint('token verify failed: ${res.statusCode} ${res.body}');
        Get.snackbar(
          'Sign-in failed',
          'Token verification failed',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Token verify exception: $e');
      Get.snackbar(
        'Sign-in error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }

    setState(() => _processing = false);
  }

  @override
  void initState() {
    super.initState();
    // Attempt sign-in shortly after widget appears
    Future.microtask(() {
      final payload = Get.arguments as Map<String, dynamic>? ?? {};
      final fragmentMap =
          (payload['fragmentMap'] as Map<String, String>?) ?? {};
      if (fragmentMap.isNotEmpty) _attemptCompleteSignIn(fragmentMap);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memproses login')), // tampilan ringkas
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 48,
              width: 48,
              child: CircularProgressIndicator(strokeWidth: 4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Memproses tautan login...\nJangan tutup aplikasi.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (!_processing)
              ElevatedButton(
                onPressed: () {
                  final payload = Get.arguments as Map<String, dynamic>? ?? {};
                  final fragmentMap =
                      (payload['fragmentMap'] as Map<String, String>?) ?? {};
                  if (fragmentMap.isNotEmpty) {
                    _attemptCompleteSignIn(
                      Map<String, String>.from(fragmentMap),
                    );
                  }
                },
                child: const Text('Coba lagi'),
              ),
          ],
        ),
      ),
    );
  }
}
