import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:educore/src/core/services/audit_log_service.dart';
import 'package:educore/src/features/audit/models/audit_log.dart';
import 'dart:math';

enum AcademyStatus {
  pending('pending'),
  active('active'),
  blocked('blocked');

  const AcademyStatus(this.value);
  final String value;

  static AcademyStatus fromValue(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'active':
        return AcademyStatus.active;
      case 'blocked':
        return AcademyStatus.blocked;
      case 'pending':
      default:
        return AcademyStatus.pending;
    }
  }
}

@immutable
class Academy {
  const Academy({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.address,
    required this.status,
    required this.planId,
    required this.createdAt,
    required this.createdBy,
  });

  final String id; // academyId
  final String name;
  final String ownerName;
  final String email;
  final String phone;
  final String address;
  final AcademyStatus status;
  final String planId;
  final DateTime? createdAt;
  final String createdBy;

  static Academy fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Academy(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      ownerName: (data['ownerName'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      address: (data['address'] as String?) ?? '',
      status: AcademyStatus.fromValue(data['status'] as String?),
      planId: (data['planId'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      createdBy: (data['createdBy'] as String?) ?? '',
    );
  }
}

class InstituteService {
  InstituteService({
    required FirebaseFirestore firestore,
    required FirebaseApp primaryApp,
    required FirebaseAuth primaryAuth,
    required AuditLogService auditLogService,
  })  : _firestore = firestore,
        _primaryApp = primaryApp,
        _primaryAuth = primaryAuth,
        _audit = auditLogService;

  final FirebaseFirestore _firestore;
  final FirebaseApp _primaryApp;
  final FirebaseAuth _primaryAuth;
  final AuditLogService _audit;

  FirebaseAuth? _secondaryAuth;

  CollectionReference<Map<String, dynamic>> get _academies =>
      _firestore.collection('academies');
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _subscriptions =>
      _firestore.collection('subscriptions');

  Stream<List<Academy>> watchAcademies() {
    return _academies
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Academy.fromDoc).toList(growable: false));
  }

  Future<List<Academy>> getAcademies() async {
    final snap = await _academies.get();
    return snap.docs.map(Academy.fromDoc).toList(growable: false);
  }

  Stream<Academy?> watchAcademy(String academyId) {
    return _academies.doc(academyId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Academy.fromDoc(snap);
    });
  }

  Future<String> generateAcademyId(String name) async {
    final base = _sanitizeAcademyId(name);
    final candidateBase = base.isEmpty ? 'academy' : base;

    for (var attempt = 0; attempt < 8; attempt++) {
      final suffix = attempt == 0 ? '' : '_${_rand3()}';
      final candidate = '$candidateBase$suffix';
      final exists = await _academies.doc(candidate).get().then((d) => d.exists);
      if (!exists) return candidate;
    }

    // Fallback to timestamp-based suffix.
    final fallback = '${candidateBase}_${DateTime.now().millisecondsSinceEpoch % 100000}';
    return fallback;
  }

