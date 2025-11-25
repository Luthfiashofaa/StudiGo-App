import 'package:get/get.dart';

class AuthCallbackController extends GetxController {
  late final Map<String, dynamic> payload;

  @override
  void onInit() {
    super.onInit();
    payload = Get.arguments ?? {};
  }
}
