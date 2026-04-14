import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFFF8FAFC); // slate-50
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF1F5F9); // slate-100

  static const primary = Color(0xFF2563EB); // EduCore Blue
  static const accent = Color(0xFF14B8A6); // teal-500 (minimal use)

  static const text = Color(0xFF0F172A); // slate-900
  static const textMuted = Color(0xFF475569); // slate-600
  static const border = Color(0xFFE2E8F0); // slate-200
}

abstract final class AppRadii {
  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));
}

abstract final class AppSpace {
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
}

abstract final class AppShadows {
  static List<BoxShadow> soft(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.10),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
}
