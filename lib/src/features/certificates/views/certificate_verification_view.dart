import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/ui/widgets/app_button.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/features/certificates/models/certificate.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CertificateVerificationView extends StatefulWidget {
  const CertificateVerificationView({super.key});

  @override
  State<CertificateVerificationView> createState() => _CertificateVerificationViewState();
}

class _CertificateVerificationViewState extends State<CertificateVerificationView> {
  final _idController = TextEditingController();
  Certificate? _verifiedCertificate;
  bool _loading = false;
  bool _searched = false;

  Future<void> _verify() async {
    final id = _idController.text.trim();
    if (id.isEmpty) return;

    setState(() {
      _loading = true;
      _searched = false;
      _verifiedCertificate = null;
    });

    try {
      final cert = await AppServices.instance.certificateService?.verifyCertificate(id);
      setState(() {
        _verifiedCertificate = cert;
        _searched = true;
      });
    } catch (e) {
      AppDialogs.showError(context, title: 'Error', message: 'An error occurred during verification. Please try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.surface,
              cs.primaryContainer.withOpacity(0.1),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                children: [
                  // Logo / Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      size: 64,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'EduCore Verify',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    'Official Certificate Verification Portal',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Search Box
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          controller: _idController,
                          label: 'Certificate ID',
                          hintText: 'Enter the unique ID from the certificate',
                          prefixIcon: Icons.qr_code_scanner_rounded,
                          onSubmitted: (_) => _verify(),
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          label: 'Verify Certificate',
                          onPressed: _loading ? null : _verify,
                          busy: _loading,
                          variant: AppButtonVariant.primary,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Result
                  if (_searched)
                    _verifiedCertificate != null
                        ? _ResultCard(certificate: _verifiedCertificate!)
                        : _InvalidCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.certificate});
  final Certificate certificate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 48),
          const SizedBox(height: 16),
          const Text(
            'CERTIFICATE VERIFIED',
            style: TextStyle(
              color: Color(0xFF10B981),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          _InfoRow(label: 'Student Name', value: certificate.studentName),
          _InfoRow(label: 'Issued By', value: certificate.academyName),
          _InfoRow(label: 'Certificate Type', value: certificate.type.label),
          _InfoRow(label: 'Issue Date', value: DateFormat('dd MMM yyyy').format(certificate.issueDate)),
          if (certificate.validUntil != null)
            _InfoRow(label: 'Valid Until', value: DateFormat('dd MMM yyyy').format(certificate.validUntil!)),
        ],
      ),
    );
  }
}

class _InvalidCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cs.errorContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.error.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.warning_amber_rounded, color: cs.error, size: 48),
          const SizedBox(height: 16),
          Text(
            'INVALID CERTIFICATE',
            style: TextStyle(
              color: cs.error,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The Certificate ID provided could not be found in our records. Please check the ID and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
