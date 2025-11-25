import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class DeepLinkService extends GetxService {
  StreamSubscription<Uri>? _sub;

  @override
  void onInit() {
    super.onInit();
    _startListening();
  }

  void _startListening() {
    try {
      final appLinks = AppLinks();
      _sub = appLinks.uriLinkStream.listen(
        (uri) {
          if (kDebugMode) debugPrint('Deep link received: $uri');
          _handleUri(uri);
        },
        onError: (err) {
          if (kDebugMode) debugPrint('Deep link error: $err');
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to start deep link listener: $e');
    }
  }

  void _handleUri(Uri uri) {
    // Parse fragment into a map for easy debugging (Supabase often sends
    // tokens in the fragment portion after '#').
    final fragment = uri.fragment;
    Map<String, String> fragmentMap = {};
    if (fragment.isNotEmpty) {
      for (final part in fragment.split('&')) {
        final kv = part.split('=');
        if (kv.length == 2) {
          fragmentMap[Uri.decodeComponent(kv[0])] = Uri.decodeComponent(kv[1]);
        }
      }
    }

    // Navigate to a debug callback view so the app can inspect tokens and
    // continue implementation. We pass raw uri, query params and parsed
    // fragment map as arguments.
    try {
      Get.toNamed(
        '/auth-callback',
        arguments: {
          'uri': uri.toString(),
          'queryParameters': uri.queryParameters,
          'fragment': fragment,
          'fragmentMap': fragmentMap,
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Navigation error from deep link: $e');
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
