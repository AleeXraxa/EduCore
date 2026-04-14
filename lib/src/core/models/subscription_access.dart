import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum SubscriptionAccessStatus { active, expired, pending, canceled }

@immutable
class SubscriptionAccess {
  const SubscriptionAccess({
    required this.academyId,
    required this.planId,
    required this.status,
    required this.assignedFeatures,
    required this.overriddenFeatures,
    this.updatedAt,
  });

  final String academyId;
  final String planId;
  final SubscriptionAccessStatus status;
  final List<String> assignedFeatures;
  final Map<String, bool> overriddenFeatures;
  final DateTime? updatedAt;

  static SubscriptionAccess fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return SubscriptionAccess(
      academyId: doc.id,
      planId: (data['planId'] as String?) ?? '',
      status: _statusFrom(data['status'] as String?),
      assignedFeatures: _listString(data['assignedFeatures']),
      overriddenFeatures:
          _mapBool(data['overriddenFeatures'] ?? data['overrides']),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

SubscriptionAccessStatus _statusFrom(String? raw) {
  return switch ((raw ?? '').toLowerCase()) {
    'active' => SubscriptionAccessStatus.active,
    'expired' => SubscriptionAccessStatus.expired,
    'pending' => SubscriptionAccessStatus.pending,
    'canceled' => SubscriptionAccessStatus.canceled,
    _ => SubscriptionAccessStatus.pending,
  };
}

List<String> _listString(Object? value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList(growable: false);
  }
  return const <String>[];
}

Map<String, bool> _mapBool(Object? value) {
  if (value is Map) {
    return value.map(
      (k, v) => MapEntry(k.toString(), v == true),
    );
  }
  return const <String, bool>{};
}
