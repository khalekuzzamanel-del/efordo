import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/providers/auth_notifier.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../domain/message.dart';
import '../providers/chat_notifier.dart';

class RoomChatScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String roomName;

  const RoomChatScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  ConsumerState<RoomChatScreen> createState() => _RoomChatScreenState();
}

class _RoomChatScreenState extends ConsumerState<RoomChatScreen> {
  final _scrollController = ScrollController();
  final _messageController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSending = false;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(chatProvider(widget.roomId).notifier).loadInitial());

    _scrollController.addListener(() {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      // Show scroll-to-bottom button when scrolled up more than 200px
      final shouldShow = currentScroll < maxScroll - 200;
      if (shouldShow != _showScrollToBottom) {
        setState(() => _showScrollToBottom = shouldShow);
      }

      // Load more when reaching the top
      if (currentScroll <= 50 && !_isSending) {
        ref.read(chatProvider(widget.roomId).notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text;
    if (text.trim().isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    final notifier = ref.read(chatProvider(widget.roomId).notifier);
    final success = await notifier.sendMessage(text);

    if (mounted) {
      setState(() => _isSending = false);
      if (success) {
        _scrollToBottom();
      } else {
        _messageController.text = text;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to send. Tap to retry.'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                notifier.sendMessage(text);
              },
            ),
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(String createdAt) {
    final dt = DateTime.parse(createdAt).toLocal();
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messagesAsync = ref.watch(chatProvider(widget.roomId));
    final chatNotifier = ref.read(chatProvider(widget.roomId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.roomName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              'Chat',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Pending messages banner
          if (chatNotifier.pendingMessages.isNotEmpty)
            _PendingMessagesBanner(
              pendingMessages: chatNotifier.pendingMessages,
              onRetry: (index) => chatNotifier.retryPending(index),
              onDismiss: (index) => chatNotifier.removePending(index),
            ),

          // Message list
          Expanded(
            child: Stack(
              children: [
                messagesAsync.when(
                  loading: () => const LoadingWidget(message: 'Loading messages...'),
                  error: (e, _) => ErrorStateWidget(
                    message: e.toString(),
                    retryLabel: 'Retry',
                    onRetry: () =>
                        ref.read(chatProvider(widget.roomId).notifier).loadInitial(),
                  ),
                  data: (messages) {
                    if (messages.isEmpty) {
                      return ListView(
                        children: const [
                          SizedBox(height: 200),
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No messages yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Start the conversation!',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return GestureDetector(
                      onTap: () => _focusNode.unfocus(),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.sm,
                        ),
                        // Messages are in reverse chronological order (newest first)
                        // We display them reversed so newest is at bottom
                        itemCount: messages.length + (chatNotifier.isLoadingMore ? 1 : 0),
                        itemBuilder: (ctx, index) {
                          // Loading indicator at the LAST index (rendered at the top with reverse: true)
                          if (chatNotifier.isLoadingMore && index == messages.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )),
                            );
                          }

                          final message = messages[index];
                          final isOwn = message.senderId == 'me' ||
                              message.senderId ==
                                  (ref.read(authNotifierProvider).userId ?? '');
                          final isPending = message.id.startsWith('pending-');

                          // Check if we should show the date header
                          final showDateHeader = index == messages.length - 1 ||
                              !_isSameDay(
                                messages[index].dateTime,
                                messages[index + 1].dateTime,
                              );

                          return Column(
                            children: [
                              if (showDateHeader)
                                _DateHeader(date: message.dateTime),
                              _MessageBubble(
                                message: message,
                                isOwn: isOwn,
                                isPending: isPending,
                                onRetry: () =>
                                    chatNotifier.sendMessage(message.content),
                              ),
                            ],
                          );
                        },
                        reverse: true,
                      ),
                    );
                  },
                ),

                // Scroll to bottom button
                if (_showScrollToBottom)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton.small(
                      heroTag: 'scroll_to_bottom',
                      onPressed: _scrollToBottom,
                      child: const Icon(Icons.arrow_downward),
                    ),
                  ),
              ],
            ),
          ),

          // Message composer
          _MessageComposer(
            controller: _messageController,
            focusNode: _focusNode,
            isSending: _isSending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// --- Message Bubble Widget ---

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isOwn;
  final bool isPending;
  final VoidCallback? onRetry;

  const _MessageBubble({
    required this.message,
    required this.isOwn,
    this.isPending = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isOwn ? 16 : 4),
      bottomRight: Radius.circular(isOwn ? 4 : 16),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwn) ...[
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isOwn
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: borderRadius,
              ),
              child: Column(
                crossAxisAlignment:
                    isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isOwn)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.senderName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: isOwn
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isOwn
                              ? theme.colorScheme.onPrimary.withAlpha(180)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (isPending) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: isOwn
                              ? theme.colorScheme.onPrimary.withAlpha(180)
                              : theme.colorScheme.error,
                        ),
                      ],
                      if (onRetry != null && isPending) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: onRetry,
                          child: Icon(
                            Icons.refresh,
                            size: 14,
                            color: isOwn
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isOwn) ...[
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  String _formatTime(String createdAt) {
    final dt = DateTime.parse(createdAt).toLocal();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// --- Date Header Widget ---

class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(date.year, date.month, date.day);
    final diff = today.difference(msgDate).inDays;

    String label;
    if (diff == 0) {
      label = 'Today';
    } else if (diff == 1) {
      label = 'Yesterday';
    } else if (diff < 7) {
      label = '${date.month}/${date.day}';
    } else {
      label = '${date.month}/${date.day}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(150),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// --- Pending Messages Banner ---

class _PendingMessagesBanner extends StatelessWidget {
  final List<PendingMessage> pendingMessages;
  final Function(int) onRetry;
  final Function(int) onDismiss;

  const _PendingMessagesBanner({
    required this.pendingMessages,
    required this.onRetry,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.errorContainer.withAlpha(180),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${pendingMessages.length} message${pendingMessages.length == 1 ? '' : 's'} failed to send',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              for (var i = pendingMessages.length - 1; i >= 0; i--) {
                onRetry(i);
              }
            },
            child: const Text('Retry All', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// --- Message Composer Widget ---

class _MessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback onSend;

  const _MessageComposer({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(80),
          ),
        ),
      ),
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.newline,
              minLines: 1,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(bottom: 0),
            child: IconButton(
              onPressed: isSending ? null : onSend,
              icon: isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.send_rounded,
                      color: theme.colorScheme.primary,
                    ),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primaryContainer,
                shape: const CircleBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
