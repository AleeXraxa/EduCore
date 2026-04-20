import 'package:cloud_firestore/cloud_firestore.dart';

class InstituteClass {
  const InstituteClass({
    required this.id,
    required this.name,
    this.section = '',
    this.classTeacherId,
    this.classTeacherName,
    this.teacherIds = const [],
    required this.subjectIds,
    this.studentCount = 0,
    this.isActive = true,
    this.feePlanId,
    this.feePlanName,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name; // e.g. "Grade 10", "Class 5"
  final String section; // optional, e.g. "A", "B"
  final String? classTeacherId;
  final String? classTeacherName; // useful for UI without extra joins
  final List<String> teacherIds;
  final List<String> subjectIds;
  final int studentCount;
  final bool isActive;
  final String? feePlanId;
  final String? feePlanName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayName => section.isEmpty ? name : '$name - $section';

  factory InstituteClass.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return InstituteClass(
      id: doc.id,
      name: data['name'] as String? ?? '',
      section: data['section'] as String? ?? '',
      classTeacherId: data['classTeacherId'] as String?,
      classTeacherName: data['classTeacherName'] as String?,
      teacherIds: List<String>.from(data['teacherIds'] ?? []),
      subjectIds: List<String>.from(data['subjectIds'] ?? []),
      studentCount: data['studentCount'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      feePlanId: data['feePlanId'] as String?,
      feePlanName: data['feePlanName'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'section': section.trim(),
      'classTeacherId': classTeacherId,
      'classTeacherName': classTeacherName,
      'teacherIds': teacherIds,
      'subjectIds': subjectIds,
      'studentCount': studentCount,
      'isActive': isActive,
      'feePlanId': feePlanId,
      'feePlanName': feePlanName,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  InstituteClass copyWith({
    String? id,
    String? name,
    String? section,
    String? classTeacherId,
    String? classTeacherName,
    List<String>? teacherIds,
    List<String>? subjectIds,
    int? studentCount,
    bool? isActive,
    String? feePlanId,
    String? feePlanName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InstituteClass(
      id: id ?? this.id,
      name: name ?? this.name,
      section: section ?? this.section,
      classTeacherId: classTeacherId ?? this.classTeacherId,
      classTeacherName: classTeacherName ?? this.classTeacherName,
      teacherIds: teacherIds ?? this.teacherIds,
      subjectIds: subjectIds ?? this.subjectIds,
      studentCount: studentCount ?? this.studentCount,
      isActive: isActive ?? this.isActive,
      feePlanId: feePlanId ?? this.feePlanId,
      feePlanName: feePlanName ?? this.feePlanName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
