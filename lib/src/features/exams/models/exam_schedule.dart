import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ExamSchedule {
  const ExamSchedule({
    required this.id,
    required this.examId,
    required this.classId,
    required this.subjectId,
    required this.subjectName,
    required this.paperDate,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.totalMarks,
    required this.passingMarks,
    this.room,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String examId;
  final String classId;
  final String subjectId;
  final String subjectName;
  final DateTime paperDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int durationMinutes;
  final double totalMarks;
  final double passingMarks;
  final String? room;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExamSchedule copyWith({
    String? id,
    String? examId,
    String? classId,
    String? subjectId,
    String? subjectName,
    DateTime? paperDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    int? durationMinutes,
    double? totalMarks,
    double? passingMarks,
    String? room,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamSchedule(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      classId: classId ?? this.classId,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      paperDate: paperDate ?? this.paperDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      totalMarks: totalMarks ?? this.totalMarks,
      passingMarks: passingMarks ?? this.passingMarks,
      room: room ?? this.room,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'examId': examId,
      'classId': classId,
      'subjectId': subjectId,
      'subjectName': subjectName.trim(),
      'paperDate': Timestamp.fromDate(paperDate),
      'startTimeHour': startTime.hour,
      'startTimeMinute': startTime.minute,
      'endTimeHour': endTime.hour,
      'endTimeMinute': endTime.minute,
      'durationMinutes': durationMinutes,
      'totalMarks': totalMarks,
      'passingMarks': passingMarks,
      'room': room?.trim(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory ExamSchedule.fromMap(String id, Map<String, dynamic> map) {
    return ExamSchedule(
      id: id,
      examId: map['examId'] ?? '',
      classId: map['classId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      subjectName: map['subjectName'] ?? '',
      paperDate: (map['paperDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime: TimeOfDay(
        hour: map['startTimeHour'] as int? ?? 9,
        minute: map['startTimeMinute'] as int? ?? 0,
      ),
      endTime: TimeOfDay(
        hour: map['endTimeHour'] as int? ?? 12,
        minute: map['endTimeMinute'] as int? ?? 0,
      ),
      durationMinutes: map['durationMinutes'] as int? ?? 180,
      totalMarks: (map['totalMarks'] as num?)?.toDouble() ?? 100.0,
      passingMarks: (map['passingMarks'] as num?)?.toDouble() ?? 40.0,
      room: map['room'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
