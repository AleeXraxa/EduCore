import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/features/features/models/feature_overrides.dart';
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
    this.overrides = const FeatureOverrides(),
    required this.createdAt,
    required this.updatedAt,
    required this.durationMonths,
  });

  final String academyId;
  final String planId;
  final SubscriptionRecordStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final FeatureOverrides overrides;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int durationMonths;

  static SubscriptionRecord fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return SubscriptionRecord(
      academyId: (data['academyId'] as String?) ?? doc.id,
      planId: (data['planId'] as String?) ?? '',
      status: _statusFrom(data['status'] as String?),
      startDate: _tsToDate(data['startDate']),
      endDate: _tsToDate(data['endDate']),
      overrides: _mapOverrides(data['overrides']),
      createdAt: _tsToDate(data['createdAt']),
      updatedAt: _tsToDate(data['updatedAt']),
      durationMonths: (data['durationMonths'] as int?) ?? 1,
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

FeatureOverrides _mapOverrides(Object? value) {
  if (value is Map) {
    return FeatureOverrides.fromMap(value.cast<String, dynamic>());
  }
  return const FeatureOverrides();
}

