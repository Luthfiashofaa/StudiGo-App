import 'package:get/get.dart';

import '../../controllers/home/home_controller.dart';
import '../../controllers/profile/profile_controller.dart';

class AppShellBinding extends Bindings {
  @override
  void dependencies() {
    // Register HomeController and ProfileController so pages inside the
    // shell can obtain them via Get.find().
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
