import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/services/institute_service.dart';
import 'package:flutter/foundation.dart';

// Legacy UI plan enum used by older mock screens (e.g. Subscriptions).
// The real SaaS plans are stored in Firestore `plans/`.
enum InstitutePlan { basic, standard, premium }

@immutable
class Institute {
  const Institute({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.address,
    required this.planId,
    required this.status,
    required this.studentsCount,
    required this.createdAt,
  });

  final String id; // academyId
  final String name;
  final String ownerName;
  final String email;
  final String phone;
  final String address;
  final String planId;
  final AcademyStatus status;
  final int studentsCount;
  final DateTime? createdAt;

  static Institute fromAcademyDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Institute(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      ownerName: (data['ownerName'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      address: (data['address'] as String?) ?? '',
      planId: (data['planId'] as String?) ?? '',
      status: AcademyStatus.fromValue(data['status'] as String?),
      studentsCount: (data['studentsCount'] as int?) ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Institute copyWith({
    String? id,
    String? name,
    String? ownerName,
    String? email,
    String? phone,
    String? address,
    String? planId,
    AcademyStatus? status,
    int? studentsCount,
    DateTime? createdAt,
  }) {
    return Institute(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerName: ownerName ?? this.ownerName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      planId: planId ?? this.planId,
      status: status ?? this.status,
      studentsCount: studentsCount ?? this.studentsCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
