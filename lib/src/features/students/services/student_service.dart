import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/services/subscription_service.dart';
import 'package:educore/src/features/students/models/student.dart';
import 'package:educore/src/features/students/models/custom_field.dart';

import 'package:educore/src/core/services/fee_service.dart';

class StudentService {
  final FirebaseFirestore _firestore;
  final SubscriptionService _subscriptionService;
  final FeeService _feeService;

  StudentService({
    FirebaseFirestore? firestore,
    required SubscriptionService subscriptionService,
    required FeeService feeService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _subscriptionService = subscriptionService,
        _feeService = feeService;

  CollectionReference<Map<String, dynamic>> _studentsRef(String academyId) {
    return _firestore.collection('academies').doc(academyId).collection('students');
  }

  CollectionReference<Map<String, dynamic>> _customFieldsRef(String academyId) {
    return _firestore
        .collection('academies')
        .doc(academyId)
        .collection('student_custom_fields');
  }

  Future<Student> createStudent(String academyId, Student student) async {
    // 1. Enforce Plan Limits
    await _subscriptionService.checkLimit(academyId, 'maxStudents');

    final docRef = _studentsRef(academyId).doc();
    final newStudent = student.copyWith(
      id: docRef.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await docRef.set(newStudent.toMap());
    
    // Auto-generate Admission Fee
    try {
      await _feeService.createAdmissionFee(
        academyId,
        studentId: newStudent.id,
        classId: newStudent.classId,
        amount: 5000.0, // Default base admission fee
      );
    } catch (_) {
      // Ignored if already exists
    }
    
    return newStudent;
  }

  Future<void> updateStudent(String academyId, Student student) async {
    final updateData = student.copyWith(updatedAt: DateTime.now()).toMap();
    await _studentsRef(academyId).doc(student.id).update(updateData);
  }

  Future<void> softDeleteStudent(String academyId, String studentId) async {
    await _studentsRef(academyId).doc(studentId).update({
      'status': 'deleted',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getStudentsBatch({
    required String academyId,
    DocumentSnapshot? startAfter,
    int limit = 20,
    String? classIdFilter,
    String? statusFilter,
    String? searchQuery,
  }) async {
    Query<Map<String, dynamic>> query = _studentsRef(academyId);

    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter).orderBy('name');
    } else {
      query = query.orderBy('status', descending: true).orderBy('name');
    }
    
    if (classIdFilter != null && classIdFilter.isNotEmpty) {
      query = query.where('classId', isEqualTo: classIdFilter);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);
    return await query.get();
  }

  Future<Map<String, int>> getStudentStats(String academyId) async {
    final ref = _studentsRef(academyId);

    try {
      final activeQuery = await ref.where('status', isEqualTo: 'active').count().get();
      final inactiveQuery = await ref.where('status', isEqualTo: 'inactive').count().get();
      
      final activeCount = activeQuery.count ?? 0;
      final inactiveCount = inactiveQuery.count ?? 0;
      final totalCount = activeCount + inactiveCount;

      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final newAdmissionsQuery = await ref
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .count()
          .get();

      return {
        'total': totalCount,
        'active': activeCount,
        'inactive': inactiveCount,
        'newAdmissions': newAdmissionsQuery.count ?? 0,
      };
    } catch (e) {
      debugPrint('Error fetching student stats: $e');
      return {
        'total': 0,
        'active': 0,
        'inactive': 0,
        'newAdmissions': 0,
      };
    }
  }

  Future<List<StudentCustomField>> getCustomFieldDefinitions(
      String academyId) async {
    final snapshot = await _customFieldsRef(academyId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => StudentCustomField.fromFirestore(doc))
        .toList();
  }

  Future<StudentCustomField> createCustomFieldDefinition(
    String academyId,
    StudentCustomField field,
  ) async {
    final docRef = _customFieldsRef(academyId).doc();
    final newField = StudentCustomField(
      id: docRef.id,
      key: field.key,
      label: field.label,
      type: field.type,
      isRequired: field.isRequired,
      options: field.options,
      isActive: field.isActive,
      createdAt: DateTime.now(),
    );
    await docRef.set(newField.toFirestore());
    return newField;
  }

  /// Migrates legacy student data from className-based to classId-based.
  /// This should be run once during the normalization process.
  Future<void> migrateClassData(String academyId, List<dynamic> classes) async {
    final studentsSnapshot = await _studentsRef(academyId).get();
    final batch = _firestore.batch();
    int migratedCount = 0;

    for (final doc in studentsSnapshot.docs) {
      final data = doc.data();
      if (data.containsKey('classId') && (data['classId'] as String).isNotEmpty) {
        continue; // Already migrated
      }

      final legacyClassName = data['className'] as String? ?? '';
      if (legacyClassName.isEmpty) continue;

      // Find classId by name
      final matchedClass = classes.firstWhere(
        (c) => (c.name as String).toLowerCase() == legacyClassName.toLowerCase(),
        orElse: () => null,
      );

      if (matchedClass != null) {
        batch.update(doc.reference, {
          'classId': matchedClass.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        migratedCount++;
      }
    }

    if (migratedCount > 0) {
      await batch.commit();
    }
  }
}
