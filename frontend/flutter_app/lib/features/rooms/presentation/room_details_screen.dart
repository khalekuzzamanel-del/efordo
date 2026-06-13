import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../chat/presentation/room_chat_screen.dart';
import '../data/room_api_service.dart';
import '../domain/room.dart';
import '../domain/room_member.dart';
import '../providers/member_notifier.dart';
import '../providers/room_details_notifier.dart';
import '../providers/room_list_notifier.dart';

class RoomDetailsScreen extends ConsumerStatefulWidget {
  final String roomId;

  const RoomDetailsScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends ConsumerState<RoomDetailsScreen> {
  bool _shouldRefreshParent = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(roomDetailsProvider(widget.roomId).notifier).load();
      await ref.read(memberProvider(widget.roomId).notifier).load();
    });
  }

  Future<void> _showEditRoomSheet(Room room) async {
    final nameController = TextEditingController(text: room.name);
    final descController = TextEditingController(text: room.description ?? '');
    final formKey = GlobalKey<FormState>();

    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Edit Room',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Room Name',
                  prefixIcon: Icon(Icons.meeting_room_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final data = <String, dynamic>{
                    'name': nameController.text.trim(),
                  };
                  if (descController.text.trim().isNotEmpty) {
                    data['description'] = descController.text.trim();
                  }
                  final success = await ref
                      .read(roomDetailsProvider(widget.roomId).notifier)
                      .update(data);
                  if (success && ctx.mounted) {
                    Navigator.of(ctx).pop(true);
                  }
                },
                child: const Text('Save'),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );

    if (updated == true && mounted) {
      ref.read(roomDetailsProvider(widget.roomId).notifier).load();
      _shouldRefreshParent = true;
    }
  }

  Future<void> _handleDeleteRoom() async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Room',
      message: 'Delete this room permanently? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true) {
      final success =
          await ref.read(roomDetailsProvider(widget.roomId).notifier).delete();
      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _handleLeaveRoom() async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Leave Room',
      message: 'Are you sure you want to leave this room?',
      confirmLabel: 'Leave',
      isDestructive: true,
    );
    if (confirmed == true && mounted) {
      await ref.read(roomListProvider.notifier).leave(widget.roomId);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  Future<void> _handlePromote(RoomMember member) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Promote to Admin',
      message: 'Promote ${member.displayNameOrUsername} to admin?',
      confirmLabel: 'Promote',
    );
    if (confirmed == true) {
      await ref.read(memberProvider(widget.roomId).notifier).promote(member.userId);
    }
  }

  Future<void> _handleDemote(RoomMember member) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Demote to Member',
      message: 'Demote ${member.displayNameOrUsername} to member?',
      confirmLabel: 'Demote',
      isDestructive: true,
    );
    if (confirmed == true) {
      await ref.read(memberProvider(widget.roomId).notifier).demote(member.userId);
    }
  }

  Future<void> _handleRemoveMember(RoomMember member) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Remove Member',
      message: 'Remove ${member.displayNameOrUsername} from this room?',
      confirmLabel: 'Remove',
      isDestructive: true,
    );
    if (confirmed == true) {
      await ref.read(memberProvider(widget.roomId).notifier).remove(member.userId);
    }
  }

  Future<void> _showTransferOwnershipDialog(List<RoomMember> members) async {
    final nonOwnerMembers =
        members.where((m) => !m.isOwner).toList();

    if (nonOwnerMembers.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No other members to transfer ownership to'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final selected = await showDialog<RoomMember>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Transfer Ownership'),
        children: nonOwnerMembers
            .map((m) => SimpleDialogOption(
                  onPressed: () => Navigator.of(ctx).pop(m),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        m.displayNameOrUsername[0].toUpperCase(),
                      ),
                    ),
                    title: Text(m.displayNameOrUsername),
                    subtitle: Text(m.roleLabel),
                    contentPadding: EdgeInsets.zero,
                  ),
                ))
            .toList(),
      ),
    );

    if (selected != null && mounted) {
      final confirmed = await showConfirmationDialog(
        context,
        title: 'Transfer Ownership',
        message:
            'Transfer ownership to ${selected.displayNameOrUsername}? You will become an admin.',
        confirmLabel: 'Transfer',
      );
      if (confirmed == true) {
        try {
          final apiService = ref.read(roomApiServiceProvider);
          await apiService.transferOwnership(widget.roomId, selected.userId);
          if (mounted) {
            await ref.read(roomDetailsProvider(widget.roomId).notifier).load();
            await ref.read(memberProvider(widget.roomId).notifier).load();
            _shouldRefreshParent = true;
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to transfer ownership: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roomAsync = ref.watch(roomDetailsProvider(widget.roomId));
    final membersAsync = ref.watch(memberProvider(widget.roomId));

    return roomAsync.when(
      loading: () => const Scaffold(
        body: LoadingWidget(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorStateWidget(
          message: e.toString(),
          retryLabel: 'Retry',
          onRetry: () =>
              ref.read(roomDetailsProvider(widget.roomId).notifier).load(),
        ),
      ),
      data: (room) {
        if (room == null) {
          return const Scaffold(
            body: ErrorStateWidget(message: 'Room not found'),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(room.name),
            actions: [
              if (room.isOwnerOrAdmin)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditRoomSheet(room);
                      case 'delete':
                        _handleDeleteRoom();
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit Room'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (room.isOwner)
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_forever, color: Colors.red),
                          title:
                              Text('Delete Room', style: TextStyle(color: Colors.red)),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await ref.read(roomDetailsProvider(widget.roomId).notifier).load();
              await ref.read(memberProvider(widget.roomId).notifier).load();
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Room info card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  room.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (room.description != null &&
                                    room.description!.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    room.description!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: room.isOwner
                                  ? theme.colorScheme.primaryContainer
                                  : room.isAdmin
                                      ? theme.colorScheme.secondaryContainer
                                      : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              room.roleLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: room.isOwner
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Divider(),
                      const SizedBox(height: AppSpacing.sm),
                      // Invite code section
                      Row(
                        children: [
                          const Icon(Icons.vpn_key_outlined, size: 18),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Invite Code: ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            room.inviteCode,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                              letterSpacing: 1.5,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            tooltip: 'Copy invite code',
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: room.inviteCode),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invite code copied!'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          if (room.isOwnerOrAdmin)
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 18),
                              tooltip: 'Regenerate invite code',
                              onPressed: () async {
                                final confirmed = await showConfirmationDialog(
                                  context,
                                  title: 'Regenerate Code',
                                  message:
                                      'Generate a new invite code? The old code will stop working.',
                                  confirmLabel: 'Regenerate',
                                );
                                if (confirmed == true && mounted) {
                                  await ref
                                      .read(roomDetailsProvider(widget.roomId)
                                          .notifier)
                                      .regenerateInviteCode();
                                }
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Chat button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RoomChatScreen(
                            roomId: widget.roomId,
                            roomName: room.name,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Open Chat'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Actions section
                if (!room.isOwner)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _handleLeaveRoom,
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text('Leave Room'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ),

                // Members section
                const SectionHeader(
                  title: 'Members',
                  subtitle: 'Everyone in this room',
                ),
                membersAsync.when(
                  loading: () => const LoadingWidget(),
                  error: (e, _) => ErrorStateWidget(
                    message: e.toString(),
                    retryLabel: 'Retry',
                    onRetry: () =>
                        ref.read(memberProvider(widget.roomId).notifier).load(),
                  ),
                  data: (members) => Column(
                    children: members.map((member) {
                      final isCurrentUser =
                          member.userId == ref.read(roomListProvider).valueOrNull
                                  ?.where((r) => r.id == widget.roomId)
                                  .firstOrNull
                                  ?.createdBy;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AppCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: member.isOwner
                                  ? theme.colorScheme.primaryContainer
                                  : member.isAdmin
                                      ? theme.colorScheme.secondaryContainer
                                      : theme.colorScheme.surfaceContainerHighest,
                              child: Text(
                                member.displayNameOrUsername[0].toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: member.isOwner
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  member.displayNameOrUsername,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (isCurrentUser)
                                  Text(
                                    ' (you)',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              member.roleLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: member.isOwner
                                    ? theme.colorScheme.primary
                                    : member.isAdmin
                                        ? theme.colorScheme.secondary
                                        : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: room.isOwner && !member.isOwner
                                ? PopupMenuButton<String>(
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'promote':
                                          _handlePromote(member);
                                        case 'demote':
                                          _handleDemote(member);
                                        case 'remove':
                                          _handleRemoveMember(member);
                                        case 'transfer':
                                          _showTransferOwnershipDialog(members);
                                      }
                                    },
                                    itemBuilder: (ctx) {
                                      final items = <PopupMenuEntry<String>>[];
                                      if (member.isAdmin) {
                                        items.add(const PopupMenuItem(
                                          value: 'demote',
                                          child: ListTile(
                                            leading: Icon(Icons.arrow_downward),
                                            title: Text('Demote to Member'),
                                            dense: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ));
                                      } else {
                                        items.add(const PopupMenuItem(
                                          value: 'promote',
                                          child: ListTile(
                                            leading: Icon(Icons.arrow_upward),
                                            title: Text('Promote to Admin'),
                                            dense: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ));
                                      }
                                      items.add(const PopupMenuDivider());
                                      items.add(const PopupMenuItem(
                                        value: 'transfer',
                                        child: ListTile(
                                          leading: Icon(Icons.swap_horiz),
                                          title: Text('Transfer Ownership'),
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ));
                                      items.add(const PopupMenuDivider());
                                      items.add(const PopupMenuItem(
                                        value: 'remove',
                                        child: ListTile(
                                          leading: Icon(Icons.remove_circle_outline,
                                              color: Colors.red),
                                          title: Text('Remove',
                                              style: TextStyle(color: Colors.red)),
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ));
                                      return items;
                                    },
                                  )
                                : (room.isAdmin && !member.isOwner && !member.isAdmin
                                    ? PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'remove') {
                                            _handleRemoveMember(member);
                                          }
                                        },
                                        itemBuilder: (ctx) => [
                                          const PopupMenuItem(
                                            value: 'remove',
                                            child: ListTile(
                                              leading: Icon(Icons.remove_circle_outline,
                                                  color: Colors.red),
                                              title: Text('Remove',
                                                  style:
                                                      TextStyle(color: Colors.red)),
                                              dense: true,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink()),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        );
      },
    );
  }
}
