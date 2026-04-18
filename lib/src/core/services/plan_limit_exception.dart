class PlanLimitExceededException implements Exception {
  final String message;
  final String limitKey;

  PlanLimitExceededException(this.message, {required this.limitKey});

  @override
  String toString() => 'PlanLimitExceededException: $message';
}
