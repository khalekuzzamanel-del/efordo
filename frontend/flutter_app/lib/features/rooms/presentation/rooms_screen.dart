import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../domain/room.dart';
import '../providers/room_list_notifier.dart';
import 'create_room_sheet.dart';
import 'join_room_dialog.dart';
import 'room_details_screen.dart';

class RoomsScreen extends ConsumerStatefulWidget {
  const RoomsScreen({super.key});

  @override
  ConsumerState<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends ConsumerState<RoomsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(roomListProvider.notifier).load());
  }

  Future<void> _showCreateRoomSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const CreateRoomSheet(),
    );
    if (created == true && mounted) {
      ref.read(roomListProvider.notifier).load();
    }
  }

  Future<void> _showJoinRoomDialog() async {
    final joined = await showDialog<bool>(
      context: context,
      builder: (_) => const JoinRoomDialog(),
    );
    if (joined == true && mounted) {
      ref.read(roomListProvider.notifier).load();
    }
  }

  Future<void> _handleLeaveRoom(Room room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Room'),
        content: Text('Are you sure you want to leave "${room.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(roomListProvider.notifier).leave(room.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roomsAsync = ref.watch(roomListProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(roomListProvider.notifier).load(),
        child: roomsAsync.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => ErrorStateWidget(
            message: e.toString(),
            retryLabel: 'Retry',
            onRetry: () => ref.read(roomListProvider.notifier).load(),
          ),
          data: (rooms) {
            if (rooms.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 200),
                  EmptyStateWidget(
                    icon: Icons.meeting_room_outlined,
                    title: 'No rooms yet',
                    subtitle: 'Create a room or join one using an invite code',
                    actionLabel: 'Create Room',
                    onAction: _showCreateRoomSheet,
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: rooms.length,
              itemBuilder: (ctx, i) {
                final room = rooms[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    onTap: () async {
                      final shouldRefresh = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => RoomDetailsScreen(roomId: room.id),
                        ),
                      );
                      if (shouldRefresh == true && mounted) {
                        ref.read(roomListProvider.notifier).load();
                      }
                    },
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: room.isOwner
                            ? theme.colorScheme.primaryContainer
                            : room.isAdmin
                                ? theme.colorScheme.secondaryContainer
                                : theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          room.isOwner
                              ? Icons.star_rounded
                              : Icons.meeting_room_outlined,
                          color: room.isOwner
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      title: Text(
                        room.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${room.memberCount} member${room.memberCount == 1 ? '' : 's'}  •  ${room.roleLabel}',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'open':
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => RoomDetailsScreen(roomId: room.id),
                                ),
                              );
                            case 'leave':
                              _handleLeaveRoom(room);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'open',
                            child: ListTile(
                              leading: Icon(Icons.open_in_new),
                              title: Text('Open'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          if (!room.isOwner)
                            const PopupMenuItem(
                              value: 'leave',
                              child: ListTile(
                                leading: Icon(Icons.exit_to_app, color: Colors.red),
                                title: Text('Leave', style: TextStyle(color: Colors.red)),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'join_room',
            onPressed: _showJoinRoomDialog,
            child: const Icon(Icons.login_rounded),
          ),
          const SizedBox(height: AppSpacing.sm),
          FloatingActionButton(
            heroTag: 'create_room',
            onPressed: _showCreateRoomSheet,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
