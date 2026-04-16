class AuthException implements Exception {
  final String message;
  final String code;

  AuthException(this.message, this.code);

  @override
  String toString() => 'AuthException: $message ($code)';
}

class UserNotFoundException extends AuthException {
  UserNotFoundException() : super('User profile not found.', 'user-not-found');
}

class UserBlockedException extends AuthException {
  UserBlockedException() : super('This user account has been blocked.', 'user-blocked');
}

class InstituteBlockedException extends AuthException {
  InstituteBlockedException() : super('Your institute is currently blocked.', 'institute-blocked');
}

class SubscriptionExpiredException extends AuthException {
  SubscriptionExpiredException() : super('Your subscription has expired.', 'subscription-expired');
}

class SubscriptionInactiveException extends AuthException {
  SubscriptionInactiveException() : super('A valid subscription is required.', 'subscription-inactive');
}
