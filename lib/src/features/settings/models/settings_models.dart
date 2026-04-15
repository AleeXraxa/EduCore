import 'package:flutter/material.dart';

enum SettingsSection {
  general,

  paymentSettings,
  notificationSettings,
  security,
  systemPreferences,
}

enum Currency { pkr, usd }

enum DateFormatOption { ymd, dmy, mdy }

enum ThemePreference { light, dark, system }
