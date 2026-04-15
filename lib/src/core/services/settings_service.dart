import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:educore/src/features/settings/models/global_settings.dart';

class SettingsService {
  final FirebaseFirestore _firestore;
  
  SettingsService({required FirebaseFirestore firestore}) : _firestore = firestore;

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<GlobalSettings?> getGlobalSettings() async {
    final doc = await _firestore.collection('settings').doc('global').get();
    if (!doc.exists) return null;
    return GlobalSettings.fromFirestore(doc);
  }

  Stream<GlobalSettings?> watchGlobalSettings() {
    return _firestore.collection('settings').doc('global').snapshots().map((doc) {
      if (!doc.exists) return null;
      return GlobalSettings.fromFirestore(doc);
    });
  }

  Future<void> updateGlobalSettings(GlobalSettings settings, {String? userId}) async {
    final data = settings.toFirestore();
    if (userId != null) {
      data['updatedBy'] = userId;
    }
    await _firestore.collection('settings').doc('global').set(
      data,
      SetOptions(merge: true),
    );
  }

  Future<String> uploadLogo(File file) async {
    final ref = _storage.ref().child('branding/logo_${DateTime.now().millisecondsSinceEpoch}.png');
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }
}
