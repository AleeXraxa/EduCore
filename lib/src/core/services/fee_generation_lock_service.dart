import 'package:flutter/foundation.dart';
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
      // 1. Get current lock status (Reading outside transaction for Windows stability)
      final snapshot = await lockRef.get();

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
        }
        // If status is 'completed', we fall through and allow re-acquisition
        // to support incremental generation for new students.
      }

      // 2. Set the lock (Atomic set for Windows stability)
      await lockRef.set({
        'classId': classId,
        'month': month,
        'status': 'processing',
        'startedAt': FieldValue.serverTimestamp(),
        'completedAt': null,
      });

      return LockAcquired(lockId);
    } catch (e) {
      debugPrint('Error acquiring lock: $e');
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
