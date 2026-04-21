import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:educore/src/features/fees/models/fee.dart';
import 'package:educore/src/features/fees/models/fee_transaction.dart';
import 'package:educore/src/core/services/fee_document_service.dart';
import 'package:educore/src/features/fees/services/fee_pdf_generator.dart';
import 'package:educore/src/features/fees/services/bank_challan_generator.dart';
import 'package:educore/src/features/fees/views/fee_document_preview_page.dart';
import 'package:educore/src/core/ui/widgets/app_toasts.dart';
import 'package:educore/src/app/theme/app_tokens.dart';

/// Dialog that handles the full challan/receipt generation + print/share flow.
class FeeDocumentDialog extends StatefulWidget {
  const FeeDocumentDialog({
    super.key,
    required this.fee,
    required this.mode, // 'challan' | 'receipt'
    this.selectedTransaction,
  });

  final Fee fee;
  final String mode;
  final FeeTransaction? selectedTransaction;

  @override
  State<FeeDocumentDialog> createState() => _FeeDocumentDialogState();
}

class _FeeDocumentDialogState extends State<FeeDocumentDialog> {
  final _docService = FeeDocumentService();
  bool _isGenerating = false;
  bool _isPrinting = false;
  bool _isSharing = false;
  String? _documentNumber;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-populate if already generated
    if (widget.mode == 'challan') {
      _documentNumber = widget.fee.challanNumber;
    } else {
      _documentNumber = widget.selectedTransaction?.receiptNumber ??
          widget.fee.receiptNumber;
    }
    // Auto-generate if not yet assigned
    if (_documentNumber == null) {
      if (widget.mode == 'challan' && widget.fee.status == FeeStatus.paid) {
        _error = 'Cannot generate a challan for a fully paid fee.';
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
    }
  }

