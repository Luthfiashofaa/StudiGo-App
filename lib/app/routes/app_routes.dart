part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const splashscreen = _Paths.splashscreen;
  static const login = _Paths.login;
  static const home = _Paths.home;
  static const addschedule = _Paths.addschedule;
  static const profile = _Paths.profile;
  static const testNotification = _Paths.testNotification;
  static const newPassword = _Paths.newPassword;
}

abstract class _Paths {
  _Paths._();
  static const splashscreen = '/splashscreen';
  static const login = '/login';
  static const home = '/home';
  static const addschedule = '/add-schedule';
  static const profile = '/profile';
  static const testNotification = '/test-notification';
  static const newPassword = '/new-password';
}
