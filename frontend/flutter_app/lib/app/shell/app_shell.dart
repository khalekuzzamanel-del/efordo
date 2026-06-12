import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/providers/auth_notifier.dart';
import '../../shared/providers/navigation_provider.dart';
import '../theme/app_spacing.dart';

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final location = GoRouterState.of(context).matchedLocation;

    // Sync navigation index with current route
    final navItems = [
      const _NavItem(Icons.dashboard_outlined, 'Dashboard', '/dashboard'),
      const _NavItem(Icons.folder_outlined, 'Projects', '/projects'),
      const _NavItem(Icons.task_alt_outlined, 'Tasks', '/tasks'),
      const _NavItem(Icons.settings_outlined, 'Settings', '/settings'),
    ];

    final currentIndex = navItems.indexWhere(
      (item) => location.startsWith(item.route),
    );
    final activeIndex = currentIndex >= 0 ? currentIndex : 0;

    // Update navigation provider to match current route
    ref.read(navigationIndexProvider.notifier).state = activeIndex;

    return Scaffold(
      appBar: AppBar(
        title: Text(navItems[activeIndex].label),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'logout') {
                  await ref.read(authNotifierProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  enabled: false,
                  child: SizedBox(
                    width: 200,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            authState.displayNameOrUsername.isNotEmpty
                                ? authState.displayNameOrUsername[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                authState.displayNameOrUsername,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                authState.email ?? '',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Logout'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    authState.displayNameOrUsername.isNotEmpty
                        ? authState.displayNameOrUsername[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: activeIndex,
        onDestinationSelected: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
          context.go(navItems[index].route);
        },
        destinations: navItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.icon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;

  const _NavItem(this.icon, this.label, this.route);
}
