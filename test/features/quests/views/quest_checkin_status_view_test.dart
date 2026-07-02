import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axiom/core/theme/app_theme.dart';
import 'package:axiom/features/quests/controllers/quest_list_controller.dart';
import 'package:axiom/features/quests/repositories/quest_repository.dart';
import 'package:axiom/features/quests/views/quest_checkin_status_view.dart';
import 'package:axiom/features/shell/controllers/shell_controller.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(Get.reset);

  testWidgets('renders the confirmation state for a real quest via GetX navigation', (
    tester,
  ) async {
    Get.put<QuestRepository>(QuestRepository());
    Get.put<ShellController>(ShellController());
    Get.put<QuestListController>(QuestListController());
    // Don't `await` loadQuests directly: the mock repository's
    // Future.delayed only fires once the widget test's fake clock is
    // advanced via `tester.pump` — awaiting it here hangs forever (see
    // [[getx-testwidgets-gotchas]] memory).

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.dark,
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const Scaffold()),
          GetPage(
            name: '/quest-checkin-status',
            page: () => const QuestCheckinStatusView(),
          ),
        ],
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
    Get.toNamed('/quest-checkin-status', arguments: '1');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    tester.takeException();

    expect(find.text("TERMINÉ POUR AUJOURD'HUI"), findsOneWidget);
    expect(
      find.text('Preuve soumise et en attente de validation par vos alliés.'),
      findsOneWidget,
    );
    expect(find.textContaining('SÉRIE :'), findsOneWidget);
    expect(find.text('TABLEAU DE BORD'), findsOneWidget);
  });
}