  Future<Academy> createInstitute({
    required String name,
    required String ownerName,
    required String email,
    required String phone,
    required String address,
    required String adminEmail,
    required String adminPassword,
    required String planId,
    DateTime? endDate,
  }) async {
    final superUid = _primaryAuth.currentUser?.uid;
    if (superUid == null) {
      throw StateError('Not signed in.');
    }

    final academyId = await generateAcademyId(name);
    final adminAuth = await _ensureSecondaryAuth();

    UserCredential? adminCred;
    try {
      // NOTE: This creates a real Firebase Auth user from the client app.
      // For production-grade security, prefer a Cloud Function with Admin SDK.
      adminCred = await adminAuth.createUserWithEmailAndPassword(
        email: adminEmail.trim(),
        password: adminPassword,
      );

      final adminUid = adminCred.user?.uid;
      if (adminUid == null) {
        throw StateError('Failed to create institute admin user.');
      }

      final academyRef = _academies.doc(academyId);
      final userRef = _users.doc(adminUid);
      final subRef = _subscriptions.doc(academyId);
      final bootstrapRef =
          academyRef.collection('system').doc('bootstrap');

      final now = FieldValue.serverTimestamp();
      final startDate = Timestamp.fromDate(DateTime.now());
      final endTs = endDate == null ? null : Timestamp.fromDate(endDate);
      final batch = _firestore.batch();

      batch.set(academyRef, {
        'name': name.trim(),
        'nameLower': name.trim().toLowerCase(),
        'ownerName': ownerName.trim(),
        'ownerNameLower': ownerName.trim().toLowerCase(),
        'email': email.trim(),
        'emailLower': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'address': address.trim(),
        'status': AcademyStatus.active.value,
        'planId': planId.trim(),
        'createdAt': now,
        'createdBy': superUid,
      });

      batch.set(userRef, {
        'uid': adminUid,
        'name': ownerName.trim(),
        'email': adminEmail.trim(),
        'emailLower': adminEmail.trim().toLowerCase(),
        'phone': phone.trim(),
        'role': AppUserRole.instituteAdmin.value,
        'academyId': academyId,
        'status': 'active',
        'createdAt': now,
        'createdBy': superUid,
      });

      // Initialize default subscription
      batch.set(subRef, {
        'academyId': academyId,
        'planId': planId.trim(),
        'status': 'active', // Default to active for manually created institutes
        'startDate': startDate,
        'endDate': endTs,
        'createdAt': now,
        'createdBy': superUid,
      });

      batch.set(bootstrapRef, {
        'createdAt': now,
        'createdBy': superUid,
        'version': 1,
      });

      await batch.commit();

      // Log Action
      await _audit.logAction(
        action: 'INSTITUTE_CREATED',
        module: 'academies',
        targetId: academyId,
        targetType: 'academy',
        severity: AuditSeverity.critical,
      );

      // Keep the secondary auth clean.
      await adminAuth.signOut();

      // Return a view model; createdAt resolves later.
      return Academy(
        id: academyId,
        name: name.trim(),
        ownerName: ownerName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        address: address.trim(),
        status: AcademyStatus.active,
        planId: planId.trim(),
        createdAt: null,
        createdBy: superUid,
      );
    } catch (e) {
      // Best-effort cleanup: if Auth user created but Firestore failed.
      try {
        final createdUser = adminCred?.user;
        if (createdUser != null) {
          await createdUser.delete();
        }
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> updateInstitute({
    required String academyId,
    String? name,
    String? ownerName,
    String? email,
    String? phone,
    String? address,
  }) async {
    final patch = <String, dynamic>{};
    if (name != null) {
      patch['name'] = name.trim();
      patch['nameLower'] = name.trim().toLowerCase();
    }
    if (ownerName != null) {
      patch['ownerName'] = ownerName.trim();
      patch['ownerNameLower'] = ownerName.trim().toLowerCase();
    }
    if (email != null) {
      patch['email'] = email.trim();
      patch['emailLower'] = email.trim().toLowerCase();
    }
    if (phone != null) patch['phone'] = phone.trim();
    if (address != null) patch['address'] = address.trim();
    if (patch.isEmpty) return;
    await _academies.doc(academyId).update(patch);

    // Log Action
    await _audit.logAction(
      action: 'INSTITUTE_UPDATED',
      module: 'academies',
      targetId: academyId,
      targetType: 'academy',
      after: patch,
      severity: AuditSeverity.warning,
    );
  }

  Future<void> setAcademyStatus(String academyId, AcademyStatus status) async {
    await _academies.doc(academyId).update({'status': status.value});

    // Log Action
    await _audit.logAction(
      action: status == AcademyStatus.blocked ? 'INSTITUTE_BLOCKED' : 'INSTITUTE_STATUS_CHANGED',
      module: 'academies',
      targetId: academyId,
      targetType: 'academy',
      after: {'status': status.value},
      severity: status == AcademyStatus.blocked ? AuditSeverity.critical : AuditSeverity.info,
    );
  }

  Future<void> setPlan(String academyId, String planId) async {
    final clean = planId.trim();
    if (clean.isEmpty) return;

    final batch = _firestore.batch();
    batch.update(_academies.doc(academyId), {'planId': clean});
    batch.update(_subscriptions.doc(academyId), {
      'planId': clean,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> assignPlan({
    required String academyId,
    required String planId,
  }) async {
    final now = FieldValue.serverTimestamp();
    final batch = _firestore.batch();
    batch.update(_academies.doc(academyId), {'planId': planId.trim()});
    batch.set(
      _subscriptions.doc(academyId),
      {
        'academyId': academyId,
        'planId': planId.trim(),
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<FirebaseAuth> _ensureSecondaryAuth() async {
    final existing = _secondaryAuth;
    if (existing != null) return existing;

    // Secondary app is used to create the institute admin without
    // disrupting the super admin's session.
    final secondary = await Firebase.initializeApp(
      name: 'educore-secondary-auth',
      options: _primaryApp.options,
    );
    final auth = FirebaseAuth.instanceFor(app: secondary);
    _secondaryAuth = auth;
    return auth;
  }

  String _sanitizeAcademyId(String name) {
    final lower = name.trim().toLowerCase();
    if (lower.isEmpty) return '';
    final replaced = lower.replaceAll(RegExp(r'\s+'), '_');
    final clean = replaced.replaceAll(RegExp(r'[^a-z0-9_]+'), '');
    return clean.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
  }

  String _rand3() {
    final rng = Random();
    return (rng.nextInt(900) + 100).toString();
  }
}
