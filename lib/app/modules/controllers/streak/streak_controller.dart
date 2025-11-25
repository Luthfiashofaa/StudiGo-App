import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class StreakController extends GetxController {
  // example observable: current streak count (displayed top-left)
  final RxInt streakCount = 2.obs;

  // observable list of houses (rumah-rumah)
  final RxList<String> houses = <String>[].obs;

  // index of selected house (optional)
  final RxInt selectedHouseIndex = (-1).obs;

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

  // ----- Houses management -----
  void addHouse(String name) {
    houses.add(name);
  }

  void removeHouseAt(int index) {
    if (index >= 0 && index < houses.length) houses.removeAt(index);
  }

  void selectHouse(int index) {
    if (index >= 0 && index < houses.length) {
      selectedHouseIndex.value = index;
    } else {
      selectedHouseIndex.value = -1;
    }
  }

  /// Load more houses (generates sample names). Useful for infinite list demo.
  void loadMoreHouses({int add = 5}) {
    final start = houses.length + 1;
    for (var i = 0; i < add; i++) {
      houses.add('Rumah ${start + i}');
    }
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
