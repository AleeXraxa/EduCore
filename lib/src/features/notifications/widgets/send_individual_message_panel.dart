import 'package:flutter/material.dart';
import 'package:educore/src/features/notifications/controllers/institute_notifications_controller.dart';
import 'package:educore/src/features/students/models/student.dart';
import 'package:educore/src/core/ui/widgets/app_text_field.dart';
import 'package:educore/src/core/ui/widgets/app_dropdown.dart';

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
  String? _selectedTemplate;

  final List<String> _templates = [
    'Custom Message',
    'Fee Reminder',
    'Test Schedule',
    'Test Result',
    'Attendance Alert',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isConnected = widget.controller.whatsappStatus == 'connected';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
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
            _buildTemplateSelector(cs),
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
      ),
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
    return AppDropdown<Student>(
      label: 'Select Student (Optional)',
      hintText: 'Search for a student...',
      items: widget.controller.students,
      value: _selectedStudent,
      searchable: true,
      itemLabel: (s) => '${s.name} (${s.rollNo ?? 'N/A'})',
      onChanged: (val) {
        setState(() {
          _selectedStudent = val;
          if (val != null) {
            _recipientController.text = val.phone;
          }
          _updateMessageWithTemplate();
        });
      },
    );
  }

  Widget _buildTemplateSelector(ColorScheme cs) {
    return AppDropdown<String>(
      label: 'Message Template',
      items: _templates,
      value: _selectedTemplate ?? 'Custom Message',
      itemLabel: (t) => t,
      onChanged: (val) {
        setState(() {
          _selectedTemplate = val;
          _updateMessageWithTemplate();
        });
      },
    );
  }

  void _updateMessageWithTemplate() {
    if (_selectedTemplate == null || _selectedTemplate == 'Custom Message') return;

    String msg = '';
    switch (_selectedTemplate) {
      case 'Fee Reminder':
        msg = 'Dear Parent, this is a reminder that the tuition fee for {month} is pending. Please clear it by {date}. Regards, {institute}';
        break;
      case 'Test Schedule':
        msg = 'Dear Student, your {subject} test is scheduled for {date} at {time}. Regards, {institute}';
        break;
      case 'Test Result':
        msg = 'Dear Parent, the result for {student} in {subject} test is {marks}/{total}. Regards, {institute}';
        break;
      case 'Attendance Alert':
        msg = 'Dear Parent, {student} was absent from the academy today ({date}). Regards, {institute}';
        break;
    }

    if (_selectedStudent != null) {
      msg = msg.replaceAll('{student}', _selectedStudent!.name);
    }
    msg = msg.replaceAll('{date}', DateTime.now().toString().split(' ')[0]);
    msg = msg.replaceAll('{institute}', widget.controller.academyId ?? 'EduCore');

    _messageController.text = msg;
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
