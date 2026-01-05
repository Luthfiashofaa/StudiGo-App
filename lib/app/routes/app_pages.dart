import 'package:get/get.dart';
import 'package:studigo/app/modules/views/splashscreen_view.dart';
import 'package:studigo/app/modules/views/auth/login_view.dart';
import 'package:studigo/app/modules/views/home/home_view.dart';
import 'package:studigo/app/modules/views/home/gemini_chat_view.dart';
import 'package:studigo/app/modules/views/auth/auth_callback_view.dart';
import 'package:studigo/app/modules/views/auth/new_password_view.dart';
import 'package:studigo/app/modules/views/schedule/add_schedule_view.dart';
import 'package:studigo/app/modules/views/profile/profile_view.dart';
import 'package:studigo/app/routes/test_notification_screen.dart';

import 'package:studigo/app/modules/bindings/auth/login_binding.dart';
import 'package:studigo/app/modules/bindings/auth/new_password_binding.dart';
import 'package:studigo/app/modules/bindings/home/home_binding.dart';
import 'package:studigo/app/modules/bindings/schedule/add_schedule_binding.dart';
import 'package:studigo/app/modules/bindings/profile/profile_binding.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.splashscreen;

  static final routes = [
    GetPage(name: _Paths.splashscreen, page: () => const SplashScreen()),
    GetPage(
      name: _Paths.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(name: _Paths.home, page: () => HomeView(), binding: HomeBinding()),
    GetPage(
      name: _Paths.addschedule,
      page: () => const AddScheduleView(),
      binding: AddScheduleBinding(),
    ),
    GetPage(
      name: _Paths.profile,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.testNotification,
      page: () => const TestNotificationScreen(),
    ),
    GetPage(name: _Paths.geminiChat, page: () => const GeminiChatView()),
    GetPage(name: '/auth-callback', page: () => const AuthCallbackView()),
    GetPage(
      name: '/new-password',
      page: () => const NewPasswordView(),
      binding: NewPasswordBinding(),
    ),
  ];
}
