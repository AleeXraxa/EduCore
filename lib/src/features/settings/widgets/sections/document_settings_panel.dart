import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/services/fee_document_service.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/fees/models/document_settings.dart';
import 'package:educore/src/features/settings/settings_controller.dart';
import 'package:flutter/material.dart';

class DocumentSettingsPanel extends StatefulWidget {
  const DocumentSettingsPanel({super.key, required this.controller});

  final SettingsController controller;

  @override
  State<DocumentSettingsPanel> createState() => _DocumentSettingsPanelState();
}

class _DocumentSettingsPanelState extends State<DocumentSettingsPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _docService = FeeDocumentService();

  DocumentSettings _settings = const DocumentSettings();
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers for text fields
  final _receiptFooterCtrl = TextEditingController();
  final _challanFooterCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _branchNameCtrl = TextEditingController();
  final _accTitleCtrl = TextEditingController();
  final _accNumberCtrl = TextEditingController();
  final _ibanCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final academyId = FeeDocumentService.currentAcademyId;
    final settings = await _docService.getDocumentSettings(academyId);

    if (mounted) {
      setState(() {
        _settings = settings;
        _receiptFooterCtrl.text = settings.receiptSettings.footerNote;
        _challanFooterCtrl.text = settings.challanSettings.footerNote;
        _bankNameCtrl.text = settings.bankDetails.bankName;
        _branchNameCtrl.text = settings.bankDetails.branchName;
        _accTitleCtrl.text = settings.bankDetails.accountTitle;
        _accNumberCtrl.text = settings.bankDetails.accountNumber;
        _ibanCtrl.text = settings.bankDetails.iban ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final academyId = FeeDocumentService.currentAcademyId;
      final auth = AppServices.instance.authService!;
      final actorId = auth.session!.user.uid;

      final updatedSettings = DocumentSettings(
        receiptSettings: _settings.receiptSettings.copyWith(
          footerNote: _receiptFooterCtrl.text,
        ),
        challanSettings: _settings.challanSettings.copyWith(
          footerNote: _challanFooterCtrl.text,
        ),
        bankDetails: BankDetails(
          bankName: _bankNameCtrl.text,
          branchName: _branchNameCtrl.text,
          accountTitle: _accTitleCtrl.text,
          accountNumber: _accNumberCtrl.text,
          iban: _ibanCtrl.text.isEmpty ? null : _ibanCtrl.text,
        ),
      );

      await _docService.updateDocumentSettings(
        academyId,
        updatedSettings,
        actorId: actorId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document settings saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving document settings: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 400,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Document Customization',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configure institutional branding for receipts and challans.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            AppPrimaryButton(
              label: 'Save Configuration',
              icon: Icons.done_all_rounded,
              busy: _isSaving,
              onPressed: _saveSettings,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: AppRadii.r20,
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: 'RECEIPT', icon: Icon(Icons.receipt_long_rounded, size: 20)),
                  Tab(text: 'CHALLAN', icon: Icon(Icons.account_balance_wallet_rounded, size: 20)),
                  Tab(text: 'BANKING', icon: Icon(Icons.account_balance_rounded, size: 20)),
                ],
              ),
              const Divider(height: 1),
              SizedBox(
                height: 500,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildReceiptTab(cs),
                    _buildChallanTab(cs),
                    _buildBankTab(cs),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptTab(ColorScheme cs) {
    final rs = _settings.receiptSettings;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _SectionHeader(title: 'Visibility Flags', color: cs.primary),
        _ToggleTile(
          title: 'Show Institutional Logo',
          value: rs.showLogo,
          onChanged: (v) => setState(() => _settings = _settings.copyWith(
                receiptSettings: rs.copyWith(showLogo: v),
              )),
        ),
        _ToggleTile(
          title: 'Show Institute Name',
          value: rs.showInstituteName,
          onChanged: (v) => setState(() => _settings = _settings.copyWith(
                receiptSettings: rs.copyWith(showInstituteName: v),
              )),
        ),
        _ToggleTile(
          title: 'Show Address Details',
          value: rs.showAddress,
          onChanged: (v) => setState(() => _settings = _settings.copyWith(
                receiptSettings: rs.copyWith(showAddress: v),
              )),
        ),
        _ToggleTile(
          title: 'Show Student Information',
          value: rs.showStudentInfo,
          onChanged: (v) => setState(() => _settings = _settings.copyWith(
                receiptSettings: rs.copyWith(showStudentInfo: v),
              )),
        ),
        _ToggleTile(
          title: 'Show Detailed Fee Breakdown',
          value: rs.showFeeBreakdown,
          onChanged: (v) => setState(() => _settings = _settings.copyWith(
                receiptSettings: rs.copyWith(showFeeBreakdown: v),
              )),
        ),
        _ToggleTile(
          title: 'Show Signature Pad',
          value: rs.showSignature,
          onChanged: (v) => setState(() => _settings = _settings.copyWith(
                receiptSettings: rs.copyWith(showSignature: v),
              )),
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Custom Footer Message', color: cs.primary),
        AppTextField(
          label: 'Footer Note',
          maxLines: 3,
          controller: _receiptFooterCtrl,
          hintText: 'e.g. This is a computer generated receipt...',
        ),
      ],
    );
  }

  Widget _buildChallanTab(ColorScheme cs) {
    final cs_ = _settings.challanSettings;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _SectionHeader(title: 'Display Configurations', color: cs.primary),
        _ToggleTile(
          title: 'Show Logo on Challan',
          value: cs_.showLogo,
          onChanged: (v) => setState(() => _settings = _settings.copyWith(
                challanSettings: cs_.copyWith(showLogo: v),
              )),
        ),
        _ToggleTile(
          title: 'Show Institute Name',
          value: cs_.showInstituteName,
          onChanged: (v) => setState(() => _settings = _settings.copyWith(
                challanSettings: cs_.copyWith(showInstituteName: v),
              )),
        ),
        _ToggleTile(
          title: 'Show Student Info',
          value: cs_.showStudentInfo,
          onChanged: (v) => setState(() => _settings = _settings.copyWith(
                challanSettings: cs_.copyWith(showStudentInfo: v),
              )),
        ),
        _ToggleTile(
          title: 'Show Due Dates & Valid Until',
          value: cs_.showDueDates,
          onChanged: (v) => setState(() => _settings = _settings.copyWith(
                challanSettings: cs_.copyWith(showDueDates: v),
              )),
        ),
        _ToggleTile(
          title: 'Show Fine Policy Details',
          value: cs_.showFineDetails,
          onChanged: (v) => setState(() => _settings = _settings.copyWith(
                challanSettings: cs_.copyWith(showFineDetails: v),
              )),
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Challan Instructions', color: cs.primary),
        AppTextField(
          label: 'Special Instructions',
          maxLines: 3,
          controller: _challanFooterCtrl,
          hintText: 'e.g. Please pay before the due date to avoid fines...',
        ),
      ],
    );
  }

  Widget _buildBankTab(ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _SectionHeader(title: 'Banking Information', color: cs.primary),
        const Text(
          'These details will strictly appear on the Bank Challan (3-Copy document). If left empty, default institutional details will be used.',
          style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        AppTextField(label: 'Bank Name', controller: _bankNameCtrl),
        const SizedBox(height: 12),
        AppTextField(label: 'Branch Name', controller: _branchNameCtrl),
        const SizedBox(height: 12),
        AppTextField(label: 'Account Title', controller: _accTitleCtrl),
        const SizedBox(height: 12),
        AppTextField(label: 'Account Number', controller: _accNumberCtrl),
        const SizedBox(height: 12),
        AppTextField(label: 'IBAN (Recommended)', controller: _ibanCtrl),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _receiptFooterCtrl.dispose();
    _challanFooterCtrl.dispose();
    _bankNameCtrl.dispose();
    _branchNameCtrl.dispose();
    _accTitleCtrl.dispose();
    _accNumberCtrl.dispose();
    _ibanCtrl.dispose();
    super.dispose();
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(width: 4, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: cs.primary,
        contentPadding: EdgeInsets.zero,
        dense: true,
      ),
    );
  }
}

