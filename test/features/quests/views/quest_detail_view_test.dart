import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axiom/core/theme/app_theme.dart';
import 'package:axiom/features/quests/controllers/quest_list_controller.dart';
import 'package:axiom/features/quests/repositories/quest_repository.dart';
import 'package:axiom/features/quests/views/quest_detail_view.dart';
import 'package:axiom/features/shell/controllers/shell_controller.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(Get.reset);

  testWidgets('QuestDetailView renders full quest detail via real GetX navigation', (
    tester,
  ) async {
    Get.put<QuestRepository>(QuestRepository());
    Get.put<ShellController>(ShellController());
    final controller = Get.put<QuestListController>(QuestListController());
    // Don't `await` here: the mock repository's Future.delayed only fires
    // once the widget test's fake clock is advanced via `tester.pump`.
    // Awaiting it directly hangs forever (caught the hard way — a prior
    // run of this test timed out after 10 minutes).
    unawaited(controller.loadQuests());

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.dark,
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const Scaffold()),
          GetPage(name: '/quest-detail', page: () => const QuestDetailView()),
        ],
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
    Get.toNamed('/quest-detail', arguments: '1');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    tester.takeException();

    expect(find.text('Salle de sport 3x/semaine'), findsOneWidget);
    expect(find.text('VALIDER AVEC PREUVE'), findsOneWidget);
    expect(find.text('LES ENJEUX'), findsOneWidget);
    expect(find.text('LE PACTE'), findsOneWidget);
    expect(find.text('STATUT DES ALLIÉS'), findsOneWidget);
    expect(find.textContaining('REGISTRE D\'INTÉGRITÉ'), findsOneWidget);
    expect(find.text('PARAMÈTRES OPÉRATIONNELS'), findsOneWidget);
  });
}
