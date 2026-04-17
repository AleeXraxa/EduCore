import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/features/students/models/student.dart';

class StudentService {
  final FirebaseFirestore _firestore;

  StudentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _studentsRef(String academyId) {
    return _firestore.collection('academies').doc(academyId).collection('students');
  }

  Future<Student> createStudent(String academyId, Student student) async {
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
    var query = _studentsRef(academyId)
        .where('status', isNotEqualTo: 'deleted')
        .orderBy('status', descending: true)
        .orderBy('name', descending: false);

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = _studentsRef(academyId).where('status', isEqualTo: statusFilter).orderBy('name', descending: false);
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
}