extension on DocumentSettings {
  DocumentSettings copyWith({
    ReceiptSettings? receiptSettings,
    ChallanSettings? challanSettings,
    BankDetails? bankDetails,
  }) {
    return DocumentSettings(
      receiptSettings: receiptSettings ?? this.receiptSettings,
      challanSettings: challanSettings ?? this.challanSettings,
      bankDetails: bankDetails ?? this.bankDetails,
    );
  }
}

extension on ReceiptSettings {
  ReceiptSettings copyWith({
    bool? showLogo,
    bool? showInstituteName,
    bool? showAddress,
    bool? showPhone,
    bool? showStudentInfo,
    bool? showFatherName,
    bool? showClassSection,
    bool? showFeeBreakdown,
    bool? showPaymentDetails,
    bool? showCollectedBy,
    bool? showSignature,
    String? footerNote,
  }) {
    return ReceiptSettings(
      showLogo: showLogo ?? this.showLogo,
      showInstituteName: showInstituteName ?? this.showInstituteName,
      showAddress: showAddress ?? this.showAddress,
      showPhone: showPhone ?? this.showPhone,
      showStudentInfo: showStudentInfo ?? this.showStudentInfo,
      showFatherName: showFatherName ?? this.showFatherName,
      showClassSection: showClassSection ?? this.showClassSection,
      showFeeBreakdown: showFeeBreakdown ?? this.showFeeBreakdown,
      showPaymentDetails: showPaymentDetails ?? this.showPaymentDetails,
      showCollectedBy: showCollectedBy ?? this.showCollectedBy,
      showSignature: showSignature ?? this.showSignature,
      footerNote: footerNote ?? this.footerNote,
    );
  }
}

extension on ChallanSettings {
  ChallanSettings copyWith({
    bool? showLogo,
    bool? showInstituteName,
    bool? showAddress,
    bool? showPhone,
    bool? showStudentInfo,
    bool? showFatherName,
    bool? showClassSection,
    bool? showFeeTable,
    bool? showDueDates,
    bool? showFineDetails,
    bool? showSignatureBox,
    String? footerNote,
  }) {
    return ChallanSettings(
      showLogo: showLogo ?? this.showLogo,
      showInstituteName: showInstituteName ?? this.showInstituteName,
      showAddress: showAddress ?? this.showAddress,
      showPhone: showPhone ?? this.showPhone,
      showStudentInfo: showStudentInfo ?? this.showStudentInfo,
      showFatherName: showFatherName ?? this.showFatherName,
      showClassSection: showClassSection ?? this.showClassSection,
      showFeeTable: showFeeTable ?? this.showFeeTable,
      showDueDates: showDueDates ?? this.showDueDates,
      showFineDetails: showFineDetails ?? this.showFineDetails,
      showSignatureBox: showSignatureBox ?? this.showSignatureBox,
      footerNote: footerNote ?? this.footerNote,
    );
  }
}
