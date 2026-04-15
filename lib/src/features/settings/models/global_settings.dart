import 'package:cloud_firestore/cloud_firestore.dart';

class GlobalSettings {
  final String appName;
  final String appLogoUrl;
  final String supportEmail;
  final String supportPhone;
  final Map<String, PaymentMethodConfig> paymentMethods;
  final DateTime? updatedAt;
  final String? updatedBy;

  GlobalSettings({
    required this.appName,
    required this.appLogoUrl,
    required this.supportEmail,
    required this.supportPhone,
    required this.paymentMethods,
    this.updatedAt,
    this.updatedBy,
  });

  factory GlobalSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final pmData = (data['paymentMethods'] as Map<String, dynamic>?) ?? {};
    
    return GlobalSettings(
      appName: data['appName'] ?? 'EduCore',
      appLogoUrl: data['appLogoUrl'] ?? '',
      supportEmail: data['supportEmail'] ?? '',
      supportPhone: data['supportPhone'] ?? '',
      paymentMethods: pmData.map(
        (key, value) => MapEntry(key, PaymentMethodConfig.fromMap(Map<String, dynamic>.from(value))),
      ),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'appName': appName,
      'appLogoUrl': appLogoUrl,
      'supportEmail': supportEmail,
      'supportPhone': supportPhone,
      'paymentMethods': paymentMethods.map((key, value) => MapEntry(key, value.toMap())),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };
  }

  GlobalSettings copyWith({
    String? appName,
    String? appLogoUrl,
    String? supportEmail,
    String? supportPhone,
    Map<String, PaymentMethodConfig>? paymentMethods,
  }) {
    return GlobalSettings(
      appName: appName ?? this.appName,
      appLogoUrl: appLogoUrl ?? this.appLogoUrl,
      supportEmail: supportEmail ?? this.supportEmail,
      supportPhone: supportPhone ?? this.supportPhone,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }
}

class PaymentMethodConfig {
  final String? number;
  final String? accountNumber;
  final String? accountTitle;
  final String? bankName;
  final bool isActive;

  PaymentMethodConfig({
    this.number,
    this.accountNumber,
    this.accountTitle,
    this.bankName,
    required this.isActive,
  });

  factory PaymentMethodConfig.fromMap(Map<String, dynamic> map) {
    return PaymentMethodConfig(
      number: map['number'],
      accountNumber: map['accountNumber'],
      accountTitle: map['accountTitle'],
      bankName: map['bankName'],
      isActive: map['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (number != null) 'number': number,
      if (accountNumber != null) 'accountNumber': accountNumber,
      if (accountTitle != null) 'accountTitle': accountTitle,
      if (bankName != null) 'bankName': bankName,
      'isActive': isActive,
    };
  }

  PaymentMethodConfig copyWith({
    String? number,
    String? accountNumber,
    String? accountTitle,
    String? bankName,
    bool? isActive,
  }) {
    return PaymentMethodConfig(
      number: number ?? this.number,
      accountNumber: accountNumber ?? this.accountNumber,
      accountTitle: accountTitle ?? this.accountTitle,
      bankName: bankName ?? this.bankName,
      isActive: isActive ?? this.isActive,
    );
  }
}
