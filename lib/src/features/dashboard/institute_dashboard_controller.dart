import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/mvc/base_controller.dart';
import 'package:educore/src/core/services/app_services.dart';

class InstituteDashboardController extends BaseController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int totalStudents = 0;
  int todaysAttendance = 0;
  int pendingFeesCount = 0;
  int paidFeesCount = 0;
  int totalStaff = 0;

  double admissionCollected = 0;
  double monthlyCollected = 0;
  double packageCollected = 0;
  double miscCollected = 0;

  List<Map<String, dynamic>> recentStudents = [];
  List<Map<String, dynamic>> recentPayments = [];

  List<double> studentGrowth = [0, 0, 0, 0, 0, 0];
  List<String> studentGrowthLabels = ['', '', '', '', '', ''];

  bool hasActiveSubscription = true;
  String academyName = '';
  String userName = '';

  Future<void> loadDashboard() async {
    await runBusy(() async {
      final session = AppServices.instance.authService?.session;
      if (session == null) return;

      final academyId = session.academyId;
      userName = session.user.name.isNotEmpty
          ? session.user.name
          : 'Administrator';

      final subFuture = _firestore
          .collection('subscriptions')
          .doc(academyId)
          .get();
      final academyFuture = _firestore
          .collection('academies')
          .doc(academyId)
          .get();

      final studentsRef = _firestore
          .collection('academies')
          .doc(academyId)
          .collection('students');
      final attendanceRef = _firestore
          .collection('academies')
          .doc(academyId)
          .collection('attendance');
      final feesRef = _firestore
          .collection('academies')
          .doc(academyId)
          .collection('fees');
      final staffRef = _firestore
          .collection('academies')
          .doc(academyId)
          .collection('staff');

      final studentsCountFuture = studentsRef.count().get();

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final attendanceCountFuture = attendanceRef
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('status', isEqualTo: 'present')
          .count()
          .get();

      final feesCountFuture = feesRef
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      final paidFeesCountFuture = feesRef
          .where('status', isEqualTo: 'paid')
          .count()
          .get();

      final staffCountFuture = staffRef.count().get();

      // Use simple get() queries for fee summation (cloud_firestore 5.x compatible).
      // Aggregate sum() was only added in cloud_firestore 6.x.
      final admissionSumFuture = feesRef
          .where('type', isEqualTo: 'admission')
          .where('status', isEqualTo: 'paid')
          .get();

      final monthlySumFuture = feesRef
          .where('type', isEqualTo: 'monthly')
          .where('status', isEqualTo: 'paid')
          .get();

      final packageSumFuture = feesRef
          .where('type', isEqualTo: 'package')
          .where('status', isEqualTo: 'paid')
          .get();

      final miscSumFuture = feesRef
          .where('type', isEqualTo: 'misc')
          .where('status', isEqualTo: 'paid')
          .get();

      final allStudentsFuture = studentsRef.get();

      final recentStudentsFuture = studentsRef
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      final recentPaymentsFuture = feesRef
          .where('status', isEqualTo: 'paid')
          .orderBy('updatedAt', descending: true)
          .limit(5)
          .get();

      final results = await Future.wait([
        subFuture,
        academyFuture,
        studentsCountFuture,
        attendanceCountFuture,
        feesCountFuture,
        staffCountFuture,
        admissionSumFuture,
        monthlySumFuture,
        packageSumFuture,
        miscSumFuture,
        recentStudentsFuture,
        recentPaymentsFuture,
        allStudentsFuture,
        paidFeesCountFuture,
      ]);

      final subDoc = results[0] as DocumentSnapshot;
      hasActiveSubscription = subDoc.exists && subDoc.data() != null
          ? (subDoc.data() as Map<String, dynamic>)['status'] == 'active'
          : false;

      final academyDoc = results[1] as DocumentSnapshot;
      academyName = academyDoc.exists && academyDoc.data() != null
          ? (academyDoc.data() as Map<String, dynamic>)['name'] ??
                'Your Institute'
          : 'Your Institute';

      totalStudents = (results[2] as AggregateQuerySnapshot).count ?? 0;
      todaysAttendance = (results[3] as AggregateQuerySnapshot).count ?? 0;
      pendingFeesCount = (results[4] as AggregateQuerySnapshot).count ?? 0;
      totalStaff = (results[5] as AggregateQuerySnapshot).count ?? 0;
      paidFeesCount = (results[13] as AggregateQuerySnapshot).count ?? 0;

      // Manually sum 'paidAmount' field from fee documents (5.x compatible approach).
      double sumAmount(QuerySnapshot snap) {
        return snap.docs.fold(0.0, (total, doc) {
          final data = doc.data() as Map<String, dynamic>;
          final amt = data['paidAmount'] ?? data['finalAmount'];
          if (amt is num) return total + amt.toDouble();
          return total;
        });
      }

      admissionCollected = sumAmount(results[6] as QuerySnapshot);
      monthlyCollected = sumAmount(results[7] as QuerySnapshot);
      packageCollected = sumAmount(results[8] as QuerySnapshot);
      miscCollected = sumAmount(results[9] as QuerySnapshot);

      final stdSnaps = results[10] as QuerySnapshot;
      recentStudents = stdSnaps.docs.map((e) {
        final data = e.data() as Map<String, dynamic>;
        data['id'] = e.id;
        return data;
      }).toList();

      final paySnaps = results[11] as QuerySnapshot;
      recentPayments = paySnaps.docs.map((e) {
        final data = e.data() as Map<String, dynamic>;
        data['id'] = e.id;
        // In the UI we show subtitleKey: 'amount', so we need to map paidAmount or finalAmount to amount
        data['amount'] = data['paidAmount'] ?? data['finalAmount'] ?? 0.0;
        return data;
      }).toList();

      final allStudentsSnap = results[12] as QuerySnapshot;
      final nowTime = DateTime.now();
      List<int> monthlyCounts = List.filled(6, 0);
      for (var doc in allStudentsSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? nowTime;
        for (int i = 0; i < 6; i++) {
          final monthEnd = DateTime(nowTime.year, nowTime.month - i + 1, 1);
          if (createdAt.isBefore(monthEnd)) {
            monthlyCounts[5 - i]++;
          }
        }
      }
      studentGrowth = monthlyCounts.map((e) => e.toDouble()).toList();
      studentGrowthLabels = List.generate(6, (i) {
        final m = DateTime(nowTime.year, nowTime.month - (5 - i), 1);
        final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return monthNames[m.month - 1];
      });
    });
  }
}
