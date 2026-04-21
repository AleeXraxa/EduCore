import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/services/institute_service.dart';
import 'package:educore/src/features/institutes/models/institute.dart';

/// [InstituteRepository] manages the lifecycle and metadata of academies (tenants).
class InstituteRepository {
  InstituteRepository(this._firestore, {required InstituteService service})
      : _instituteService = service;
  final FirebaseFirestore _firestore;
  final InstituteService _instituteService;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('academies');

  /// Fetches a batch of academies as [Institute] models for the dashboard.
  Future<List<Institute>> getInstitutesBatch({
    int limit = 50,
    DocumentSnapshot? lastDoc,
    String? status,
  }) async {
    Query<Map<String, dynamic>> query = _collection.orderBy(
      'createdAt',
      descending: true,
    );

    if (status != null && status != 'all') {
      query = query.where('status', isEqualTo: status);
    }

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.limit(limit).get();
    return snapshot.docs.map((doc) => Institute.fromAcademyDoc(doc)).toList();
  }

  /// Updates academy metadata.
  Future<void> updateInstitute(String id, Map<String, dynamic> data) async {
    await _collection.doc(id).update(data);
  }

  /// Updates the status of an institute.
  Future<void> updateInstituteStatus(String id, String status) async {
    await _collection.doc(id).update({'status': status});
  }

  /// Updates the plan of an institute.
  Future<void> updateInstitutePlan(String id, String planId) async {
    await _collection.doc(id).update({'planId': planId});
  }

  /// Creates a new institute record (proxy to InstituteService for complex logic if needed,
  /// but here we implement the basic doc creation or call service).
  /// For this hardening, we keep it simple or delegate complex auth to service.
  Future<void> createInstitute({
    required String name,
    required String ownerName,
    required String email,
    required String phone,
    required String address,
    required String adminEmail,
    required String adminPassword,
    String planId = 'free_tier',
  }) async {
    // Delegate complex creation logic (Auth + Firestore Batch) to InstituteService
    await _instituteService.createInstitute(
      name: name,
      ownerName: ownerName,
      email: email,
      phone: phone,
      address: address,
      adminEmail: adminEmail,
      adminPassword: adminPassword,
      planId: planId,
    );
  }

  /// Fetches a single academy.
  Future<Institute?> getInstitute(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Institute.fromAcademyDoc(doc);
  }

  /// Streams all institutes (useful for dropdowns with few items).
  /// Capped at 100 for safety.
  Stream<List<Institute>> watchAll() {
    return _collection
        .orderBy('nameLower')
        .limit(100)
        .snapshots()
        .map(
          (s) => s.docs.map((doc) => Institute.fromAcademyDoc(doc)).toList(),
        );
  }
}
