import 'package:get/get.dart';
import 'package:studigo/app/modules/home/views/splashscreen.dart';

import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASHSCREEN;

  static final routes = [
    GetPage(name: _Paths.SPLASHSCREEN, page: () => const SplashScreen()),
  ];
}
