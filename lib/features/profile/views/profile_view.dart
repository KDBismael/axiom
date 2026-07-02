import 'package:flutter/material.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('PROFILE'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const CircleAvatar(radius: 40, backgroundColor: Color(0xFF2A2A2A)),
                  const SizedBox(height: 12),
                  Text('Anonymous', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('Joined 2024', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text('STATS', style: theme.textTheme.bodyMedium?.copyWith(letterSpacing: 1)),
            const SizedBox(height: 16),
            _StatRow(label: 'Active Quests', value: '3'),
            _StatRow(label: 'Completed', value: '0'),
            _StatRow(label: 'Check-ins', value: '22'),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyLarge),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
