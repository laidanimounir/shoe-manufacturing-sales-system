import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/supabase_service.dart';
import '../../features/employees/data/employee_repository.dart';
import '../../features/sales/data/client_repository.dart';

class ExcelExporter {
  static final _client = SupabaseService.client;

  static List<CellValue?> _row(List<dynamic> values) {
    return values.map<CellValue?>((v) {
      if (v is String) return TextCellValue(v);
      if (v is int) return IntCellValue(v);
      if (v is double) return DoubleCellValue(v);
      if (v is num) return DoubleCellValue(v.toDouble());
      return TextCellValue(v.toString());
    }).toList();
  }

  static Future<void> exportEmployees() async {
    final employees = await EmployeeRepository.getAll();
    final excel = Excel.createExcel();
    final sheet = excel['Employés'];

    sheet.appendRow(_row([
      'Nom',
      'Poste',
      'Type Salaire',
      'Salaire Base',
      'Taux Journalier',
      'Date Embauche',
      'Statut',
    ]));

    for (final e in employees) {
      sheet.appendRow(_row([
        e.fullName,
        e.position ?? '',
        e.salaryLabel,
        e.baseSalary,
        e.dailyRate,
        e.hireDate != null
            ? '${e.hireDate!.day}/${e.hireDate!.month}/${e.hireDate!.year}'
            : '',
        e.isActive ? 'Actif' : 'Inactif',
      ]));
    }

    await _saveAndShare(excel, 'employes_export_${_dateStr(DateTime.now())}');
  }

  static Future<void> exportClients() async {
    final clients = await ClientRepository.getAll();
    final excel = Excel.createExcel();
    final sheet = excel['Clients'];

    sheet.appendRow(_row([
      'Nom',
      'Telephone',
      'Ville',
      'Type',
      'Dette Totale',
    ]));

    for (final c in clients) {
      sheet.appendRow(_row([
        c.fullName,
        c.phone ?? '',
        c.city ?? '',
        c.clientTypeLabel,
        c.totalDebt,
      ]));
    }

    await _saveAndShare(excel, 'clients_export_${_dateStr(DateTime.now())}');
  }

  static Future<void> exportFinanceSummary(int year) async {
    final excel = Excel.createExcel();

    final sheet1 = excel['Resume annuel'];
    sheet1.appendRow(_row([
      'Mois',
      'Revenus',
      'Cout Production',
      'Achats',
      'Salaires',
      'Depenses',
      'Benefice Net',
    ]));

    final monthNames = [
      '',
      'Janvier',
      'Fevrier',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Aout',
      'Septembre',
      'Octobre',
      'Novembre',
      'Decembre',
    ];

    for (int m = 1; m <= 12; m++) {
      final monthStr = m.toString().padLeft(2, '0');
      final start = '$year-$monthStr-01';
      final end = m == 12
          ? '${year + 1}-01-01'
          : '$year-${(m + 1).toString().padLeft(2, '0')}-01';

      try {
        final results = await Future.wait([
          _client
              .from('invoices')
              .select('total_amount')
              .neq('payment_status', 'cancelled')
              .gte('invoice_date', start)
              .lt('invoice_date', end)
              .limit(10000),
          _client
              .from('purchase_orders')
              .select('total_amount')
              .eq('status', 'received')
              .gte('order_date', start)
              .lt('order_date', end)
              .limit(10000),
          _client
              .from('salary_sheets')
              .select('net_salary')
              .eq('status', 'paid')
              .eq('month', m)
              .eq('year', year)
              .limit(10000),
          _client
              .from('expenses')
              .select('amount')
              .gte('expense_date', start)
              .lt('expense_date', end)
              .limit(10000),
        ]);

        double sum(List data, String field) {
          double s = 0;
          for (final r in data) {
            s += (r[field] as num?)?.toDouble() ?? 0;
          }
          return s;
        }

        final revenue = sum(results[0] as List, 'total_amount');
        final purchaseCost = sum(results[1] as List, 'total_amount');
        final salaries = sum(results[2] as List, 'net_salary');
        final expensesTotal = sum(results[3] as List, 'amount');
        final profit = revenue - purchaseCost - salaries - expensesTotal;

        sheet1.appendRow(_row([
          monthNames[m],
          revenue,
          0.0,
          purchaseCost,
          salaries,
          expensesTotal,
          profit,
        ]));
      } catch (_) {
        sheet1.appendRow(_row([monthNames[m], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]));
      }
    }

    final sheet2 = excel['Depenses detail'];
    sheet2.appendRow(_row([
      'Date',
      'Categorie',
      'Montant',
      'Depot',
      'Description',
    ]));

    try {
      final expenses = await _client
          .from('expenses')
          .select('*, warehouses(name)')
          .gte('expense_date', '$year-01-01')
          .lt('expense_date', '${year + 1}-01-01')
          .order('expense_date', ascending: false)
          .limit(5000);

      for (final e in expenses as List) {
        final wh = e['warehouses'];
        sheet2.appendRow(_row([
          e['expense_date']?.toString() ?? '',
          e['category'] ?? '',
          (e['amount'] as num?)?.toDouble() ?? 0.0,
          wh is Map ? wh['name'] ?? '' : '',
          e['description'] ?? '',
        ]));
      }
    } catch (_) {}

    final sheet3 = excel['Factures'];
    sheet3.appendRow(_row([
      'No Facture',
      'Client',
      'Total',
      'Paye',
      'Reste',
      'Statut',
      'Date',
    ]));

    try {
      final invoices = await _client
          .from('invoices')
          .select('*, clients(name)')
          .neq('payment_status', 'cancelled')
          .gte('invoice_date', '$year-01-01')
          .lt('invoice_date', '${year + 1}-01-01')
          .order('invoice_date', ascending: false)
          .limit(5000);

      for (final i in invoices as List) {
        final c = i['clients'];
        final total = (i['total_amount'] as num?)?.toDouble() ?? 0;
        final paid = (i['paid_amount'] as num?)?.toDouble() ?? 0;
        sheet3.appendRow(_row([
          i['invoice_number'] ?? '',
          c is Map ? c['name'] ?? '' : '',
          total,
          paid,
          total - paid,
          i['payment_status'] ?? '',
          i['invoice_date']?.toString() ?? '',
        ]));
      }
    } catch (_) {}

    await _saveAndShare(excel, 'rapport_finance_$year');
  }

  static Future<void> _saveAndShare(Excel excel, String filename) async {
    final fileBytes = excel.encode();
    if (fileBytes == null) return;

    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}${Platform.pathSeparator}$filename.xlsx');
    await file.writeAsBytes(fileBytes);

    if (Platform.isWindows) {
      try {
        final downloadDir = await getDownloadsDirectory();
        if (downloadDir != null) {
          await file.copy(
              '${downloadDir.path}${Platform.pathSeparator}$filename.xlsx');
        }
      } catch (_) {}
    }

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: filename,
    );
  }

  static String _dateStr(DateTime d) {
    return '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
  }
}
