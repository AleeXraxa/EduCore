import 'package:cloud_firestore/cloud_firestore.dart';

class RoleDefaultsService {
  RoleDefaultsService({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('system').doc('config').collection('role_defaults');

  Future<Map<String, List<String>>> getRoleDefaults() async {
    try {
      final snap = await _col.get();
      final Map<String, List<String>> result = {};
      
      for (final doc in snap.docs) {
        final data = doc.data();
        final features = (data['features'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ?? [];
        result[doc.id.toLowerCase()] = features;
      }
      
      return result;
    } catch (e) {
      return {};
    }
  }
}
