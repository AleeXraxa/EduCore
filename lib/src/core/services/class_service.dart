import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/services/audit_log_service.dart';
import 'package:educore/src/features/audit/models/audit_log.dart';
import 'package:educore/src/core/services/subscription_service.dart';
import 'package:educore/src/features/classes/models/institute_class.dart';

class ClassService {
  ClassService({
    required FirebaseFirestore firestore,
    required AuditLogService auditLogService,
    required SubscriptionService subscriptionService,
  })  : _firestore = firestore,
        _audit = auditLogService,
        _subscriptionService = subscriptionService;

  final FirebaseFirestore _firestore;
  final AuditLogService _audit;
  final SubscriptionService _subscriptionService;

  CollectionReference<Map<String, dynamic>> _col(String academyId) =>
      _firestore.collection('academies').doc(academyId).collection('classes');

  DocumentReference<Map<String, dynamic>> _staffRef(
          String academyId, String staffId) =>
      _firestore
          .collection('academies')
          .doc(academyId)
          .collection('staff')
          .doc(staffId);

  Stream<List<InstituteClass>> watchClasses(String academyId) {
    return _col(academyId).snapshots().map((snap) {
      final list = snap.docs.map(InstituteClass.fromDoc).toList();
      list.sort((a, b) {
        final cmp = a.name.compareTo(b.name);
        if (cmp != 0) return cmp;
        return a.section.compareTo(b.section);
      });
      return list;
    });
  }

  Future<List<InstituteClass>> getClasses(String academyId) async {
    final snap = await _col(academyId).get();
    final list = snap.docs.map(InstituteClass.fromDoc).toList();
    list.sort((a, b) {
      final cmp = a.name.compareTo(b.name);
      if (cmp != 0) return cmp;
      return a.section.compareTo(b.section);
    });
    return list;
  }

  Future<InstituteClass?> getClass(String academyId, String classId) async {
    final doc = await _col(academyId).doc(classId).get();
    if (!doc.exists) return null;
    return InstituteClass.fromDoc(doc);
  }

  Future<void> createClass({
    required String academyId,
    required String name,
    required String section,
    String? classTeacherId,
    String? classTeacherName,
    required String feePlanId,
    required String feePlanName,
    required String performedBy,
  }) async {
    // 1. Enforce Plan Limits
    await _subscriptionService.checkLimit(academyId, 'maxClasses');

    // Check for duplicates
    final existing = await _col(academyId)
        .where('name', isEqualTo: name.trim())
        .where('section', isEqualTo: section.trim())
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('A class with this name and section already exists.');
    }

    final batch = _firestore.batch();
    final docRef = _col(academyId).doc();

