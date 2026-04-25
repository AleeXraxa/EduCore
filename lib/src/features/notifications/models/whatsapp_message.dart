import 'package:cloud_firestore/cloud_firestore.dart';

enum WhatsAppMessageStatus {
  pending,
  sent,
  failed,
}

class WhatsAppMessage {
  final String id;
  final String recipient;
  final String message;
  final WhatsAppMessageStatus status;
  final DateTime? sentAt;
  final DateTime createdAt;
  final String? error;
  final String? studentId;
  final String? studentName;
  final String type; // 'individual', 'broadcast', 'template'

  const WhatsAppMessage({
    required this.id,
    required this.recipient,
    required this.message,
    required this.status,
    this.sentAt,
    required this.createdAt,
    this.error,
    this.studentId,
    this.studentName,
    required this.type,
  });

  factory WhatsAppMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WhatsAppMessage(
      id: doc.id,
      recipient: data['recipient'] ?? '',
      message: data['message'] ?? '',
      status: WhatsAppMessageStatus.values.byName(data['status'] ?? 'pending'),
      sentAt: (data['sentAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      error: data['error'],
      studentId: data['studentId'],
      studentName: data['studentName'],
      type: data['type'] ?? 'individual',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'recipient': recipient,
      'message': message,
      'status': status.name,
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'error': error,
      'studentId': studentId,
      'studentName': studentName,
      'type': type,
    };
  }
}
