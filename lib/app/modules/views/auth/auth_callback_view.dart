import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// controller and supabase service are not referenced directly here to keep
// this callback view SDK-agnostic; tokens are verified via REST if needed.

class AuthCallbackView extends StatefulWidget {
  const AuthCallbackView({super.key});

  @override
  State<AuthCallbackView> createState() => _AuthCallbackViewState();
}

class _AuthCallbackViewState extends State<AuthCallbackView> {
  bool _processing = false;

  Future<void> _attemptCompleteSignIn(Map<String, String> fragmentMap) async {
    if (_processing) return;
    setState(() => _processing = true);
    final access = fragmentMap['access_token'];
    final refresh = fragmentMap['refresh_token'];
    if (access == null) {
      Get.snackbar(
        'No token',
        'No access_token found in deep link',
        snackPosition: SnackPosition.BOTTOM,
      );
      setState(() => _processing = false);
      return;
    }

    // Try SDK dynamic setSession first
    try {
      final supSvc = Get.find<dynamic>();
      final client = supSvc.client as dynamic;
      final authDyn = client.auth as dynamic;
      try {
        await authDyn.setSession({
          'access_token': access,
          if (refresh != null) 'refresh_token': refresh,
        });
        Get.snackbar(
          'Signed in',
          'Sign-in completed via SDK',
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.offAllNamed('/home');
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
        Get.offAllNamed('/home');
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
    final payload = Get.arguments as Map<String, dynamic>? ?? {};
    final uri = payload['uri'] as String? ?? '';
    final query = payload['queryParameters'] as Map<String, dynamic>? ?? {};
    final fragment = payload['fragment'] as String? ?? '';
    final fragmentMap = payload['fragmentMap'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('Auth Callback')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final bool isTablet = width >= 600;
          final horizontalPadding = isTablet ? 24.0 : 16.0;
          final headingStyle = TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 18 : 14,
          );
          final contentTextStyle = TextStyle(fontSize: isTablet ? 16 : 14);

          Widget buildHeading(String text) => Text(text, style: headingStyle);

          final closeButton = ElevatedButton(
            onPressed: () {
              Get.back();
            },
            child: const Text('Close'),
          );

          final completeButton = ElevatedButton(
            onPressed: _processing
                ? null
                : () async {
                    await _attemptCompleteSignIn(
                      Map<String, String>.from(fragmentMap),
                    );
                  },
            child: _processing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Complete sign-in'),
          );

          final actions = isTablet
              ? Row(
                  children: [
                    Expanded(child: closeButton),
                    const SizedBox(width: 12),
                    Expanded(child: completeButton),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    closeButton,
                    const SizedBox(height: 12),
                    completeButton,
                  ],
                );

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 800 : double.infinity,
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
                      buildHeading('Received deep link URI'),
                      const SizedBox(height: 8),
                      SelectableText(uri, style: contentTextStyle),
                      const SizedBox(height: 16),
                      buildHeading('Query parameters'),
                      const SizedBox(height: 8),
                      if (query.isEmpty)
                        Text('(none)', style: contentTextStyle)
                      else
                        ...query.entries.map(
                          (e) => Text(
                            '${e.key}: ${e.value}',
                            style: contentTextStyle,
                          ),
                        ),
                      const SizedBox(height: 16),
                      buildHeading('Fragment (raw)'),
                      const SizedBox(height: 8),
                      Text(
                        fragment.isEmpty ? '(none)' : fragment,
                        style: contentTextStyle,
                      ),
                      const SizedBox(height: 16),
                      buildHeading('Fragment parsed'),
                      const SizedBox(height: 8),
                      if (fragmentMap.isEmpty)
                        Text('(none)', style: contentTextStyle)
                      else
                        ...fragmentMap.entries.map(
                          (e) => Text(
                            '${e.key}: ${e.value}',
                            style: contentTextStyle,
                          ),
                        ),
                      const SizedBox(height: 24),
                      actions,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
