import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/services/audit_log_service.dart';
import 'package:educore/src/features/certificates/models/certificate_template.dart';

class CertificateTemplateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditLogService _auditLogService;

  CertificateTemplateService(this._auditLogService);

  CollectionReference _getTemplateCollection(String academyId) {
    return _firestore
        .collection('academies')
        .doc(academyId)
        .collection('certificate_templates');
  }

  Future<String> createTemplate({
    required String academyId,
    required CertificateTemplate template,
  }) async {
    final docRef = _getTemplateCollection(academyId).doc();
    final newTemplate = template.copyWith(id: docRef.id, updatedAt: DateTime.now());
    
    if (newTemplate.isDefault) {
      await _ensureOnlyOneDefault(academyId, excludeId: docRef.id);
    }

    await docRef.set(newTemplate.toMap());

    await _auditLogService.logAction(
      action: 'certificate_template_created',
      module: 'certificates',
      targetId: docRef.id,
      targetType: 'certificate_template',
      after: newTemplate.toMap(),
      metadata: {'name': template.name},
    );

    return docRef.id;
  }

  Future<void> updateTemplate({
    required String academyId,
    required CertificateTemplate template,
  }) async {
    final beforeDoc = await _getTemplateCollection(academyId).doc(template.id).get();
    final beforeData = beforeDoc.data() as Map<String, dynamic>?;

    if (template.isDefault) {
      await _ensureOnlyOneDefault(academyId, excludeId: template.id);
    }

    await _getTemplateCollection(academyId).doc(template.id).update(
          template.copyWith(updatedAt: DateTime.now()).toMap(),
        );

    await _auditLogService.logAction(
      action: 'certificate_template_updated',
      module: 'certificates',
      targetId: template.id,
      targetType: 'certificate_template',
      before: beforeData,
      after: template.toMap(),
    );
  }

  Future<void> deleteTemplate({
    required String academyId,
    required String templateId,
    required String templateName,
  }) async {
    final doc = await _getTemplateCollection(academyId).doc(templateId).get();
    final beforeData = doc.data() as Map<String, dynamic>?;

    await _getTemplateCollection(academyId).doc(templateId).delete();

    await _auditLogService.logAction(
      action: 'certificate_template_deleted',
      module: 'certificates',
      targetId: templateId,
      targetType: 'certificate_template',
      before: beforeData,
      metadata: {'name': templateName},
    );
  }

  Stream<List<CertificateTemplate>> watchTemplates(String academyId) {
    return _getTemplateCollection(academyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CertificateTemplate.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<List<CertificateTemplate>> getTemplates(String academyId) async {
    final snapshot = await _getTemplateCollection(academyId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      return CertificateTemplate.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }

  Future<void> _ensureOnlyOneDefault(String academyId, {required String excludeId}) async {
    final query = await _getTemplateCollection(academyId)
        .where('isDefault', isEqualTo: true)
        .get();

    final batch = _firestore.batch();
    for (final doc in query.docs) {
      if (doc.id != excludeId) {
        batch.update(doc.reference, {'isDefault': false});
      }
    }
    await batch.commit();
  }
}
