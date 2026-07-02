import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/quest_list_controller.dart';
import '../models/quest_model.dart';
import '../../../core/routes/app_routes.dart';

class QuestListView extends GetView<QuestListController> {
  const QuestListView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AXIOM'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Get.toNamed(AppRoutes.profile),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 1));
        }
        if (controller.quests.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('No active quests.', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('CREATE QUEST'),
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: controller.quests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) => _QuestCard(quest: controller.quests[index]),
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: Colors.black,
        elevation: 0,
        child: const Icon(Icons.add),
        onPressed: () {},
      ),
    );
  }
}

class _QuestCard extends GetView<QuestListController> {
  final QuestModel quest;
  const _QuestCard({required this.quest});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.questDetail, arguments: quest.id),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(quest.title, style: theme.textTheme.titleMedium),
                ),
                if (quest.hasStake)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD4AF37)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Text(
                      'STAKE',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: quest.progressRatio,
                      backgroundColor: const Color(0xFF2A2A2A),
                      color: const Color(0xFFD4AF37),
                      minHeight: 3,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${quest.progress}/${quest.total}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${quest.durationDays}d · ${quest.frequency.name}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
