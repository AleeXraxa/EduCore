import 'package:cloud_firestore/cloud_firestore.dart';

enum StaffRole {
  teacher,
  accountant,
  admin,
  custom,
}

class StaffMember {
  final String id;
  final String name;
  final String email;
  final String phone;
  final StaffRole role;
  final String? customRoleName;
  final List<String> assignedFeatureKeys;
  final List<String> deniedFeatureKeys;
  final List<String> assignedClassIds;
  final bool isActive;
  final String status;
  final DateTime createdAt;

  StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.customRoleName,
    required this.assignedFeatureKeys,
    required this.deniedFeatureKeys,
    this.assignedClassIds = const [],
    required this.isActive,
    this.status = 'active',
    required this.createdAt,
  });

  String get roleDisplayName {
    if (role == StaffRole.custom && customRoleName != null) {
      return customRoleName!;
    }
    return role.name.substring(0, 1).toUpperCase() + role.name.substring(1);
  }

  factory StaffMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StaffMember(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: StaffRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => StaffRole.custom,
      ),
      customRoleName: data['customRoleName'],
      assignedFeatureKeys: List<String>.from(data['assignedFeatureKeys'] ?? []),
      deniedFeatureKeys: List<String>.from(data['deniedFeatureKeys'] ?? []),
      assignedClassIds: List<String>.from(data['assignedClassIds'] ?? []),
      isActive: data['isActive'] ?? true,
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'customRoleName': customRoleName,
      'assignedFeatureKeys': assignedFeatureKeys,
      'deniedFeatureKeys': deniedFeatureKeys,
      'assignedClassIds': assignedClassIds,
      'isActive': isActive,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  StaffMember copyWith({
    String? name,
    String? email,
    String? phone,
    StaffRole? role,
    String? customRoleName,
    List<String>? assignedFeatureKeys,
    List<String>? deniedFeatureKeys,
    List<String>? assignedClassIds,
    bool? isActive,
    String? status,
  }) {
    return StaffMember(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      customRoleName: customRoleName ?? this.customRoleName,
      assignedFeatureKeys: assignedFeatureKeys ?? this.assignedFeatureKeys,
      deniedFeatureKeys: deniedFeatureKeys ?? this.deniedFeatureKeys,
      assignedClassIds: assignedClassIds ?? this.assignedClassIds,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
