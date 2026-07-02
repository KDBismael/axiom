import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/features/shell/controllers/shell_controller.dart';

void main() {
  test('changeTab updates currentIndex', () {
    final controller = ShellController();
    expect(controller.currentIndex.value, 0);
    controller.changeTab(2);
    expect(controller.currentIndex.value, 2);
  });
}
