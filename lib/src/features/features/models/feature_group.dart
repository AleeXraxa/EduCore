import 'package:cloud_firestore/cloud_firestore.dart';

class FeatureGroup {
  const FeatureGroup({
    required this.id,
    required this.name,
    this.description = '',
    this.icon = 'folder',
    this.order = 0,
    this.isSystem = false,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final String icon;
  final int order;
  final bool isSystem;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory FeatureGroup.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeatureGroup(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? 'folder',
      order: data['order'] ?? 0,
      isSystem: data['isSystem'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'order': order,
      'isSystem': isSystem,
      'isDeleted': isDeleted,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  FeatureGroup copyWith({
    String? name,
    String? description,
    String? icon,
    int? order,
    bool? isSystem,
    bool? isDeleted,
  }) {
    return FeatureGroup(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      order: order ?? this.order,
      isSystem: isSystem ?? this.isSystem,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
