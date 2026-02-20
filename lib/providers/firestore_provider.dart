import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firestore_service.dart';
import '../services/pending_sync_service.dart';

final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

/// Provides [PendingSyncService]. Override in main with an opened instance.
final pendingSyncServiceProvider = Provider<PendingSyncService>((ref) {
  throw UnimplementedError(
    'Override pendingSyncServiceProvider in main with an opened PendingSyncService',
  );
});
