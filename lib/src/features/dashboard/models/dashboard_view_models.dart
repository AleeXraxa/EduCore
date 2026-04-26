import 'package:educore/src/features/dashboard/widgets/app_pulse_feed.dart';

class DashboardPulseData {
  static List<PulseActivityItem> fromRaw(
    List<Map<String, dynamic>> students,
    List<Map<String, dynamic>> payments,
  ) {
    final List<PulseActivityItem> items = [];

    for (final s in students) {
      items.add(PulseActivityItem(
        id: s['id'] ?? '',
        title: 'New Enrollment',
        subtitle: '${s['name']} joined ${s['className']}',
        timestamp: (s['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
        kind: PulseActivityKind.enrollment,
      ));
    }

    for (final p in payments) {
      items.add(PulseActivityItem(
        id: p['id'] ?? '',
        title: 'Fee Collected',
        subtitle: p['studentName'] ?? 'Student',
        timestamp: (p['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(),
        kind: PulseActivityKind.payment,
        amount: 'PKR ${p['amount']}',
      ));
    }

    return items..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}
