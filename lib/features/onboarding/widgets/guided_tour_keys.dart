import 'package:flutter/widgets.dart';

/// Anchors on the home screen that the guided tour's bubbles point at.
abstract class GuidedTourKeys {
  static final newQuestButton = GlobalKey(debugLabel: 'tour-new-quest');
  static final firstQuestCard = GlobalKey(debugLabel: 'tour-first-quest');
}
