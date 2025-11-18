import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class StreakController extends GetxController {
  // example observable: current streak count (displayed top-left)
  final RxInt streakCount = 2.obs;

  // number of days to render (can be extended)
  final RxInt days = 20.obs;

  // whether we've already auto-scrolled to the current day (avoid repeat)
  bool hasAutoScrolled = false;

  // expose a ScrollController so the view can use infinite loading behavior
  late final ScrollController scrollController;

  void increment() => streakCount.value++;

  void loadMore({int add = 20}) {
    // append more days
    days.value = days.value + add;
  }

  @override
  void onInit() {
    super.onInit();
    scrollController = ScrollController();
    scrollController.addListener(() {
      final pos = scrollController.position;
      if (!pos.hasPixels) return;
      if (pos.pixels > pos.maxScrollExtent - 300) {
        // near bottom — load more days
        loadMore();
      }
    });
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
