import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/core/theme/app_theme.dart';
import 'package:axiom/features/social/controllers/allies_controller.dart';
import 'package:axiom/features/social/repositories/social_repository.dart';
import 'package:axiom/features/social/views/invitation_ally_view.dart';

class MockSocialRepository extends Mock implements SocialRepository {}

/// A layout smoke test: confirms the full scroll extent lays out without a
/// RenderFlex/overflow error.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(Get.reset);

  testWidgets('renders without layout overflow across its full scroll extent', (
    tester,
  ) async {
    final mockRepository = MockSocialRepository();
    when(() => mockRepository.fetchAllies()).thenAnswer((_) async => []);
    when(() => mockRepository.fetchInvitations()).thenAnswer((_) async => []);
    when(() => mockRepository.fetchAllyRequests()).thenAnswer((_) async => []);
    Get.put<AlliesController>(AlliesController(mockRepository));

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.dark,
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const Scaffold()),
          GetPage(name: '/invitation', page: () => const InvitationAllyView()),
        ],
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
    Get.toNamed('/invitation', arguments: 'tok-abc');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    tester.takeException();

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
    await tester.pump();
    tester.takeException();

    expect(find.text('DEVENIR ALLIÉ'), findsOneWidget);
    expect(find.text('ACCEPTER LE PACTE'), findsOneWidget);
  });
}
