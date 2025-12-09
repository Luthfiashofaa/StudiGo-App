import 'package:get/get.dart';
import '../../controllers/profile/profile_controller.dart';
import '../../../data/services/supabase_service.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // SupabaseService should already be registered in main.dart
    // But double-check in case it's accessed before initialization completes
    if (Get.isRegistered<SupabaseService>()) {
      Get.lazyPut<ProfileController>(() => ProfileController());
    } else {
      // Fallback: create ProfileController that will get SupabaseService later
      Get.lazyPut<ProfileController>(
        () => ProfileController(),
        tag: 'profile_deferred',
      );
    }
  }
}
