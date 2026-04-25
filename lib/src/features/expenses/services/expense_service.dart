import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educore/src/core/services/audit_log_service.dart';
import 'package:educore/src/features/expenses/models/expense.dart';
import 'package:educore/src/features/audit/models/audit_log.dart';

class ExpenseService {
  ExpenseService({
    required FirebaseFirestore firestore,
    required AuditLogService auditLogService,
  })  : _firestore = firestore,
        _audit = auditLogService;

  final FirebaseFirestore _firestore;
  final AuditLogService _audit;

  CollectionReference<Map<String, dynamic>> _col(String academyId) =>
      _firestore.collection('academies').doc(academyId).collection('expenses');

  Stream<List<Expense>> watchExpenses(String academyId) {
    return _col(academyId).orderBy('date', descending: true).snapshots().map(
          (snap) => snap.docs.map((doc) => Expense.fromFirestore(doc)).toList(),
        );
  }

  Future<void> addExpense(String academyId, Expense expense, String actorId) async {
    final data = expense.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();
    final docRef = await _col(academyId).add(data);
    
    await _audit.logAction(
      action: 'EXPENSE_ADDED',
      module: 'expenses',
      targetId: docRef.id,
      targetType: 'expense',
      after: data,
    );
  }

  Future<void> updateExpense(String academyId, Expense expense, String actorId) async {
    final data = expense.toFirestore();
    await _col(academyId).doc(expense.id).update(data);

    await _audit.logAction(
      action: 'EXPENSE_UPDATED',
      module: 'expenses',
      targetId: expense.id,
      targetType: 'expense',
      after: data,
    );
  }

  Future<void> deleteExpense(String academyId, String expenseId, String actorId) async {
    await _col(academyId).doc(expenseId).delete();

    await _audit.logAction(
      action: 'EXPENSE_DELETED',
      module: 'expenses',
      targetId: expenseId,
      targetType: 'expense',
      severity: AuditSeverity.warning,
    );
  }

  Future<double> getTotalExpenses(String academyId, {DateTime? startDate, DateTime? endDate}) async {
    Query<Map<String, dynamic>> query = _col(academyId);
    
    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    final agg = await query.aggregate(sum('amount')).get();
    return agg.getSum('amount') ?? 0.0;
  }
}
