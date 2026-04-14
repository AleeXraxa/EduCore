import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class FeatureFlag {
  const FeatureFlag({
    required this.id,
    required this.key,
    required this.label,
    required this.description,
    required this.group,
    required this.isActive,
    this.icon,
    this.order = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String key;
  final String label;
  final String description;
  final String group;
  final bool isActive;
  final String? icon;
  final int order;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static FeatureFlag fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return FeatureFlag(
      id: doc.id,
      key: (data['key'] as String?) ?? '',
      label: (data['label'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      group: (data['group'] as String?) ?? 'General',
      isActive: (data['isActive'] as bool?) ?? true,
      icon: (data['icon'] as String?)?.trim().isEmpty == true
          ? null
          : data['icon'] as String?,
      order: (data['order'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

