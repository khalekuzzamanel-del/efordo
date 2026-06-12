import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/empty_state_widget.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const EmptyStateWidget(
      icon: Icons.task_alt_outlined,
      title: 'Tasks',
      subtitle: 'Tasks module coming soon.',
    );
  }
}
