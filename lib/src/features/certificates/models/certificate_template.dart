import 'package:cloud_firestore/cloud_firestore.dart';

class CertificateTemplate {
  final String id;
  final String academyId;
  final String name;
  final String? backgroundUrl;
  final Map<String, dynamic> config;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  CertificateTemplate({
    required this.id,
    required this.academyId,
    required this.name,
    this.backgroundUrl,
    required this.config,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'academyId': academyId,
      'name': name,
      'backgroundUrl': backgroundUrl,
      'config': config,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory CertificateTemplate.fromMap(String id, Map<String, dynamic> map) {
    return CertificateTemplate(
      id: id,
      academyId: map['academyId'] ?? '',
      name: map['name'] ?? '',
      backgroundUrl: map['backgroundUrl'],
      config: map['config'] ?? {},
      isDefault: map['isDefault'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  CertificateTemplate copyWith({
    String? id,
    String? name,
    String? backgroundUrl,
    Map<String, dynamic>? config,
    bool? isDefault,
    DateTime? updatedAt,
  }) {
    return CertificateTemplate(
      id: id ?? this.id,
      academyId: academyId,
      name: name ?? this.name,
      backgroundUrl: backgroundUrl ?? this.backgroundUrl,
      config: config ?? this.config,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