  Future<void> _generate() async {
    setState(() {
      _isGenerating = true;
      _error = null;
    });
    try {
      final academyId = FeeDocumentService.currentAcademyId;
      final actorId = FeeDocumentService.currentUserId;

      if (widget.mode == 'challan') {
        _documentNumber = await _docService.generateChallan(
          academyId,
          widget.fee.id,
          actorId: actorId,
        );
      } else {
        final txn = widget.selectedTransaction ??
            await _docService.getLatestTransaction(academyId, widget.fee.id);
        if (txn == null) {
          setState(() {
            _error = 'No payment found. Collect a payment first.';
            _isGenerating = false;
          });
          return;
        }
        _documentNumber = await _docService.generateReceipt(
          academyId,
          widget.fee.id,
          transactionId: txn.id,
          actorId: actorId,
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<FeeDocumentData> _buildDocData() async {
    final academyId = FeeDocumentService.currentAcademyId;
    final [info, txns] = await Future.wait([
      _docService.getAcademyInfo(academyId),
      _docService.getAllTransactions(academyId, widget.fee.id),
    ]);
    return FeeDocumentData(
      fee: widget.fee,
      transactions: txns as List<FeeTransaction>,
      academyName: (info as Map<String, String>)['name']!,
      academyAddress: info['address']!,
      academyPhone: info['phone']!,
      academyEmail: info['email']!,
      documentMode: widget.mode,
      challanNumber: widget.mode == 'challan' ? _documentNumber : null,
      receiptNumber: widget.mode == 'receipt' ? _documentNumber : null,
      generatedAt: DateTime.now(),
    );
  }

  Future<void> _preview() async {
    setState(() => _isPrinting = true);
    try {
      if (widget.mode == 'challan') {
        // For Challan mode, the primary document is the Bank Voucher
        final academyId = FeeDocumentService.currentAcademyId;
        final data =
            await _docService.getBankChallanData(academyId, widget.fee.id);
        if (mounted) {
          await Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) => FeeDocumentPreviewPage(
                title: 'Bank Challan - ${data.challanNumber}',
                buildPdf: (format) => BankChallanPdfGenerator.generateBytes(data),
              ),
            ),
          );
        }
      } else {
        // For Receipt mode, use the Professional Portrait layout
        final data = await _buildDocData();
        if (mounted) {
          await Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) => FeeDocumentPreviewPage(
                title: 'Fee Receipt - ${data.receiptNumber}',
                buildPdf: (format) => FeePdfGenerator.generateBytes(data),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) AppToasts.showError(context, message: 'Preview failed: $e');
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _share() async {
    setState(() => _isSharing = true);
    try {
      if (widget.mode == 'challan') {
        final academyId = FeeDocumentService.currentAcademyId;
        final data =
            await _docService.getBankChallanData(academyId, widget.fee.id);
        await BankChallanPdfGenerator.shareDocument(data);
      } else {
        final data = await _buildDocData();
        await FeePdfGenerator.shareDocument(data);
      }
    } catch (e) {
      if (mounted) AppToasts.showError(context, message: 'Share failed: $e');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _previewPortrait() async {
    setState(() => _isPrinting = true);
    try {
      final data = await _buildDocData();
      
      if (data != null && mounted) {
        await Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => FeeDocumentPreviewPage(
              title: 'Fee Challan (Portrait) - ${data.challanNumber}',
              buildPdf: (format) => FeePdfGenerator.generateBytes(data),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) AppToasts.showError(context, message: 'Preview failed: $e');
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isChallan = widget.mode == 'challan';
    final accentColor = isChallan ? Colors.orange : Colors.green;
    final icon = isChallan ? Icons.receipt_long_rounded : Icons.task_alt_rounded;
    final title = isChallan ? 'Fee Challan' : 'Payment Receipt';
    final label = isChallan ? 'Challan No.' : 'Receipt No.';

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.r24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: accentColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        Text(
                          widget.fee.title,
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  if (_isGenerating) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Generating ${isChallan ? 'Challan' : 'Receipt'}...',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ] else if (_error != null) ...[
                    Icon(Icons.error_outline_rounded, color: cs.error, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.error),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _generate,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ] else ...[
                    // Document Number Display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurfaceVariant,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _documentNumber ?? '---',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: accentColor,
                                  letterSpacing: 2,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Fee Summary
                    _SummaryTile(label: 'Student', value: widget.fee.studentName ?? widget.fee.studentId),
                    _SummaryTile(label: 'Class', value: widget.fee.className ?? widget.fee.classId),
                    _SummaryTile(
                      label: 'Total Amount',
                      value: 'Rs. ${widget.fee.finalAmount.toStringAsFixed(0)}',
                    ),
                    _SummaryTile(
                      label: 'Amount Paid',
                      value: 'Rs. ${widget.fee.paidAmount.toStringAsFixed(0)}',
                      valueColor: Colors.green,
                    ),
                    _SummaryTile(
                      label: 'Balance Due',
                      value: 'Rs. ${widget.fee.remainingAmount.toStringAsFixed(0)}',
                      valueColor: widget.fee.remainingAmount > 0 ? cs.error : Colors.green,
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.account_balance_rounded,
                            label: isChallan
                                ? 'Preview Bank Challan (3-Copy)'
                                : 'Preview Receipt (Portrait)',
                            isLoading: _isPrinting,
                            onPressed: _preview,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.share_rounded,
                            label: 'Share PDF',
                            isLoading: _isSharing,
                            onPressed: _share,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                    if (isChallan) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: _ActionButton(
                          icon: Icons.description_rounded,
                          label: 'Preview Portrait Slip (Single Copy)',
                          isLoading: _isPrinting,
                          onPressed: _previewPortrait,
                          color: cs.secondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _isGenerating ? null : _generate,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Regenerate'),
                      style: TextButton.styleFrom(
                        foregroundColor: cs.onSurfaceVariant,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
    this.isLoading = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
      ),
    );
  }
}
