import 'package:flutter/material.dart';
import 'package:educore/src/features/notifications/controllers/institute_notifications_controller.dart';
import 'package:qr_flutter/qr_flutter.dart';

class WhatsAppConnectPanel extends StatelessWidget {
  const WhatsAppConnectPanel({super.key, required this.controller});
  final InstituteNotificationsController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = controller.whatsappStatus;
    final isConnected = status == 'connected';

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 40,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isConnected 
                    ? Colors.green.withValues(alpha: 0.1) 
                    : cs.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isConnected ? Icons.check_circle_rounded : Icons.qr_code_2_rounded,
                  color: isConnected ? Colors.green : cs.primary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isConnected ? 'WhatsApp Connected' : 'Connect Your WhatsApp',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                isConnected 
                  ? 'Your institute is now ready to send messages and alerts.'
                  : 'Scan the QR code below using your WhatsApp mobile app to start sending messages.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 40),
              
              if (controller.qrCode != null && !isConnected)
                _QrDisplay(qr: controller.qrCode!)
              else if (status == 'checking')
                const CircularProgressIndicator()
              else if (!isConnected) ...[
                // Show backend error if present
                if (controller.backendError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: cs.error, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            controller.backendError!,
                            style: TextStyle(color: cs.onErrorContainer, fontSize: 13, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: controller.connectWhatsApp,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Generate Connection QR'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
  
              if (isConnected)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: controller.disconnectWhatsApp,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Disconnect WhatsApp'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.error,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrDisplay extends StatelessWidget {
  const _QrDisplay({required this.qr});
  final String qr;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          QrImageView(
            data: qr,
            version: QrVersions.auto,
            size: 250.0,
            gapless: false,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'SCAN WITH WHATSAPP',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
