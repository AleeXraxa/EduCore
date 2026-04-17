import 'package:cloud_firestore/cloud_firestore.dart';

enum CustomFieldType { text, number, date, dropdown }

class StudentCustomField {
  final String id;
  final String key;
  final String label;
  final CustomFieldType type;
  final bool isRequired;
  final List<String> options;
  final bool isActive;
  final DateTime createdAt;

  StudentCustomField({
    required this.id,
    required this.key,
    required this.label,
    required this.type,
    this.isRequired = false,
    this.options = const [],
    this.isActive = true,
    required this.createdAt,
  });

  factory StudentCustomField.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudentCustomField(
      id: doc.id,
      key: data['key'] ?? '',
      label: data['label'] ?? '',
      type: CustomFieldType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => CustomFieldType.text,
      ),
      isRequired: data['isRequired'] ?? false,
      options: List<String>.from(data['options'] ?? []),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'key': key,
      'label': label,
      'type': type.name,
      'isRequired': isRequired,
      'options': options,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
