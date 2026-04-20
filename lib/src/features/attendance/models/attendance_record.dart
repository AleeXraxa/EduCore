import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { present, absent, leave, none }

class AttendanceRecord {
  final String? id;
  final String studentId;
  final String studentName;
  final String classId;
  final String className;
  final String phone;
  final DateTime date;
  AttendanceStatus status;

  AttendanceRecord({
    this.id,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.className,
    required this.phone,
    required this.date,
    this.status = AttendanceStatus.none,
  });

  factory AttendanceRecord.fromMap(String id, Map<String, dynamic> map) {
    return AttendanceRecord(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      classId: map['classId'] ?? '',
      className: map['className'] ?? '',
      phone: map['phone'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'none'),
        orElse: () => AttendanceStatus.none,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'classId': classId,
      'className': className,
      'phone': phone,
      'date': Timestamp.fromDate(date),
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AttendanceRecord copyWith({
    AttendanceStatus? status,
  }) {
    return AttendanceRecord(
      id: id,
      studentId: studentId,
      studentName: studentName,
      classId: classId,
      className: className,
      phone: phone,
      date: date,
      status: status ?? this.status,
    );
  }
}
