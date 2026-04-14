enum SubscriptionStatus { active, pendingApproval, expired, canceled }

enum PaymentStatus { paid, proofSubmitted, unpaid, rejected }

class Subscription {
  const Subscription({
    required this.id,
    required this.instituteId,
    required this.instituteName,
    required this.planId,
    required this.planName,
    required this.status,
    required this.startDate,
    required this.expiryDate,
    required this.amountPkr,
    required this.paymentStatus,
  });

  final String id;
  final String instituteId;
  final String instituteName;
  final String planId;
  final String planName;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime expiryDate;
  final int amountPkr;
  final PaymentStatus paymentStatus;

  int get daysLeft {
    final diff = expiryDate.difference(DateTime.now()).inDays;
    return diff;
  }
}
