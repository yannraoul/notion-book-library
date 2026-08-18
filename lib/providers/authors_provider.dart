import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notion_api.dart';
import 'notion_connection_provider.dart';

/// `id -> Name` for every row of the `Authors*` database — a shared home
/// for a fetch every author-matching consumer needs (the chip-input
/// widget's live dropdown, the scan-queue's import-time ambiguity check),
/// instead of each one calling `queryRelationNames` ad hoc. Caches for the
/// life of the container; callers invalidate it explicitly after a write
/// that may have added a new author (see `queue_screen.dart`'s
/// `commitReady` handling).
final authorNamesProvider = FutureProvider<Map<String, String>>((ref) async {
  final connection = ref.watch(notionConnectionProvider);
  final authorsDbId = connection is NotionConnected ? connection.authorsDatabaseId : null;
  if (connection is! NotionConnected || authorsDbId == null) {
    return const {};
  }
  return NotionApi().queryRelationNames(connection.token, authorsDbId);
});
