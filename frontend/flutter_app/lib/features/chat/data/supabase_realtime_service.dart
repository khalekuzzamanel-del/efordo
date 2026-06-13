import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

import '../../authentication/providers/auth_state.dart';
import '../domain/message.dart';

final supabaseRealtimeServiceProvider = Provider<SupabaseRealtimeService>((ref) {
  return SupabaseRealtimeService();
});

class SupabaseRealtimeService {
  SupabaseClient? _client;

  /// Initialize Supabase client with the user's JWT token
  void initialize(String accessToken) {
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (supabaseUrl.isEmpty || anonKey.isEmpty) {
      // If SUPABASE_URL is not in Flutter .env, try to derive from API URL
      // Or we can just skip Realtime initialization
      return;
    }

    _client = SupabaseClient(
      supabaseUrl,
      anonKey,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'apikey': anonKey,
      },
    );
  }

  /// Subscribe to new messages in a room
  RealtimeChannel subscribeToRoom(
    String roomId,
    void Function(Message message) onNewMessage,
  ) {
    final client = _client;
    if (client == null) {
      // Return a no-op channel if not initialized
      return _noOpChannel();
    }

    final channel = client.channel('room-messages-$roomId');

    channel.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'INSERT',
        schema: 'public',
        table: 'messages',
        filter: 'room_id=eq.$roomId',
      ),
      (payload, [ref]) {
        final newMessage = Message.fromJson(payload['new'] as Map<String, dynamic>);
        onNewMessage(newMessage);
      },
    ).subscribe();

    return channel;
  }

  /// Clean up subscription
  void unsubscribe(RealtimeChannel channel) {
    channel.unsubscribe();
  }

  /// Dispose the client
  void dispose() {
    _client?.dispose();
    _client = null;
  }

  RealtimeChannel _noOpChannel() {
    return _client?.channel('noop') ?? RealtimeChannel('noop', const <String, dynamic>{});
  }
}
