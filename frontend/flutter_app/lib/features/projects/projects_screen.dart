import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/empty_state_widget.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const EmptyStateWidget(
      icon: Icons.folder_outlined,
      title: 'Projects',
      subtitle: 'Projects module coming soon.',
    );
  }
}
