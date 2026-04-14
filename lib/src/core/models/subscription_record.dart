import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum SubscriptionRecordStatus { active, expired, pending, canceled }

@immutable
class SubscriptionRecord {
  const SubscriptionRecord({
    required this.academyId,
    required this.planId,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.overrides,
    required this.createdAt,
    required this.updatedAt,
  });

  final String academyId;
  final String planId;
  final SubscriptionRecordStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, bool> overrides;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static SubscriptionRecord fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return SubscriptionRecord(
      academyId: (data['academyId'] as String?) ?? doc.id,
      planId: (data['planId'] as String?) ?? '',
      status: _statusFrom(data['status'] as String?),
      startDate: _tsToDate(data['startDate']),
      endDate: _tsToDate(data['endDate']),
      overrides: _mapBool(data['overriddenFeatures'] ?? data['overrides']),
      createdAt: _tsToDate(data['createdAt']),
      updatedAt: _tsToDate(data['updatedAt']),
    );
  }
}

SubscriptionRecordStatus _statusFrom(String? raw) {
  return switch ((raw ?? '').trim().toLowerCase()) {
    'active' => SubscriptionRecordStatus.active,
    'expired' => SubscriptionRecordStatus.expired,
    'canceled' => SubscriptionRecordStatus.canceled,
    // We use "pending" as the normalized value; legacy data might store
    // "pending_approval" or "pendingApproval".
    'pending_approval' => SubscriptionRecordStatus.pending,
    'pendingapproval' => SubscriptionRecordStatus.pending,
    'pending' => SubscriptionRecordStatus.pending,
    _ => SubscriptionRecordStatus.pending,
  };
}

DateTime? _tsToDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  return null;
}

Map<String, bool> _mapBool(Object? value) {
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v == true));
  }
  return const <String, bool>{};
}

