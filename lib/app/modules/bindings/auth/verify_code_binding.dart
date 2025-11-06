import 'package:get/get.dart';
import '../../controllers/auth/verify_code_controller.dart';

class VerifyCodeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VerifyCodeController>(() => VerifyCodeController());
  }
}