    final data = {
      'name': name.trim(),
      'section': section.trim(),
      'classTeacherId': classTeacherId,
      'classTeacherName': classTeacherName,
      'teacherIds': classTeacherId != null ? [classTeacherId] : [],
      'subjectIds': <String>[],
      'studentCount': 0,
      'isActive': true,
      'feePlanId': feePlanId,
      'feePlanName': feePlanName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    batch.set(docRef, data);

    if (classTeacherId != null) {
      batch.update(_staffRef(academyId, classTeacherId), {
        'assignedClassIds': FieldValue.arrayUnion([docRef.id]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    await _audit.logAction(
      action: 'class_created',
      module: 'classes',
      targetId: docRef.id,
      targetType: 'class',
      severity: AuditSeverity.info,
    );
  }

  Future<void> updateClass({
    required String academyId,
    required String classId,
    required Map<String, dynamic> updates,
    required String performedBy,
  }) async {
    final docRef = _col(academyId).doc(classId);
    final currentDoc = await docRef.get();
    if (!currentDoc.exists) throw Exception('Class not found');

    final batch = _firestore.batch();

    // Check for duplicate name/section if updated
    if (updates.containsKey('name') || updates.containsKey('section')) {
      final currentName = currentDoc.data()?['name'] as String? ?? '';
      final currentSection = currentDoc.data()?['section'] as String? ?? '';

      final newName = (updates['name'] as String?)?.trim() ?? currentName;
      final newSection =
          (updates['section'] as String?)?.trim() ?? currentSection;

      if (newName != currentName || newSection != currentSection) {
        final existing = await _col(academyId)
            .where('name', isEqualTo: newName)
            .where('section', isEqualTo: newSection)
            .get();

        if (existing.docs.any((d) => d.id != classId)) {
          throw Exception('A class with this name and section already exists.');
        }
      }
    }

    // Bidirectional Teacher Sync
    if (updates.containsKey('classTeacherId')) {
      final oldId = currentDoc.data()?['classTeacherId'] as String?;
      final newId = updates['classTeacherId'] as String?;

      if (oldId != newId) {
        // Remove from old
        if (oldId != null) {
          // Note: Only remove from membership if they are not in teacherIds list 
          // (But usually class teacher is part of teacherIds)
          // For simplicity, we manage classTeacherId as a primary assignment.
          batch.update(_staffRef(academyId, oldId), {
            'assignedClassIds': FieldValue.arrayRemove([classId]),
          });
        }
        // Add to new
        if (newId != null) {
          batch.update(_staffRef(academyId, newId), {
            'assignedClassIds': FieldValue.arrayUnion([classId]),
          });
          // Also ensure new teacher is in membership list
          updates['teacherIds'] = FieldValue.arrayUnion([newId]);
        }
      }
    }

    updates['updatedAt'] = FieldValue.serverTimestamp();
    batch.update(docRef, updates);

    // Update Students Cache if Name/Section changed
    if (updates.containsKey('name') || updates.containsKey('section')) {
      final newName = (updates['name'] as String?)?.trim() ?? currentDoc.data()?['name'] as String? ?? '';
      final newSection = (updates['section'] as String?)?.trim() ?? currentDoc.data()?['section'] as String? ?? '';
      final displayLabel = newSection.isEmpty ? newName : '$newName - $newSection';

      final studentsSnapshot = await _firestore
          .collection('academies')
          .doc(academyId)
          .collection('students')
          .where('classId', isEqualTo: classId)
          .get();

      for (final studentDoc in studentsSnapshot.docs) {
        batch.update(studentDoc.reference, {
          'className': displayLabel,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();

    await _audit.logAction(
      action: 'class_updated',
      module: 'classes',
      targetId: classId,
      targetType: 'class',
      severity: AuditSeverity.info,
    );
  }

  Future<void> deleteClass({
    required String academyId,
    required String classId,
    required String performedBy,
  }) async {
    final docRef = _col(academyId).doc(classId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    if ((doc.data()?['studentCount'] ?? 0) > 0) {
      throw Exception('Cannot delete a class that has enrolled students.');
    }

    final batch = _firestore.batch();
    
    // Reverse sync: Remove from all assigned teachers
    final teacherIds = List<String>.from(doc.data()?['teacherIds'] ?? []);
    for (final tid in teacherIds) {
      batch.update(_staffRef(academyId, tid), {
        'assignedClassIds': FieldValue.arrayRemove([classId]),
      });
    }

    batch.delete(docRef);
    await batch.commit();

    await _audit.logAction(
      action: 'class_deleted',
      module: 'classes',
      targetId: classId,
      targetType: 'class',
      severity: AuditSeverity.critical,
    );
  }

  Future<void> assignClassTeacher({
    required String academyId,
    required String classId,
    required String teacherId,
    required String teacherName,
    required String performedBy,
  }) async {
    final batch = _firestore.batch();
    final docRef = _col(academyId).doc(classId);

    // Get current CT to remove mapping
    final doc = await docRef.get();
    final oldCT = doc.data()?['classTeacherId'] as String?;

    if (oldCT != null && oldCT != teacherId) {
      batch.update(_staffRef(academyId, oldCT), {
        'assignedClassIds': FieldValue.arrayRemove([classId]),
      });
    }

    batch.update(docRef, {
      'classTeacherId': teacherId,
      'classTeacherName': teacherName,
      'teacherIds': FieldValue.arrayUnion([teacherId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.update(_staffRef(academyId, teacherId), {
      'assignedClassIds': FieldValue.arrayUnion([classId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    await _audit.logAction(
      action: 'assign_class_teacher',
      module: 'classes',
      targetId: classId,
      targetType: 'class',
      after: {'teacherId': teacherId, 'teacherName': teacherName},
      severity: AuditSeverity.warning,
    );
  }

  Future<void> assignMultipleTeachers({
    required String academyId,
    required String classId,
    required List<String> teacherIds,
    required String performedBy,
  }) async {
    final batch = _firestore.batch();

    // Update Class
    batch.update(_col(academyId).doc(classId), {
      'teacherIds': FieldValue.arrayUnion(teacherIds),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update each staff
    for (final tid in teacherIds) {
      batch.update(_staffRef(academyId, tid), {
        'assignedClassIds': FieldValue.arrayUnion([classId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    await _audit.logAction(
      action: 'assign_teachers',
      module: 'classes',
      targetId: classId,
      targetType: 'class',
      after: {'teacherIds': teacherIds},
      severity: AuditSeverity.info,
    );
  }

  Future<void> removeTeachers({
    required String academyId,
    required String classId,
    required List<String> teacherIds,
    required String performedBy,
  }) async {
    final batch = _firestore.batch();
    final docRef = _col(academyId).doc(classId);

    // Update Class
    batch.update(docRef, {
      'teacherIds': FieldValue.arrayRemove(teacherIds),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update each staff
    for (final tid in teacherIds) {
      batch.update(_staffRef(academyId, tid), {
        'assignedClassIds': FieldValue.arrayRemove([classId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Handle Class Teacher nullification
    final doc = await docRef.get();
    final currentCT = doc.data()?['classTeacherId'] as String?;
    if (teacherIds.contains(currentCT)) {
      batch.update(docRef, {
        'classTeacherId': null,
        'classTeacherName': null,
      });
    }

    await batch.commit();

    await _audit.logAction(
      action: 'remove_teachers',
      module: 'classes',
      targetId: classId,
      targetType: 'class',
      after: {'removedIds': teacherIds},
      severity: AuditSeverity.warning,
    );
  }
}
