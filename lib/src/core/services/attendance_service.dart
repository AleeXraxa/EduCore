import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:educore/src/features/attendance/models/attendance_record.dart';

class AttendanceService {
  final FirebaseFirestore _firestore;

  AttendanceService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String academyId) => _firestore
      .collection('academies')
      .doc(academyId)
      .collection('attendance');

  /// Fetches attendance records for a specific class and date
  Future<List<AttendanceRecord>> getAttendance({
    required String academyId,
    required String classId,
    required DateTime date,
  }) async {
    // Normalize date to start of day for consistent querying
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final snap = await _col(academyId)
          .where('classId', isEqualTo: classId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      return snap.docs
          .map((doc) => AttendanceRecord.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      if (e.toString().contains('index')) {
        debugPrint('\n\n🚨 [ACTION REQUIRED] FIRESTORE INDEX MISSING 🚨');
        debugPrint('Create it here: $e\n\n');
      }
      rethrow;
    }
  }

  /// Saves or updates attendance records
  Future<void> saveAttendance({
    required String academyId,
    required List<AttendanceRecord> records,
  }) async {
    final batch = _firestore.batch();

    for (final record in records) {
      if (record.id != null) {
        batch.update(_col(academyId).doc(record.id), record.toMap());
      } else {
        // Double check for existence even if id is null to prevent duplicates on same day
        final startOfDay = DateTime(
          record.date.year,
          record.date.month,
          record.date.day,
        );
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final existing = await _col(academyId)
            .where('studentId', isEqualTo: record.studentId)
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
            )
            .where('date', isLessThan: Timestamp.fromDate(endOfDay))
            .limit(1)
            .get();

        if (existing.docs.isNotEmpty) {
          batch.update(existing.docs.first.reference, record.toMap());
        } else {
          final docRef = _col(academyId).doc();
          batch.set(docRef, record.toMap());
        }
      }
    }

    await batch.commit();
  }

  /// Fetches attendance stats for the week
  Future<List<double>> getWeeklyAttendanceTrend(String academyId) async {
    final now = DateTime.now();
    final List<double> trend = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final totalSnap = await _col(academyId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      if (totalSnap.docs.isEmpty) {
        trend.add(0.0);
        continue;
      }

      final present = totalSnap.docs.where((doc) {
        final status = doc.data()['status'] as String?;
        return status == AttendanceStatus.present.name;
      }).length;

      trend.add((present / totalSnap.docs.length * 100));
    }

    return trend;
  }

  /// Fetches attendance report data for a specific range and type
  Future<List<Map<String, dynamic>>> getAttendanceReport({
    required String academyId,
    required DateTime start,
    required DateTime end,
    required String type, // 'student', 'teacher', 'classroom'
  }) async {
    final startOfRange = DateTime(start.year, start.month, start.day);
    final endOfRange = DateTime(end.year, end.month, end.day, 23, 59, 59);

    try {
      final snapshot = await _col(academyId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfRange))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfRange))
          .get();

      final records = snapshot.docs
          .map((doc) => AttendanceRecord.fromMap(doc.id, doc.data()))
          .toList();

      if (type == 'student') {
        final studentMap = <String, Map<String, dynamic>>{};
        for (var r in records) {
          final data = studentMap.putIfAbsent(
            r.studentId,
            () => {
              'name': r.studentName,
              'present': 0,
              'absent': 0,
              'leave': 0,
              'total': 0,
            },
          );

          if (r.status == AttendanceStatus.present) data['present']++;
          if (r.status == AttendanceStatus.absent) data['absent']++;
          if (r.status == AttendanceStatus.leave) data['leave']++;
          data['total']++;
        }

        return studentMap.values.map((v) {
          final present = v['present'] as int;
          final absent = v['absent'] as int;
          v['percentage'] = (present + absent) == 0
              ? 0.0
              : (present / (present + absent) * 100);
          return v;
        }).toList();
      } else if (type == 'classroom') {
        final classMap = <String, Map<String, dynamic>>{};
        for (var r in records) {
          final data = classMap.putIfAbsent(
            r.classId,
            () => {
              'name': r.className,
              'present': 0,
              'absent': 0,
              'leave': 0,
              'total': 0,
              'students': <String>{},
            },
          );

          if (r.status == AttendanceStatus.present) data['present']++;
          if (r.status == AttendanceStatus.absent) data['absent']++;
          if (r.status == AttendanceStatus.leave) data['leave']++;
          data['total']++;
          data['students'].add(r.studentId);
        }

        return classMap.values.map((v) {
          final present = v['present'] as int;
          final absent = v['absent'] as int;
          v['percentage'] = (present + absent) == 0
              ? 0.0
              : (present / (present + absent) * 100);
          v['summary'] =
              'P: ${v['present']}, A: ${v['absent']}, L: ${v['leave']}';
          v['students'] = (v['students'] as Set).length;
          return v;
        }).toList();
      }

      return [];
    } catch (e) {
      if (e.toString().contains('index')) {
        debugPrint('\n\n🚨 [ACTION REQUIRED] FIRESTORE INDEX MISSING 🚨');
        debugPrint('Create it here: $e\n\n');
      }
      rethrow;
    }
  }
}
