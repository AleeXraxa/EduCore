import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/services/subscription_service.dart';
import 'package:educore/src/features/students/models/student.dart';
import 'package:educore/src/features/students/models/custom_field.dart';

class StudentService {
  final FirebaseFirestore _firestore;
  final SubscriptionService _subscriptionService;

  StudentService({
    FirebaseFirestore? firestore,
    required SubscriptionService subscriptionService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _subscriptionService = subscriptionService;

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
    String? classFilter,
    String? statusFilter,
    String? searchQuery,
  }) async {
    Query<Map<String, dynamic>> query = _studentsRef(academyId);

    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter).orderBy('name');
    } else {
      query = query.orderBy('status', descending: true).orderBy('name');
    }
    
    if (classFilter != null && classFilter.isNotEmpty) {
      query = query.where('className', isEqualTo: classFilter);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);
    return await query.get();
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
}
