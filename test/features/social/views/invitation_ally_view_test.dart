import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:axiom/core/theme/app_theme.dart';
import 'package:axiom/features/social/controllers/social_controller.dart';
import 'package:axiom/features/social/repositories/social_repository.dart';
import 'package:axiom/features/social/views/invitation_ally_view.dart';

/// A layout smoke test: confirms the full scroll extent lays out without a
/// RenderFlex/overflow error, since this screen has dynamic text (inviter
/// name, quest title) that could overflow.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(Get.reset);

  testWidgets('renders without layout overflow across its full scroll extent', (
    tester,
  ) async {
    Get.put<SocialRepository>(SocialRepository());
    Get.put<SocialController>(SocialController());

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.dark, home: const Scaffold(body: InvitationAllyView())),
    );
    await tester.pump(const Duration(milliseconds: 350));
    tester.takeException();

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
    await tester.pump();
    tester.takeException();

    expect(find.text('REJOINDRE LA MISSION'), findsOneWidget);
    expect(find.text('ACCEPTER LE PACTE'), findsOneWidget);
  });
}
