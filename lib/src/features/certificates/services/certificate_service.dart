import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/services/audit_log_service.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/certificates/models/certificate.dart';

class CertificateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditLogService _auditLogService;

  CertificateService(this._auditLogService);

  CollectionReference _getCertCollection(String academyId) {
    return _firestore
        .collection('academies')
        .doc(academyId)
        .collection('certificates');
  }

  Future<String> createCertificate({
    required String academyId,
    required Certificate certificate,
  }) async {
    final docRef = _getCertCollection(academyId).doc();
    final academyName = AppServices.instance.authService?.currentAcademyName ?? 'Unknown Academy';
    final newCert = certificate.copyWith(
      id: docRef.id, 
      updatedAt: DateTime.now(),
      academyId: academyId,
      academyName: academyName,
    );
    
    await docRef.set(newCert.toMap());

    await _auditLogService.logAction(
      action: 'certificate_created',
      module: 'certificates',
      targetId: docRef.id,
      targetType: 'certificate',
      after: newCert.toMap(),
      metadata: {
        'studentName': certificate.studentName,
        'certificateType': certificate.type.name,
      },
    );

    return docRef.id;
  }

  Future<void> updateCertificate({
    required String academyId,
    required Certificate certificate,
  }) async {
    final beforeDoc = await _getCertCollection(academyId).doc(certificate.id).get();
    final beforeData = beforeDoc.data() as Map<String, dynamic>?;

    await _getCertCollection(academyId).doc(certificate.id).update(
          certificate.copyWith(updatedAt: DateTime.now()).toMap(),
        );

    await _auditLogService.logAction(
      action: 'certificate_updated',
      module: 'certificates',
      targetId: certificate.id,
      targetType: 'certificate',
      before: beforeData,
      after: certificate.toMap(),
    );
  }

  Future<void> deleteCertificate({
    required String academyId,
    required String certificateId,
    required String studentName,
  }) async {
    final doc = await _getCertCollection(academyId).doc(certificateId).get();
    final beforeData = doc.data() as Map<String, dynamic>?;

    await _getCertCollection(academyId).doc(certificateId).delete();

    await _auditLogService.logAction(
      action: 'certificate_deleted',
      module: 'certificates',
      targetId: certificateId,
      targetType: 'certificate',
      before: beforeData,
      metadata: {'studentName': studentName},
    );
  }

  Future<void> logDownload({
    required String academyId,
    required String certificateId,
    required String studentName,
  }) async {
    await _getCertCollection(academyId).doc(certificateId).update({
      'downloadCount': FieldValue.increment(1),
      'updatedAt': Timestamp.now(),
    });

    await _auditLogService.logAction(
      action: 'certificate_downloaded',
      module: 'certificates',
      targetId: certificateId,
      targetType: 'certificate',
      metadata: {'studentName': studentName},
    );
  }

  Stream<List<Certificate>> watchCertificates(String academyId) {
    return _getCertCollection(academyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Certificate.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<List<Certificate>> getCertificates(String academyId) async {
    final snapshot = await _getCertCollection(academyId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      return Certificate.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }
  
  Future<Certificate?> verifyCertificate(String certificateId) async {
    // Attempt to find certificate across all academies using collectionGroup
    // Note: This requires a Firestore index for collectionGroup('certificates')
    try {
      final snapshot = await _firestore
          .collectionGroup('certificates')
          .get();
      
      // Since documentId filtering in collectionGroup can be tricky without the full path,
      // and certificate IDs are unique strings we generated, we search for the doc with this ID.
      // Alternatively, if we added 'id' field to toMap, we could filter by it.
      
      for (var doc in snapshot.docs) {
        if (doc.id == certificateId) {
          return Certificate.fromMap(doc.id, doc.data());
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
