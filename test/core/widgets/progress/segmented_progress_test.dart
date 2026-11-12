import 'package:axiom/core/widgets/progress/segmented_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('any started progress fills at least one segment', () {
    expect(SegmentedProgress.filledSegments(0, 10), 0);
    expect(SegmentedProgress.filledSegments(0.03, 10), 1);
    expect(SegmentedProgress.filledSegments(0.5, 10), 5);
    expect(SegmentedProgress.filledSegments(1.2, 10), 10);
  });
}
