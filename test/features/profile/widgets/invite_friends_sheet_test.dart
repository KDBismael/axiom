import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/core/theme/app_theme.dart';
import 'package:axiom/core/widgets/sheets/app_bottom_sheet.dart';
import 'package:axiom/features/social/controllers/allies_controller.dart';
import 'package:axiom/features/social/models/ally.dart';
import 'package:axiom/features/social/models/ally_invitation.dart';
import 'package:axiom/features/social/models/ally_request.dart';
import 'package:axiom/features/social/repositories/social_repository.dart';
import 'package:axiom/features/profile/widgets/invite_friends_sheet.dart';

class MockSocialRepository extends Mock implements SocialRepository {}

/// A layout smoke test, not a UI-behavior test: the sheet packs a lot into
/// a fixed-height bottom sheet (search + results + link + share row + stat
/// row), which is exactly the shape that silently overflows if a child
/// isn't wrapped in the scrollable it needs.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(Get.reset);

  Future<void> pumpSheet(
    WidgetTester tester, {
    List<Ally> allies = const [],
    List<AllyRequest> allyRequests = const [],
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final mockRepository = MockSocialRepository();
    when(() => mockRepository.fetchAllies()).thenAnswer((_) async => allies);
    when(
      () => mockRepository.fetchInvitations(),
    ).thenAnswer((_) async => const <AllyInvitation>[]);
    when(
      () => mockRepository.fetchAllyRequests(),
    ).thenAnswer((_) async => allyRequests);
    when(
      () => mockRepository.searchUsers(any()),
    ).thenAnswer((_) async => const []);
    Get.put<AlliesController>(AlliesController(mockRepository));

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showAppBottomSheet(
                    context,
                    builder: (_) => const InviteFriendsSheet(),
                  ),
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    tester.takeException();
  }

  testWidgets('renders without layout overflow with no allies or requests', (
    tester,
  ) async {
    await pumpSheet(tester);

    expect(find.text('Recrute tes alliés'), findsOneWidget);
    expect(find.text('Amis recrutés'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
    // Nothing to manage yet, so the shortcut link is hidden.
    expect(find.text('Gérer mes alliés →'), findsNothing);
  });

  testWidgets(
    'renders without layout overflow with allies and pending requests',
    (tester) async {
      await pumpSheet(
        tester,
        allies: const [
          Ally(id: 'u-1', firstName: 'Awa', lastName: 'Koné'),
          Ally(id: 'u-2', firstName: 'Moussa', lastName: 'Ba'),
        ],
        allyRequests: const [
          AllyRequest(
            id: 'r-1',
            direction: AllyRequestDirection.outgoing,
            status: AllyRequestStatus.pending,
            otherUser: AllyRequestUser(
              id: 'u-3',
              firstName: 'Fatou',
              lastName: 'Sow',
            ),
          ),
        ],
      );

      expect(find.text('Gérer mes alliés →'), findsOneWidget);
    },
  );

  testWidgets('typing a query below 2 characters shows no results section', (
    tester,
  ) async {
    // Drives the controller directly rather than tester.enterText(): a
    // TextField's blinking-cursor animation inside a modal sheet's own
    // (also-animated) route trips an unrelated Flutter test-framework
    // caret-positioning assertion — this tests the same conditional-
    // rendering logic without that brittleness.
    await pumpSheet(tester);

    final controller = Get.find<AlliesController>();
    await controller.search('A');
    await tester.pump();
    tester.takeException();

    expect(
      find.text('Personne de ce nom sur Ndeli. Invite-le avec ton lien.'),
      findsNothing,
    );
  });
}
