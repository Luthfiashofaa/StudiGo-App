import 'package:get/get.dart';
import 'package:studigo/app/modules/views/splashscreen_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.splashscreen;

  static final routes = [
    GetPage(name: _Paths.splashscreen, page: () => const SplashScreen()),
  ];
}
