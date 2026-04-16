import 'package:flutter/material.dart';

/// A centralized validation service for the EduCore platform.
/// 
/// This class provides standardized validation logic for all forms
/// across the application, ensuring data consistency and a premium UX.
abstract final class Validators {
  
  /// Validates standard text input.
  /// 
  /// Rules:
  /// - Required (cannot be empty or just spaces)
  /// - Minimum 2 characters
  static String? validateText(String? value, {String? label}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return label != null ? '$label is required' : 'This field is required';
    }
    if (text.length < 2) {
      return 'Enter valid text (min 2 characters)';
    }
    return null;
  }

  /// Validates Pakistani mobile numbers.
  /// 
  /// Rules:
  /// - Must start with '03'
  /// - Exactly 11 digits
  /// - Only numeric
  static String? validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) {
      return 'Mobile number is required';
    }
    
    // Check if numeric
    if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
      return 'Enter valid mobile number (digits only)';
    }

    if (phone.length != 11) {
      return 'Mobile number must be 11 digits';
    }

    if (!phone.startsWith('03')) {
      return 'Enter valid mobile number (03XXXXXXXXX)';
    }

    return null;
  }

  /// Validates email addresses using RFC 5322 regex.
  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email address is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&'
      r"'"
      r'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  /// Validates password strength.
  /// 
  /// Rules:
  /// - Minimum 6 characters
  /// - Not empty
  static String? validatePassword(String? value) {
    final pass = value ?? '';
    if (pass.isEmpty) {
      return 'Password is required';
    }
    if (pass.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Ensures two password entries match.
  static String? validateConfirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates numeric input.
  static String? validateNumeric(String? value, {String? label}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return label != null ? '$label is required' : 'This field is required';
    }
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(text)) {
      return 'Please enter a valid number';
    }
    return null;
  }

  /// Validates feature/resource keys (snake_case).
  static String? validateFeatureKey(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Key is required';
    }
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(text)) {
      return 'Use lowercase, numbers and underscores only';
    }
    return null;
  }

  /// Validates date selection.
  static String? validateDate(DateTime? value, {String? label}) {
    if (value == null) {
      return label != null ? '$label is required' : 'Please select a valid date';
    }
    return null;
  }

  /// High-level method to validate an entire map of data against a ruleset.
  /// Useful for service-layer enforcement.
  static void enforce(Map<String, dynamic> data, Map<String, String? Function(dynamic)> rules) {
    for (final entry in rules.entries) {
      final key = entry.key;
      final validator = entry.value;
      final value = data[key];
      
      final error = validator(value);
      if (error != null) {
        throw ArgumentError('Validation failed for $key: $error');
      }
    }
  }
}
