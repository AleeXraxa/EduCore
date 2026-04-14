import 'package:flutter/material.dart';

enum SettingsSection {
  general,
  subscriptionPlans,
  paymentSettings,
  notificationSettings,
  security,
  systemPreferences,
}

@immutable
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.pricePkr,
    required this.durationDays,
    required this.features,
  });

  final String id;
  final String name;
  final int pricePkr;
  final int durationDays;
  final List<String> features;
}

enum Currency { pkr, usd }

enum DateFormatOption { ymd, dmy, mdy }

enum ThemePreference { light, dark, system }

