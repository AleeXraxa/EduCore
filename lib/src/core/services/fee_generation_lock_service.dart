import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the result of attempting to acquire a generation lock.
sealed class LockResult {
  const LockResult();
}

/// Lock was successfully acquired — caller may proceed.
class LockAcquired extends LockResult {
  const LockAcquired(this.lockId);
  final String lockId;
}

/// Lock is currently held by an ongoing process — caller must wait.
class LockBlocked extends LockResult {
  const LockBlocked({required this.status, required this.startedAt});
  final String status; // "processing" | "completed"
  final DateTime startedAt;
}

/// Manages Firestore-backed generation locks to prevent duplicate or
/// concurrent batch fee generation for the same class + month.
///
/// Lock document path: academies/{academyId}/fee_generation_locks/{classId}_{month}
class FeeGenerationLockService {
  FeeGenerationLockService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _locks(String academyId) =>
      _firestore
          .collection('academies')
          .doc(academyId)
          .collection('fee_generation_locks');

  String _lockId(String classId, String month) => '${classId}_$month';

  /// Atomically checks for an existing lock and creates one if none exists.
  ///
  /// Returns [LockAcquired] if the caller may proceed, or [LockBlocked]
  /// if another process is already running (or completed) for this key.
  Future<LockResult> acquireLock(
    String academyId, {
    required String classId,
    required String month,
  }) async {
    final lockId = _lockId(classId, month);
    final lockRef = _locks(academyId).doc(lockId);

    try {
      return await _firestore.runTransaction<LockResult>((tx) async {
        final snapshot = await tx.get(lockRef);

        if (snapshot.exists) {
          final data = snapshot.data()!;
          final status = data['status'] as String? ?? '';
          final startedAt = (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

          // Stale "processing" locks older than 10 minutes are auto-recovered.
          if (status == 'processing') {
            final age = DateTime.now().difference(startedAt);
            if (age.inMinutes < 10) {
              return LockBlocked(status: 'processing', startedAt: startedAt);
            }
            // Stale lock — fall through to overwrite below.
          } else if (status == 'completed') {
            return LockBlocked(status: 'completed', startedAt: startedAt);
          }
        }

        // Create (or recover) the lock in "processing" state.
        tx.set(lockRef, {
          'classId': classId,
          'month': month,
          'status': 'processing',
          'startedAt': FieldValue.serverTimestamp(),
          'completedAt': null,
        });

        return LockAcquired(lockId);
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Marks a previously acquired lock as completed.
  Future<void> completeLock(String academyId, {required String classId, required String month}) async {
    final lockId = _lockId(classId, month);
    await _locks(academyId).doc(lockId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Releases (deletes) a lock, used on generation failure to allow retry.
  Future<void> releaseLock(String academyId, {required String classId, required String month}) async {
    final lockId = _lockId(classId, month);
    await _locks(academyId).doc(lockId).delete();
  }

  /// Returns the current lock document, or null if no lock exists.
  Future<Map<String, dynamic>?> getLockStatus(
    String academyId, {
    required String classId,
    required String month,
  }) async {
    final snap = await _locks(academyId).doc(_lockId(classId, month)).get();
    return snap.exists ? snap.data() : null;
  }
}
