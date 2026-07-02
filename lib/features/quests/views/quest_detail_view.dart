import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/quest_list_controller.dart';
import '../models/quest_model.dart';

class QuestDetailView extends GetView<QuestListController> {
  const QuestDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final String questId = Get.arguments as String;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('QUEST'),
      ),
      body: Obx(() {
        final quest = controller.findById(questId);
        if (quest == null) {
          return const Center(child: Text('Quest not found.'));
        }
        return _QuestDetailBody(quest: quest);
      }),
    );
  }
}

class _QuestDetailBody extends GetView<QuestListController> {
  final QuestModel quest;
  const _QuestDetailBody({required this.quest});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(quest.title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '${quest.durationDays} days · ${quest.frequency.name}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          _ProgressSection(quest: quest),
          const Spacer(),
          _CheckInButton(quest: quest),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {},
            child: const Text('INVITE FRIENDS'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final QuestModel quest;
  const _ProgressSection({required this.quest});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('PROGRESS', style: theme.textTheme.bodyMedium?.copyWith(letterSpacing: 1)),
            Text(
              '${quest.progress} / ${quest.total}',
              style: theme.textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: quest.progressRatio,
            backgroundColor: const Color(0xFF2A2A2A),
            color: const Color(0xFFD4AF37),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(quest.progressRatio * 100).toStringAsFixed(0)}% complete',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _CheckInButton extends GetView<QuestListController> {
  final QuestModel quest;
  const _CheckInButton({required this.quest});

  @override
  Widget build(BuildContext context) {
    if (quest.isComplete) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD4AF37)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: Text(
            'QUEST COMPLETE',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
      );
    }
    return ElevatedButton(
      onPressed: () => controller.checkIn(quest.id),
      child: const Text('CHECK IN'),
    );
  }
}
