import 'package:get/get.dart';
import 'package:studigo/app/modules/views/splashscreen_view.dart';
import 'package:studigo/app/modules/views/auth/login_view.dart';
import 'package:studigo/app/modules/views/home/home_view.dart';
import 'package:studigo/app/modules/views/auth/auth_callback_view.dart';
import 'package:studigo/app/modules/views/schedule/add_schedule_view.dart';

import 'package:studigo/app/modules/bindings/auth/login_binding.dart';
import 'package:studigo/app/modules/bindings/home/home_binding.dart';
import 'package:studigo/app/modules/bindings/schedule/add_schedule_binding.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.splashscreen;

  static final routes = [
    GetPage(
      name: _Paths.splashscreen,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: _Paths.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.addschedule,
      page: () => const AddScheduleView(),
      binding: AddScheduleBinding(),
    ),

    GetPage(
      name: '/auth-callback',
      page: () => const AuthCallbackView(),
    ),
  ];
}
