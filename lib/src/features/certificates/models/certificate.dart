import 'package:cloud_firestore/cloud_firestore.dart';

enum CertificateType {
  character('Character Certificate'),
  completion('Completion Certificate'),
  achievement('Achievement Certificate'),
  participation('Participation Certificate'),
  bonafide('Bonafide Certificate'),
  leaving('Leaving Certificate'),
  custom('Custom');

  const CertificateType(this.label);
  final String label;
}

class Certificate {
  final String id;
  final String studentId;
  final String studentName;
  final String? studentRollNo;
  final String? className;
  final CertificateType type;
  final String title;
  final String body;
  final DateTime issueDate;
  final DateTime? validUntil;
  final String authorizedSignatory;
  final String? remarks;
  final int downloadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String academyId;
  final String academyName;
  final String? templateId;
  final String? templateBackgroundUrl;


  Certificate({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.studentRollNo,
    this.className,
    required this.type,
    required this.title,
    required this.body,
    required this.issueDate,
    this.validUntil,
    required this.authorizedSignatory,
    this.remarks,
    this.downloadCount = 0,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.academyId,
    required this.academyName,
    this.templateId,
    this.templateBackgroundUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentRollNo': studentRollNo,
      'className': className,
      'type': type.name,
      'title': title,
      'body': body,
      'issueDate': Timestamp.fromDate(issueDate),
      'validUntil': validUntil != null ? Timestamp.fromDate(validUntil!) : null,
      'authorizedSignatory': authorizedSignatory,
      'remarks': remarks,
      'downloadCount': downloadCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'academyId': academyId,
      'academyName': academyName,
      'templateId': templateId,
      'templateBackgroundUrl': templateBackgroundUrl,
    };
  }

  factory Certificate.fromMap(String id, Map<String, dynamic> map) {
    return Certificate(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      studentRollNo: map['studentRollNo'],
      className: map['className'],
      type: CertificateType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CertificateType.custom,
      ),
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      issueDate: (map['issueDate'] as Timestamp).toDate(),
      validUntil: (map['validUntil'] as Timestamp?)?.toDate(),
      authorizedSignatory: map['authorizedSignatory'] ?? '',
      remarks: map['remarks'],
      downloadCount: map['downloadCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] ?? '',
      academyId: map['academyId'] ?? '',
      academyName: map['academyName'] ?? '',
      templateId: map['templateId'],
      templateBackgroundUrl: map['templateBackgroundUrl'],
    );
  }

  Certificate copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? studentRollNo,
    String? className,
    CertificateType? type,
    String? title,
    String? body,
    DateTime? issueDate,
    DateTime? validUntil,
    String? authorizedSignatory,
    String? remarks,
    int? downloadCount,
    DateTime? updatedAt,
    String? academyId,
    String? academyName,
    String? templateId,
    String? templateBackgroundUrl,
  }) {
    return Certificate(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentRollNo: studentRollNo ?? this.studentRollNo,
      className: className ?? this.className,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      issueDate: issueDate ?? this.issueDate,
      validUntil: validUntil ?? this.validUntil,
      authorizedSignatory: authorizedSignatory ?? this.authorizedSignatory,
      remarks: remarks ?? this.remarks,
      downloadCount: downloadCount ?? this.downloadCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy,
      academyId: academyId ?? this.academyId,
      academyName: academyName ?? this.academyName,
      templateId: templateId ?? this.templateId,
      templateBackgroundUrl: templateBackgroundUrl ?? this.templateBackgroundUrl,
    );
  }
}
