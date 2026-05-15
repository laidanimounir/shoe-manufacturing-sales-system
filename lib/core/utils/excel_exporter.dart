import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/employees/data/employee_model.dart';
import '../../features/employees/data/employee_repository.dart';
import '../../features/sales/data/client_model.dart';
import '../../features/sales/data/client_repository.dart';
import '../../features/finance/data/finance_repository.dart';

class ExcelExporter {
  static final _dateFormat = DateFormat('yyyyMMdd');
  static final _currencyFormat = NumberFormat('#,##0.00', 'fr');
  static final _displayDateFormat = DateFormat('dd/MM/yyyy');

  static Future<void> exportEmployees() async {
    final employees = await EmployeeRepository.getAll();
    final excel = Excel.createExcel();
    final sheet = excel['Employés'];

    sheet.appendRow([
      'Nom',
      'Poste',
      'Type Salaire',
      'Salaire Base',
      'Taux Journalier',
      'Date Embauche',
      'Statut',
    ]);

    for (final e in employees) {
      sheet.appendRow([
        e.fullName,
        e.position ?? '',
        e.salaryLabel,
        e.baseSalary,
        e.dailyRate,
        e.hireDate != null
            ? _displayDateFormat.format(e.hireDate!)
            : '',
        e.isActive ? 'Actif' : 'Inactif',
      ]);
    }

    await _saveAndShare(excel, 'employes_export_${_dateFormat.format(DateTime.now())}');
  }

  static Future<void> exportClients() async {
    final clients = await ClientRepository.getAll();
    final excel = Excel.createExcel();
    final sheet = excel['Clients'];

    sheet.appendRow([
      'Nom',
      'Téléphone',
      'Ville',
      'Type',
      'Dette Totale',
    ]);

    for (final c in clients) {
      sheet.appendRow([
        c.name,
        c.phone ?? '',
        c.city ?? '',
        c.clientType == 'wholesale' ? 'Grossiste' : 'Détaillant',
        c.totalDebt,
      ]);
    }

    await _saveAndShare(excel, 'clients_export_${_dateFormat.format(DateTime.now())}');
  }

  static Future<void> exportFinanceSummary(int year) async {
    final summary = await FinanceRepository.getYearlySummary(year: year);
    final expenses = await FinanceRepository.getAllExpenses(year: year);
    final invoices = await FinanceRepository.getYearlyInvoices(year: year);
    final excel = Excel.createExcel();

    final sheet1 = excel['Résumé annuel'];
    sheet1.appendRow([
      'Mois',
      'Revenus',
      'Coût Production',
      'Achats',
      'Salaires',
      'Dépenses',
      'Bénéfice Net',
    ]);

    final monthNames = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
    ];

    for (final row in summary) {
      sheet1.appendRow([
        monthNames[(row['month'] as num?)?.toInt() ?? 0],
        (row['total_revenue'] as num?)?.toDouble() ?? 0,
        (row['total_production_cost'] as num?)?.toDouble() ?? 0,
        (row['total_purchase_cost'] as num?)?.toDouble() ?? 0,
        (row['total_salaries'] as num?)?.toDouble() ?? 0,
        (row['total_expenses'] as num?)?.toDouble() ?? 0,
        (row['net_profit'] as num?)?.toDouble() ?? 0,
      ]);
    }

    final sheet2 = excel['Dépenses détail'];
    sheet2.appendRow([
      'Date',
      'Catégorie',
      'Montant',
      'Dépôt',
      'Description',
    ]);

    for (final e in expenses) {
      sheet2.appendRow([
        e['expense_date']?.toString() ?? '',
        e['category'] ?? '',
        (e['amount'] as num?)?.toDouble() ?? 0,
        e['warehouse_name'] ?? '',
        e['description'] ?? '',
      ]);
    }

    final sheet3 = excel['Factures'];
    sheet3.appendRow([
      'N° Facture',
      'Client',
      'Total',
      'Payé',
      'Reste',
      'Statut',
      'Date',
    ]);

    for (final i in invoices) {
      sheet3.appendRow([
        i['invoice_number'] ?? '',
        i['client_name'] ?? '',
        (i['total_amount'] as num?)?.toDouble() ?? 0,
        (i['paid_amount'] as num?)?.toDouble() ?? 0,
        (i['total_amount'] as num?)?.toDouble()! - ((i['paid_amount'] as num?)?.toDouble() ?? 0),
        i['payment_status'] ?? '',
        i['invoice_date']?.toString() ?? '',
      ]);
    }

    await _saveAndShare(excel, 'rapport_finance_$year');
  }

  static Future<void> _saveAndShare(Excel excel, String filename) async {
    final fileBytes = excel.encode();
    if (fileBytes == null) return;

    final dir = await _getExportDir();
    final file = File('${dir.path}${Platform.pathSeparator}$filename.xlsx');
    await file.writeAsBytes(fileBytes);

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final downloadDir = await getDownloadsDirectory();
      if (downloadDir != null) {
        await file.copy('${downloadDir.path}${Platform.pathSeparator}$filename.xlsx');
      }
    }

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: filename,
    );
  }

  static Future<Directory> _getExportDir() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return Directory.systemTemp;
    }
    final dir = await getApplicationDocumentsDirectory();
    return dir;
  }
}
