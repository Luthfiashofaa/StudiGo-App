import 'package:get/get.dart';

class ShellController extends GetxController {
  final RxInt currentIndex = 0.obs;

  void setIndex(int index) {
    if (index < 0 || index > 3) return;
    currentIndex.value = index;
  }
}
