import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/services/audit_log_service.dart';
import 'package:educore/src/features/classes/models/institute_class.dart';

class ClassService {
  ClassService({
    required FirebaseFirestore firestore,
    required AuditLogService auditLogService,
  })  : _firestore = firestore,
        _audit = auditLogService;

  final FirebaseFirestore _firestore;
  final AuditLogService _audit;

  CollectionReference<Map<String, dynamic>> _col(String academyId) =>
      _firestore.collection('academies').doc(academyId).collection('classes');

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
    required String performedBy,
  }) async {
    final docRef = _col(academyId).doc();
    
    // Check for duplicates
    final existing = await _col(academyId)
        .where('name', isEqualTo: name.trim())
        .where('section', isEqualTo: section.trim())
        .get();
        
    if (existing.docs.isNotEmpty) {
      throw Exception('A class with this name and section already exists.');
    }

    final data = {
      'name': name.trim(),
      'section': section.trim(),
      'classTeacherId': classTeacherId,
      'classTeacherName': classTeacherName,
      'subjectIds': <String>[],
      'studentCount': 0,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(data);

    await _audit.logAction(
      action: 'class_created',
      module: 'classes',
      targetDoc: docRef.id,
      academyId: academyId,
      uid: performedBy,
      role: 'institute_admin',
    );
  }

  Future<void> updateClass({
    required String academyId,
    required String classId,
    required Map<String, dynamic> updates,
    required String performedBy,
  }) async {
    final docRef = _col(academyId).doc(classId);

    if (updates.containsKey('name') || updates.containsKey('section')) {
      final cDoc = await docRef.get();
      if (cDoc.exists) {
        final currentName = cDoc.data()?['name'] as String? ?? '';
        final currentSection = cDoc.data()?['section'] as String? ?? '';
        
        final newName = (updates['name'] as String?)?.trim() ?? currentName;
        final newSection = (updates['section'] as String?)?.trim() ?? currentSection;

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
    }

    updates['updatedAt'] = FieldValue.serverTimestamp();
    await docRef.update(updates);

    await _audit.logAction(
      action: 'class_updated',
      module: 'classes',
      targetDoc: classId,
      academyId: academyId,
      uid: performedBy,
      role: 'institute_admin',
    );
  }

  Future<void> deleteClass({
    required String academyId,
    required String classId,
    required String performedBy,
  }) async {
    final docRef = _col(academyId).doc(classId);
    
    final doc = await docRef.get();
    if (doc.exists && (doc.data()?['studentCount'] ?? 0) > 0) {
      throw Exception('Cannot delete a class that has enrolled students.');
    }

    await docRef.delete();

    await _audit.logAction(
      action: 'class_deleted',
      module: 'classes',
      targetDoc: classId,
      academyId: academyId,
      uid: performedBy,
      role: 'institute_admin',
    );
  }
}
