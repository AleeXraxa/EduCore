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
    this.isSystem = false,
    this.isDeleted = false,
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
  final bool isSystem;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static FeatureFlag fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    
    // Schema Fallbacks
    final key = (data['key'] as String?) ?? (data['keyLower'] as String?) ?? '';
    final label = (data['label'] as String?) ?? (data['name'] as String?) ?? '';
    final group = (data['group'] as String?) ?? (data['category'] as String?) ?? 'General';
    
    return FeatureFlag(
      id: doc.id,
      key: key,
      label: label,
      description: (data['description'] as String?) ?? '',
      group: group,
      isActive: (data['isActive'] as bool?) ?? true,
      icon: (data['icon'] as String?)?.trim().isEmpty == true
          ? null
          : data['icon'] as String?,
      order: (data['order'] as num?)?.toInt() ?? 0,
      isSystem: (data['isSystem'] as bool?) ?? false,
      isDeleted: (data['isDeleted'] as bool?) ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  FeatureFlag copyWith({
    String? label,
    String? description,
    String? group,
    bool? isActive,
    String? icon,
    int? order,
    bool? isDeleted,
  }) {
    return FeatureFlag(
      id: id,
      key: key,
      label: label ?? this.label,
      description: description ?? this.description,
      group: group ?? this.group,
      isActive: isActive ?? this.isActive,
      icon: icon ?? this.icon,
      order: order ?? this.order,
      isSystem: isSystem,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
