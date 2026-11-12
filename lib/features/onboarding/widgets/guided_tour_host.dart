import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../quests/controllers/quest_list_controller.dart';
import '../controllers/guided_tour_controller.dart';
import 'first_quest_sheet.dart';
import 'guided_tour_keys.dart';
import 'tour_bubble.dart';

/// Invisible widget on the home screen that shows the guided tour's
/// bubbles when [GuidedTourController.step] asks for one.
class GuidedTourHost extends StatefulWidget {
  const GuidedTourHost({super.key});

  @override
  State<GuidedTourHost> createState() => _GuidedTourHostState();
}

class _GuidedTourHostState extends State<GuidedTourHost> {
  final _tour = Get.find<GuidedTourController>();
  final _quests = Get.find<QuestListController>();
  final _workers = <Worker>[];
  GuidedTourStep? _shown;

  @override
  void initState() {
    super.initState();
    _workers
      ..add(ever<bool>(_quests.isLoading, (_) => _evaluate()))
      ..add(ever<GuidedTourStep>(_tour.step, (_) => _scheduleBubble()));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evaluate();
      _scheduleBubble();
    });
  }

  void _evaluate() {
    // A failed load would make an existing user look brand new.
    if (!_quests.isLoading.value && _quests.errorMessage.value == null) {
      _tour.evaluate();
    }
  }

  void _scheduleBubble() {
    // Let the route transition and list layout settle before measuring
    // the target.
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _showBubble(_tour.step.value);
    });
  }

  Future<void> _showBubble(GuidedTourStep step, {int retries = 30}) async {
    if (step == _shown || step != _tour.step.value) return;
    if (ModalRoute.of(context)?.isCurrent != true) {
      // A dialog (e.g. the notification explanation) or another screen is
      // on top: try again once the home screen is back in front.
      if (retries > 0) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _showBubble(step, retries: retries - 1);
        });
      }
      return;
    }
    final key = switch (step) {
      GuidedTourStep.createQuest => GuidedTourKeys.newQuestButton,
      GuidedTourStep.checkIn => GuidedTourKeys.firstQuestCard,
      _ => null,
    };
    final targetContext = key?.currentContext;
    if (key == null || targetContext == null) return;
    // Never spotlight something that isn't laid out on screen.
    final box = targetContext.findRenderObject();
    if (box is! RenderBox || !box.hasSize || box.size.isEmpty) return;
    _shown = step;
    await Scrollable.ensureVisible(
      targetContext,
      alignment: 0.5,
      duration: const Duration(milliseconds: 300),
    );
    // Cards above the target (rank, stakes) load asynchronously and push
    // it down; spotlighting too early lights up the wrong card.
    await _waitForStablePosition(key);
    if (!mounted) return;

    late final TutorialCoachMark coachMark;
    final isCreate = step == GuidedTourStep.createQuest;
    coachMark = TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: step.name,
          keyTarget: key,
          shape: ShapeLightFocus.RRect,
          radius: 16,
          enableOverlayTab: false,
          contents: [
            TargetContent(
              align: isCreate ? ContentAlign.top : ContentAlign.bottom,
              builder: (_, _) => isCreate
                  ? const TourBubble(
                      step: 'ÉTAPE 1/3',
                      title: 'Crée ta première quête',
                      body:
                          'Un objectif simple, que tu tiens chaque jour ou '
                          'chaque semaine. Touche le bouton pour choisir.',
                    )
                  : TourBubble(
                      step: 'ÉTAPE 3/3',
                      title: 'Valide chaque jour ici',
                      body:
                          'Quand tu as fait ta part, touche « VALIDER » sur '
                          'ta quête. Chaque validation fait grandir ta série.',
                      actionLabel: 'COMPRIS',
                      onAction: () => coachMark.finish(),
                    ),
            ),
          ],
        ),
      ],
      colorShadow: AppColors.surfaceContainerLowest,
      opacityShadow: 0.88,
      paddingFocus: 6,
      // Top-right keeps it clear of the bottom tab bar; its own pill keeps
      // it legible over whatever card sits underneath.
      alignSkip: Alignment.topRight,
      skipWidget: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outlineVariantStrong),
        ),
        child: Text(
          'PASSER LE GUIDE',
          style: AppTypography.labelMd.copyWith(color: AppColors.primary),
        ),
      ),
      onSkip: () {
        _tour.finish();
        return true;
      },
      onClickTarget: (_) {
        if (isCreate) {
          showFirstQuestSheet(context).then((_) {
            // Sheet closed without picking (back / swipe down): bring the
            // bubble back rather than leaving the user with no guide.
            if (mounted && _tour.step.value == GuidedTourStep.createQuest) {
              _shown = null;
              _scheduleBubble();
            }
          });
        } else {
          // The bubble says "touche VALIDER": do exactly that.
          _tour.finish();
          final quests = _quests.activeQuests;
          if (quests.isNotEmpty) {
            Get.toNamed(AppRoutes.questValidation, arguments: quests.first.id);
          }
        }
      },
      onFinish: () {
        if (!isCreate) _tour.finish();
      },
    );
    coachMark.show(context: context);
  }

  Future<void> _waitForStablePosition(GlobalKey key) async {
    Offset? last;
    for (var i = 0; i < 10; i++) {
      final box = key.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached) return;
      final position = box.localToGlobal(Offset.zero);
      if (position == last) return;
      last = position;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  @override
  void dispose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
