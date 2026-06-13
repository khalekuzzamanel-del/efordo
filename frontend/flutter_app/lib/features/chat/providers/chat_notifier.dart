import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

import '../../authentication/providers/auth_notifier.dart';
import '../data/chat_api_service.dart';
import '../data/supabase_realtime_service.dart';
import '../domain/message.dart';

// Provider with roomId as family parameter
final chatProvider =
    StateNotifierProvider.family<ChatNotifier, AsyncValue<List<Message>>, String>(
  (ref, roomId) {
    return ChatNotifier(
      ref.read(chatApiServiceProvider),
      ref.read(supabaseRealtimeServiceProvider),
      roomId,
      ref,
    );
  },
);

class ChatNotifier extends StateNotifier<AsyncValue<List<Message>>> {
  final ChatApiService _api;
  final SupabaseRealtimeService _realtime;
  final String _roomId;
  final Ref _ref;

  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final Set<String> _seenIds = {};
  RealtimeChannel? _channel;

  // Pending messages that failed to send
  final List<PendingMessage> _pendingMessages = [];

  ChatNotifier(this._api, this._realtime, this._roomId, this._ref)
      : super(const AsyncValue.loading()) {
    _initRealtime();
  }

  void _initRealtime() {
    // Try to get auth token and initialize realtime
    final authState = _ref.read(authNotifierProvider);
    if (authState.accessToken != null) {
      _realtime.initialize(authState.accessToken!);
      _subscribe();
    }

    // Listen for auth state changes to reinitialize
    _ref.listen(authNotifierProvider, (previous, next) {
      if (next.accessToken != null && _channel == null) {
        _realtime.initialize(next.accessToken!);
        _subscribe();
      }
    });
  }

  void _subscribe() {
    _channel = _realtime.subscribeToRoom(_roomId, (message) {
      if (mounted && !_seenIds.contains(message.id)) {
        _seenIds.add(message.id);
        state = state.whenData((messages) => [message, ...messages]);
      }
    });
  }

  Future<void> loadInitial() async {
    _currentPage = 1;
    _hasMore = true;
    state = const AsyncValue.loading();
    await _loadMessages();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    _currentPage++;
    await _loadMessages(isLoadMore: true);
    _isLoadingMore = false;
  }

  Future<void> _loadMessages({bool isLoadMore = false}) async {
    try {
      final result = await _api.getMessages(
        _roomId,
        page: _currentPage,
        limit: 50,
      );
      final messages = (result['data'] as List)
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList();

      _totalPages = result['total_pages'] as int? ?? 1;
      _hasMore = _currentPage < _totalPages;

      // Track seen IDs for deduplication
      for (final msg in messages) {
        _seenIds.add(msg.id);
      }

      if (isLoadMore) {
        state = state.whenData((existing) => [...existing, ...messages]);
      } else {
        state = AsyncValue.data(messages);
      }
    } catch (e, st) {
      if (isLoadMore) {
        _currentPage--; // Rollback page on error
      }
      if (!isLoadMore) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<bool> sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return false;

    // Optimistic: append message immediately
    final tempId = 'pending-${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = Message(
      id: tempId,
      roomId: _roomId,
      senderId: 'me',
      content: trimmed,
      createdAt: DateTime.now().toIso8601String(),
      senderUsername: 'You',
    );

    state = state.whenData((messages) => [optimistic, ...messages]);

    try {
      final sent = await _api.sendMessage(_roomId, trimmed);
      _seenIds.add(sent.id);
      // Replace optimistic message with real one
      state = state.whenData((messages) =>
          messages.map((m) => m.id == tempId ? sent : m).toList());
      return true;
    } catch (e) {
      // Remove optimistic message
      state = state.whenData((messages) =>
          messages.where((m) => m.id != tempId).toList());
      // Add to pending for retry
      _pendingMessages.add(PendingMessage(content: trimmed, createdAt: DateTime.now()));
      return false;
    }
  }

  Future<void> retryPending(int index) async {
    if (index < 0 || index >= _pendingMessages.length) return;
    final pending = _pendingMessages[index];
    _pendingMessages.removeAt(index);
    await sendMessage(pending.content);
  }

  void removePending(int index) {
    if (index >= 0 && index < _pendingMessages.length) {
      _pendingMessages.removeAt(index);
    }
  }

  List<PendingMessage> get pendingMessages => List.unmodifiable(_pendingMessages);

  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  @override
  void dispose() {
    if (_channel != null) {
      _realtime.unsubscribe(_channel!);
    }
    super.dispose();
  }
}

class PendingMessage {
  final String content;
  final DateTime createdAt;

  PendingMessage({required this.content, required this.createdAt});
}
