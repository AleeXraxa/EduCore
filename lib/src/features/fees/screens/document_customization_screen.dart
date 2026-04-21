import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/services/fee_document_service.dart';
import 'package:educore/src/features/fees/models/document_settings.dart';
import 'package:flutter/material.dart';

class DocumentCustomizationScreen extends StatefulWidget {
  const DocumentCustomizationScreen({super.key});

  @override
  State<DocumentCustomizationScreen> createState() => _DocumentCustomizationScreenState();
}

class _DocumentCustomizationScreenState extends State<DocumentCustomizationScreen>
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

      // Update settings object from controllers
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
          const SnackBar(content: Text('Settings saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Customization'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Receipt', icon: Icon(Icons.receipt_long_rounded)),
            Tab(text: 'Challan', icon: Icon(Icons.account_balance_wallet_rounded)),
            Tab(text: 'Bank Details', icon: Icon(Icons.account_balance_rounded)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: const Text('Save Changes'),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReceiptTab(cs),
          _buildChallanTab(cs),
          _buildBankTab(cs),
        ],
      ),
    );
  }

  Widget _buildReceiptTab(ColorScheme cs) {
    final rs = _settings.receiptSettings;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _SectionHeader(title: 'Visibility Flags', color: cs.primary),
        _ToggleTile(
          title: 'Show Logo',
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
          title: 'Show Address',
          value: rs.showAddress,
          onChanged: (v) => setState(() => _settings = _settings.copyWith(
            receiptSettings: rs.copyWith(showAddress: v),
          )),
        ),
        _ToggleTile(
          title: 'Show Student Info',
          value: rs.showStudentInfo,
          onChanged: (v) => setState(() => _settings = _settings.copyWith(
            receiptSettings: rs.copyWith(showStudentInfo: v),
          )),
        ),
        _ToggleTile(
          title: 'Show Fee Breakdown',
          value: rs.showFeeBreakdown,
          onChanged: (v) => setState(() => _settings = _settings.copyWith(
            receiptSettings: rs.copyWith(showFeeBreakdown: v),
          )),
        ),
        _ToggleTile(
          title: 'Show Signature Box',
          value: rs.showSignature,
          onChanged: (v) => setState(() => _settings = _settings.copyWith(
            receiptSettings: rs.copyWith(showSignature: v),
          )),
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Footer Note', color: cs.primary),
        TextField(
          controller: _receiptFooterCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter custom footer message for receipts...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildChallanTab(ColorScheme cs) {
    final cs_ = _settings.challanSettings;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _SectionHeader(title: 'Visibility Flags', color: cs.primary),
        _ToggleTile(
          title: 'Show Logo',
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
          title: 'Show Due Dates',
          value: cs_.showDueDates,
          onChanged: (v) => setState(() => _settings = _settings.copyWith(
            challanSettings: cs_.copyWith(showDueDates: v),
          )),
        ),
        _ToggleTile(
          title: 'Show Fine Details',
          value: cs_.showFineDetails,
          onChanged: (v) => setState(() => _settings = _settings.copyWith(
            challanSettings: cs_.copyWith(showFineDetails: v),
          )),
        ),
        _ToggleTile(
          title: 'Show Signature Box',
          value: cs_.showSignatureBox,
          onChanged: (v) => setState(() => _settings = _settings.copyWith(
            challanSettings: cs_.copyWith(showSignatureBox: v),
          )),
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Custom Message', color: cs.primary),
        TextField(
          controller: _challanFooterCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter custom instructions for challans...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildBankTab(ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _SectionHeader(title: 'Bank Information', color: cs.primary),
        const Text(
          'These details will appear on the Bank Challan (3-Copy document). If left empty, default institute details will be used.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 16),
        _BankField(label: 'Bank Name', controller: _bankNameCtrl, icon: Icons.account_balance_rounded),
        _BankField(label: 'Branch Name', controller: _branchNameCtrl, icon: Icons.map_rounded),
        _BankField(label: 'Account Title', controller: _accTitleCtrl, icon: Icons.person_rounded),
        _BankField(label: 'Account Number', controller: _accNumberCtrl, icon: Icons.numbers_rounded),
        _BankField(label: 'IBAN (Optional)', controller: _ibanCtrl, icon: Icons.public_rounded),
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
          Container(width: 4, height: 24, color: color),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _BankField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  const _BankField({required this.label, required this.controller, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// Helper extension to make updating immutable settings easier
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
