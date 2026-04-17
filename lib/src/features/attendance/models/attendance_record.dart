enum AttendanceStatus { present, absent, leave, none }

class AttendanceRecord {
  final String studentId;
  final String studentName;
  final String className;
  final String phone;
  AttendanceStatus status;

  AttendanceRecord({
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.phone,
    this.status = AttendanceStatus.none,
  });

  AttendanceRecord copyWith({
    AttendanceStatus? status,
  }) {
    return AttendanceRecord(
      studentId: studentId,
      studentName: studentName,
      className: className,
      phone: phone,
      status: status ?? this.status,
    );
  }
}
