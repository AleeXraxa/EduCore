import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class Plan {
  const Plan({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.isActive,
    required this.features,
    required this.limits,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final num price;
  final String description;
  final bool isActive;
  final List<String> features;
  final Map<String, num> limits;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static Plan fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Plan(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      price: (data['price'] as num?) ?? 0,
      description: (data['description'] as String?) ?? '',
      isActive: (data['isActive'] as bool?) ?? true,
      features: _mapFeatures(data['features']),
      limits: _mapNum(data['limits']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Plan copyWith({
    String? id,
    String? name,
    num? price,
    String? description,
    bool? isActive,
    List<String>? features,
    Map<String, num>? limits,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Plan(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      features: features ?? this.features,
      limits: limits ?? this.limits,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

List<String> _mapFeatures(Object? value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList(growable: false);
  }
  if (value is Map) {
    final keys = <String>[];
    value.forEach((k, v) {
      if (v == true) keys.add(k.toString());
    });
    return keys;
  }
  return const <String>[];
}

Map<String, num> _mapNum(Object? value) {
  if (value is Map) {
    return value.map((k, v) {
      final numValue = v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;
      return MapEntry(k.toString(), numValue);
    });
  }
  return const <String, num>{};
}
