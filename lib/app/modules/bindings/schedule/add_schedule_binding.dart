import 'package:get/get.dart';

import '../../controllers/schedule/add_schedule_controller.dart';

class AddScheduleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AddScheduleController());
  }
}
