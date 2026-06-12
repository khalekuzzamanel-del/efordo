import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SettingsSection(
          title: 'Appearance',
          children: [
            ListTile(
              leading: Icon(
                theme.brightness == Brightness.dark
                    ? Icons.dark_mode
                    : Icons.light_mode,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Theme'),
              subtitle: Text(
                theme.brightness == Brightness.dark
                    ? 'Dark Mode'
                    : 'Light Mode',
              ),
              trailing: Switch(
                value: theme.brightness == Brightness.dark,
                onChanged: (_) {
                  // Theme toggle placeholder
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _SettingsSection(
          title: 'Account',
          children: [
            ListTile(
              leading: Icon(
                Icons.person_outline,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Profile'),
              subtitle: const Text('Manage your account'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Profile placeholder
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withAlpha(60),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
