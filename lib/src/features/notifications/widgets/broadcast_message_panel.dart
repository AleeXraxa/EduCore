import 'package:flutter/material.dart';
import 'package:educore/src/features/notifications/controllers/institute_notifications_controller.dart';

class BroadcastMessagePanel extends StatefulWidget {
  const BroadcastMessagePanel({super.key, required this.controller});
  final InstituteNotificationsController controller;

  @override
  State<BroadcastMessagePanel> createState() => _BroadcastMessagePanelState();
}

class _BroadcastMessagePanelState extends State<BroadcastMessagePanel> {
  String _selectedTemplate = 'General Announcement';
  final _messageController = TextEditingController();
  final List<String> _templates = [
    'General Announcement',
    'Fee Reminder',
    'Test Schedule',
    'Test Result',
    'Attendance Alert',
  ];

  @override
  void initState() {
    super.initState();
    _updateTemplate();
  }

  void _updateTemplate() {
    switch (_selectedTemplate) {
      case 'Fee Reminder':
        _messageController.text = 'Dear Parent, this is a reminder that the tuition fee for {month} is pending. Please clear it by {date} to avoid any inconvenience. Regards, {institute}';
        break;
      case 'Test Schedule':
        _messageController.text = 'Dear Student, your {subject} test is scheduled for {date} at {time}. Please ensure you are prepared. Regards, {institute}';
        break;
      case 'Test Result':
        _messageController.text = 'Dear Parent, the result for {student} in {subject} test is {marks}/{total}. Position: {position}. Regards, {institute}';
        break;
      case 'Attendance Alert':
        _messageController.text = 'Dear Parent, {student} was absent from the academy today ({date}) without prior notice. Regards, {institute}';
        break;
      default:
        _messageController.text = '';
    }
  }

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
            'Bulk Broadcast',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Send messages to all students or specific groups at once.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 32),

          if (!isConnected)
            _buildNotConnectedWarning(cs)
          else ...[
            _buildTemplateSelector(cs),
            const SizedBox(height: 24),
            _buildMessageEditor(cs),
            const SizedBox(height: 32),
            _buildRecipientsStats(cs),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _sendBroadcast,
                icon: const Icon(Icons.campaign_rounded),
                label: const Text('Send Bulk Broadcast'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: cs.primary,
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

  Widget _buildTemplateSelector(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Message Template', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedTemplate,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: _templates.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedTemplate = val;
                _updateTemplate();
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildMessageEditor(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Message Content', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'Placeholders: {student}, {date}, {month}',
              style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _messageController,
          maxLines: 8,
          decoration: InputDecoration(
            hintText: 'Type your message...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipientsStats(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.secondaryContainer),
      ),
      child: Row(
        children: [
          Icon(Icons.people_alt_rounded, color: cs.secondary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'This message will be sent to ${widget.controller.students.length} active students.',
              style: TextStyle(color: cs.onSecondaryContainer, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendBroadcast() async {
    if (_messageController.text.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Broadcast'),
        content: Text('Are you sure you want to send this message to ${widget.controller.students.length} students?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm & Send')),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    // Build recipients list with placeholder replacements
    final recipients = widget.controller.students.map((s) {
      String msg = _messageController.text;
      msg = msg.replaceAll('{student}', s.name);
      msg = msg.replaceAll('{date}', DateTime.now().toString().split(' ')[0]);
      msg = msg.replaceAll('{institute}', widget.controller.academyId ?? 'EduCore');
      
      return {
        'to': s.phone,
        'message': msg,
        'studentId': s.id,
        'studentName': s.name,
      };
    }).toList();

    await widget.controller.sendBulkMessages(
      context,
      recipients: recipients,
      broadcastType: _selectedTemplate,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Broadcast initiated successfully!')),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
