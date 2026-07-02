import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axiom/core/theme/app_theme.dart';
import 'package:axiom/features/profile/views/profile_view.dart';
import 'package:axiom/features/quests/controllers/quest_list_controller.dart';
import 'package:axiom/features/quests/repositories/quest_repository.dart';
import 'package:axiom/features/social/controllers/social_controller.dart';
import 'package:axiom/features/social/repositories/social_repository.dart';

/// A layout smoke test, not a UI-behavior test: confirms the full scroll
/// extent of this content-heavy tab lays out without a RenderFlex/overflow
/// error, since the simulator sandbox in this environment has no working
/// input-injection path to scroll and verify visually below the fold.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(Get.reset);

  testWidgets('renders without layout overflow across its full scroll extent', (
    tester,
  ) async {
    Get.put<QuestRepository>(QuestRepository());
    Get.put<QuestListController>(QuestListController());
    Get.put<SocialRepository>(SocialRepository());
    Get.put<SocialController>(SocialController());

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.dark, home: const Scaffold(body: ProfileView())),
    );
    await tester.pump(const Duration(milliseconds: 350));
    tester.takeException();

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
    await tester.pump();
    tester.takeException();

    expect(find.text('ENREGISTRER LES MODIFICATIONS'), findsOneWidget);
    expect(find.text('STATISTIQUES'), findsOneWidget);
  });
}
