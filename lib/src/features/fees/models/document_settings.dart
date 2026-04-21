import 'package:cloud_firestore/cloud_firestore.dart';

class ReceiptSettings {
  final bool showLogo;
  final bool showInstituteName;
  final bool showAddress;
  final bool showPhone;
  final bool showStudentInfo;
  final bool showFatherName;
  final bool showClassSection;
  final bool showFeeBreakdown;
  final bool showPaymentDetails;
  final bool showCollectedBy;
  final bool showSignature;
  final String footerNote;

  const ReceiptSettings({
    this.showLogo = true,
    this.showInstituteName = true,
    this.showAddress = true,
    this.showPhone = true,
    this.showStudentInfo = true,
    this.showFatherName = true,
    this.showClassSection = true,
    this.showFeeBreakdown = true,
    this.showPaymentDetails = true,
    this.showCollectedBy = true,
    this.showSignature = true,
    this.footerNote = '',
  });

  Map<String, dynamic> toMap() => {
        'showLogo': showLogo,
        'showInstituteName': showInstituteName,
        'showAddress': showAddress,
        'showPhone': showPhone,
        'showStudentInfo': showStudentInfo,
        'showFatherName': showFatherName,
        'showClassSection': showClassSection,
        'showFeeBreakdown': showFeeBreakdown,
        'showPaymentDetails': showPaymentDetails,
        'showCollectedBy': showCollectedBy,
        'showSignature': showSignature,
        'footerNote': footerNote,
      };

  factory ReceiptSettings.fromMap(Map<String, dynamic> map) => ReceiptSettings(
        showLogo: map['showLogo'] ?? true,
        showInstituteName: map['showInstituteName'] ?? true,
        showAddress: map['showAddress'] ?? true,
        showPhone: map['showPhone'] ?? true,
        showStudentInfo: map['showStudentInfo'] ?? true,
        showFatherName: map['showFatherName'] ?? true,
        showClassSection: map['showClassSection'] ?? true,
        showFeeBreakdown: map['showFeeBreakdown'] ?? true,
        showPaymentDetails: map['showPaymentDetails'] ?? true,
        showCollectedBy: map['showCollectedBy'] ?? true,
        showSignature: map['showSignature'] ?? true,
        footerNote: map['footerNote'] ?? '',
      );
}

class ChallanSettings {
  final bool showLogo;
  final bool showInstituteName;
  final bool showAddress;
  final bool showPhone;
  final bool showStudentInfo;
  final bool showFatherName;
  final bool showClassSection;
  final bool showFeeTable;
  final bool showDueDates;
  final bool showFineDetails;
  final bool showSignatureBox;
  final String footerNote;

  const ChallanSettings({
    this.showLogo = true,
    this.showInstituteName = true,
    this.showAddress = true,
    this.showPhone = true,
    this.showStudentInfo = true,
    this.showFatherName = true,
    this.showClassSection = true,
    this.showFeeTable = true,
    this.showDueDates = true,
    this.showFineDetails = true,
    this.showSignatureBox = true,
    this.footerNote = '',
  });

  Map<String, dynamic> toMap() => {
        'showLogo': showLogo,
        'showInstituteName': showInstituteName,
        'showAddress': showAddress,
        'showPhone': showPhone,
        'showStudentInfo': showStudentInfo,
        'showFatherName': showFatherName,
        'showClassSection': showClassSection,
        'showFeeTable': showFeeTable,
        'showDueDates': showDueDates,
        'showFineDetails': showFineDetails,
        'showSignatureBox': showSignatureBox,
        'footerNote': footerNote,
      };

  factory ChallanSettings.fromMap(Map<String, dynamic> map) => ChallanSettings(
        showLogo: map['showLogo'] ?? true,
        showInstituteName: map['showInstituteName'] ?? true,
        showAddress: map['showAddress'] ?? true,
        showPhone: map['showPhone'] ?? true,
        showStudentInfo: map['showStudentInfo'] ?? true,
        showFatherName: map['showFatherName'] ?? true,
        showClassSection: map['showClassSection'] ?? true,
        showFeeTable: map['showFeeTable'] ?? true,
        showDueDates: map['showDueDates'] ?? true,
        showFineDetails: map['showFineDetails'] ?? true,
        showSignatureBox: map['showSignatureBox'] ?? true,
        footerNote: map['footerNote'] ?? '',
      );
}

class BankDetails {
  final String bankName;
  final String branchName;
  final String accountTitle;
  final String accountNumber;
  final String? iban;

  const BankDetails({
    this.bankName = '',
    this.branchName = '',
    this.accountTitle = '',
    this.accountNumber = '',
    this.iban,
  });

  Map<String, dynamic> toMap() => {
        'bankName': bankName,
        'branchName': branchName,
        'accountTitle': accountTitle,
        'accountNumber': accountNumber,
        'iban': iban,
      };

  factory BankDetails.fromMap(Map<String, dynamic> map) => BankDetails(
        bankName: map['bankName'] ?? '',
        branchName: map['branchName'] ?? '',
        accountTitle: map['accountTitle'] ?? '',
        accountNumber: map['accountNumber'] ?? '',
        iban: map['iban'],
      );
}

class DocumentSettings {
  final ReceiptSettings receiptSettings;
  final ChallanSettings challanSettings;
  final BankDetails bankDetails;

  const DocumentSettings({
    this.receiptSettings = const ReceiptSettings(),
    this.challanSettings = const ChallanSettings(),
    this.bankDetails = const BankDetails(),
  });

  Map<String, dynamic> toMap() => {
        'receiptSettings': receiptSettings.toMap(),
        'challanSettings': challanSettings.toMap(),
        'bankDetails': bankDetails.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory DocumentSettings.fromMap(Map<String, dynamic> map) => DocumentSettings(
        receiptSettings: ReceiptSettings.fromMap(map['receiptSettings'] ?? {}),
        challanSettings: ChallanSettings.fromMap(map['challanSettings'] ?? {}),
        bankDetails: BankDetails.fromMap(map['bankDetails'] ?? {}),
      );
}
