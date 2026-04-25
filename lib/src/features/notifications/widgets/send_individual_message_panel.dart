import 'package:flutter/material.dart';
import 'package:educore/src/features/notifications/controllers/institute_notifications_controller.dart';
import 'package:educore/src/features/students/models/student.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';

class SendIndividualMessagePanel extends StatefulWidget {
  const SendIndividualMessagePanel({super.key, required this.controller});
  final InstituteNotificationsController controller;

  @override
  State<SendIndividualMessagePanel> createState() => _SendIndividualMessagePanelState();
}

class _SendIndividualMessagePanelState extends State<SendIndividualMessagePanel> {
  final _recipientController = TextEditingController();
  final _messageController = TextEditingController();
  Student? _selectedStudent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isConnected = widget.controller.whatsappStatus == 'connected';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send Single Message',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a direct WhatsApp message to any student or parent.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          
          if (!isConnected)
            _buildNotConnectedWarning(cs)
          else ...[
            _buildStudentSelector(cs),
            const SizedBox(height: 24),
            AppTextField(
              controller: _recipientController,
              label: 'WhatsApp Number',
              hintText: 'e.g. 923023476605',
              prefixIcon: Icons.phone_android_rounded,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: _messageController,
              label: 'Message Content',
              hintText: 'Type your message here...',
              maxLines: 5,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Send WhatsApp Message'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotConnectedWarning(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.errorContainer),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: cs.error),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'WhatsApp is not connected. Please go to the "Connection" tab to link your account.',
              style: TextStyle(color: cs.error, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentSelector(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Student (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<Student>(
          value: _selectedStudent,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: widget.controller.students.map((s) {
            return DropdownMenuItem(
              value: s,
              child: Text('${s.name} (${s.rollNo ?? 'N/A'})'),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedStudent = val;
              if (val != null) {
                _recipientController.text = val.phone; 
              }
            });
          },
        ),
      ],
    );
  }

  Future<void> _sendMessage() async {
    if (_recipientController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final success = await widget.controller.sendSingleMessage(
      context,
      recipient: _recipientController.text,
      message: _messageController.text,
      studentId: _selectedStudent?.id,
      studentName: _selectedStudent?.name,
    );

    if (success && mounted) {
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent successfully!')),
      );
    }
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
