import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class RealtimeService {
  RealtimeService._();

  static SupabaseClient get _client => SupabaseService.client;

  /// Subscribe to real-time changes on a table
  static RealtimeChannel subscribeToTable({
    required String table,
    required void Function(PostgresChangePayload payload) onInsert,
    void Function(PostgresChangePayload payload)? onUpdate,
    void Function(PostgresChangePayload payload)? onDelete,
  }) {
    var channel = _client.channel('public:$table');

    channel = channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: table,
      callback: onInsert,
    );

    if (onUpdate != null) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: table,
        callback: onUpdate,
      );
    }

    if (onDelete != null) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: table,
        callback: onDelete,
      );
    }

    channel.subscribe();
    return channel;
  }

  static void unsubscribe(RealtimeChannel channel) {
    _client.removeChannel(channel);
  }
}
