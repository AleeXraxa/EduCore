enum PaymentMethod { jazzCash, easyPaisa, bankTransfer }

enum PaymentReviewStatus { pending, approved, rejected }

class Payment {
  const Payment({
    required this.id,
    required this.instituteId,
    required this.instituteName,
    required this.amountPkr,
    required this.method,
    required this.submittedAt,
    required this.status,
    required this.proofRef,
  });

  final String id;
  final String instituteId;
  final String instituteName;
  final int amountPkr;
  final PaymentMethod method;
  final DateTime submittedAt;
  final PaymentReviewStatus status;

  /// Placeholder reference for proof. Replace with Firebase Storage URL/path.
  final String proofRef;
}

