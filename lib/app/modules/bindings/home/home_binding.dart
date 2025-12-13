import 'package:get/get.dart';

import '../../controllers/home/home_controller.dart';
import '../../controllers/profile/profile_controller.dart';
import '../../../data/services/supabase_service.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // SupabaseService is initialized in main.dart via Get.putAsync
    // HomeController should be registered here
    Get.lazyPut<HomeController>(() => HomeController());

    // ProfileController will access Get.find<SupabaseService>()
    // which is guaranteed to exist since main.dart uses Get.putAsync
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
