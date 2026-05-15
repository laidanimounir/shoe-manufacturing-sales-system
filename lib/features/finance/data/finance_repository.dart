import '../../../core/services/supabase_service.dart';
import 'finance_summary_model.dart';

class FinanceRepository {
  static Future<FinanceSummary> getMonthlySummary(
      int year, int month) async {
    final client = SupabaseService.client;
    final monthStr = month.toString().padLeft(2, '0');
    final start = '$year-$monthStr-01';
    final end = month == 12
        ? '${year + 1}-01-01'
        : '$year-${(month + 1).toString().padLeft(2, '0')}-01';

    final results = await Future.wait([
      client.from('invoices').select('total_amount, paid_amount')
          .neq('payment_status', 'cancelled').limit(10000),
      client.from('production_cost_summaries').select('total_cost').limit(10000),
      client.from('purchase_orders').select('total_amount')
          .eq('status', 'received').limit(10000),
      client.from('salary_sheets').select('net_salary')
          .eq('status', 'paid').eq('month', month).eq('year', year).limit(10000),
      client.from('expenses').select('amount')
          .gte('expense_date', start).lt('expense_date', end).limit(10000),
      client.from('clients').select('total_debt').limit(10000),
      client.from('suppliers').select('total_debt').limit(10000),
    ]);

    double sumInvoices(List data, String field) {
      double s = 0;
      for (final r in data) {
        s += (r[field] as num?)?.toDouble() ?? 0;
      }
      return s;
    }

    final invoices = results[0] as List;
    final totalRevenue = sumInvoices(invoices, 'total_amount');
    final totalPaid = sumInvoices(invoices, 'paid_amount');

    final productionCost =
        sumInvoices(results[1] as List, 'total_cost');
    final purchaseCost =
        sumInvoices(results[2] as List, 'total_amount');
    final salariesPaid =
        sumInvoices(results[3] as List, 'net_salary');
    final totalExpenses =
        sumInvoices(results[4] as List, 'amount');
    final clientDebtTotal =
        sumInvoices(results[5] as List, 'total_debt');
    final supplierDebtTotal =
        sumInvoices(results[6] as List, 'total_debt');

    return FinanceSummary(
      totalRevenue: totalRevenue,
      totalPaid: totalPaid,
      clientDebt: clientDebtTotal,
      productionCost: productionCost,
      purchaseCost: purchaseCost,
      salariesPaid: salariesPaid,
      totalExpenses: totalExpenses,
      supplierDebt: supplierDebtTotal,
      month: month,
      year: year,
    );
  }

  static Future<List<Map<String, dynamic>>> getMonthlySeriesData(
      int year) async {
    final series = <Map<String, dynamic>>[];
    for (int m = 1; m <= 12; m++) {
      try {
        final summary = await getMonthlySummary(year, m);
        series.add({
          'month': m,
          'revenue': summary.totalRevenue,
          'expenses': summary.totalExpenses,
          'profit': summary.netProfit,
        });
      } catch (_) {
        series.add({
          'month': m, 'revenue': 0, 'expenses': 0, 'profit': 0,
        });
      }
    }
    return series;
  }
}
