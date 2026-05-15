import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/finance_summary_model.dart';
import '../data/expense_model.dart';
import '../data/audit_log_model.dart';
import '../data/finance_repository.dart';
import '../data/expense_repository.dart';
import '../data/audit_log_repository.dart';

final selectedMonthProvider = StateProvider<int>((ref) => DateTime.now().month);
final selectedYearProvider = StateProvider<int>((ref) => DateTime.now().year);

final financeSummaryProvider = FutureProvider.autoDispose
    .family<FinanceSummary, ({int year, int month})>((ref, params) async {
  return FinanceRepository.getMonthlySummary(params.year, params.month);
});

final monthlySeriesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, year) async {
  return FinanceRepository.getMonthlySeriesData(year);
});

final expenseFilterMonthProvider = StateProvider<int?>((ref) => null);
final expenseFilterYearProvider = StateProvider<int?>((ref) => null);
final expenseFilterWarehouseProvider = StateProvider<String?>((ref) => null);

final expensesProvider = FutureProvider.autoDispose
    .family<List<Expense>, void>((ref, _) async {
  final y = ref.watch(expenseFilterYearProvider);
  final m = ref.watch(expenseFilterMonthProvider);
  final wh = ref.watch(expenseFilterWarehouseProvider);
  return ExpenseRepository.getAll(year: y, month: m, warehouseId: wh);
});

class AuditLogFilter {
  final String action;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String search;

  const AuditLogFilter({
    this.action = 'all',
    this.fromDate,
    this.toDate,
    this.search = '',
  });

  AuditLogFilter copyWith({
    String? action,
    DateTime? fromDate,
    DateTime? toDate,
    String? search,
    bool clearDates = false,
  }) {
    return AuditLogFilter(
      action: action ?? this.action,
      fromDate: clearDates ? null : (fromDate ?? this.fromDate),
      toDate: clearDates ? null : (toDate ?? this.toDate),
      search: search ?? this.search,
    );
  }
}

final auditLogFilterProvider =
    StateProvider<AuditLogFilter>((ref) => const AuditLogFilter());

final auditLogsProvider = FutureProvider.autoDispose
    .family<List<AuditLog>, AuditLogFilter>((ref, filter) async {
  return AuditLogRepository.getAll(
    action: filter.action,
    fromDate: filter.fromDate,
    toDate: filter.toDate,
    search: filter.search.isNotEmpty ? filter.search : null,
  );
});
