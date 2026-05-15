import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../features/sales/data/invoice_model.dart';
import '../../features/sales/data/invoice_item_model.dart';
import '../../features/employees/data/salary_sheet_model.dart';
import '../../features/settings/data/company_settings_model.dart';
import '../../features/settings/data/settings_repository.dart';

class PdfGenerator {
  static final _currencyFormat = NumberFormat('#,##0.00', 'fr');

  static Future<CompanySettings> _getSettings() async {
    try {
      return await SettingsRepository.getCompanySettings();
    } catch (_) {
      return const CompanySettings(id: 'default');
    }
  }

  static Future<void> generateTicket(
    InvoiceModel invoice,
    List<InvoiceItemModel> items,
  ) async {
    final settings = await _getSettings();
    final pdf = pw.Document();
    final width = settings.ticketFormat == '58mm' ? 58.0 : 80.0;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(width * PdfPageFormat.mm, double.infinity),
        margin: const pw.EdgeInsets.all(4 * PdfPageFormat.mm),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.SizedBox(height: 8),
              if (settings.logoUrl != null)
                pw.Center(child: pw.Text('LOGO', style: pw.TextStyle(fontSize: 10))),
              pw.Center(
                child: pw.Text(
                  settings.name,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              if (settings.address != null || settings.phone != null)
                pw.Center(
                  child: pw.Text(
                    '${settings.address ?? ''} ${settings.phone != null ? '| ${settings.phone}' : ''}'.trim(),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  'TICKET ${invoice.invoiceNumber}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  invoice.invoiceDate != null
                      ? DateFormat('dd/MM/yyyy HH:mm').format(invoice.invoiceDate!)
                      : '-',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              pw.SizedBox(height: 6),
              if (invoice.clientName != null)
                pw.Text(
                  'Client: ${invoice.clientName}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              pw.Divider(),
              ...items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          '${item.productName ?? 'Produit'}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Text(
                        'x${item.quantity}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                );
              }),
              ...items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(
                        '${_currencyFormat.format(item.unitPrice)} DZD',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                );
              }),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${_currencyFormat.format(invoice.totalAmount)} DZD',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Payé:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    '${_currencyFormat.format(invoice.paidAmount)} DZD',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Reste:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    '${_currencyFormat.format(invoice.remainingDebt)} DZD',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: invoice.remainingDebt > 0
                          ? PdfColors.red
                          : PdfColors.green,
                    ),
                  ),
                ],
              ),
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  settings.ticketFooter,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  static Future<void> generateFacture(
    InvoiceModel invoice,
    List<InvoiceItemModel> items,
  ) async {
    final settings = await _getSettings();
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20 * PdfPageFormat.mm),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (settings.logoUrl != null)
                    pw.Container(
                      width: 60,
                      height: 60,
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      child: pw.Center(child: pw.Text('LOGO')),
                    ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          settings.name,
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (settings.address != null)
                          pw.Text(settings.address!, style: const pw.TextStyle(fontSize: 10)),
                        if (settings.phone != null || settings.email != null)
                          pw.Text(
                            '${settings.phone ?? ''} ${settings.email != null ? '/ ${settings.email}' : ''}'.trim(),
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                      ],
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey900,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'FACTURE',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Text(
                          'N°: ${invoice.invoiceNumber}',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Text(
                          'Date: ${invoice.invoiceDate != null ? DateFormat('dd/MM/yyyy').format(invoice.invoiceDate!) : '-'}',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.white,
                          ),
                        ),
                        if (invoice.dueDate != null)
                          pw.Text(
                            'Échéance: ${DateFormat('dd/MM/yyyy').format(invoice.dueDate!)}',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              if (invoice.clientName != null) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'FACTURER À:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        invoice.clientName!,
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
              ],
              pw.TableHelper.fromTextArray(
                headers: ['Désignation', 'Qté', 'P.Unit', 'Total'],
                headerStyle: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                data: items.map((item) {
                  return [
                    item.productName ?? 'Produit',
                    item.quantity.toString(),
                    '${_currencyFormat.format(item.unitPrice)} DZD',
                    '${_currencyFormat.format(item.subtotal)} DZD',
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 16),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'TOTAL HT: ${_currencyFormat.format(invoice.totalAmount)} DZD',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Payé: ${_currencyFormat.format(invoice.paidAmount)} DZD',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.Text(
                      'RESTE DÛ: ${_currencyFormat.format(invoice.remainingDebt)} DZD',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: invoice.remainingDebt > 0
                            ? PdfColors.red
                            : PdfColors.green,
                      ),
                    ),
                  ],
                ),
              ),
              if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 16),
                pw.Text('Notes: ${invoice.notes}', style: const pw.TextStyle(fontSize: 10)),
              ],
              pw.SizedBox(height: 32),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Signature: ___________________________',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Cachet: ___________________________',
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  static Future<void> generateSalarySheet(SalarySheet sheet) async {
    final settings = await _getSettings();
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20 * PdfPageFormat.mm),
        build: (context) {
          final monthNames = [
            '',
            'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
            'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
          ];
          final monthLabel = '${monthNames[sheet.month]} ${sheet.year}';

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (settings.logoUrl != null)
                    pw.Container(
                      width: 50,
                      height: 50,
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      child: pw.Center(child: pw.Text('LOGO')),
                    ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          settings.name,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text('FICHE DE PAIE',
                            style: const pw.TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  pw.Text(
                    monthLabel,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Employé: ${sheet.employeeName ?? '-'}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Jours travaillés: ${sheet.workedDays} / 26 | Absences: ${sheet.absentDays}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Description', 'Montant'],
                headerStyle: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                },
                data: [
                  ['Salaire de base', '${_currencyFormat.format(sheet.baseSalary)} DZD'],
                  ['+ Primes', '${_currencyFormat.format(sheet.bonus)} DZD'],
                  ['- Avances', '${_currencyFormat.format(sheet.totalAdvances)} DZD'],
                  ['- Déductions', '${_currencyFormat.format(sheet.deductions)} DZD'],
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey900,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'NET À PAYER',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      '${_currencyFormat.format(sheet.netSalary)} DZD',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Statut: ${sheet.statusLabel}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: sheet.status == 'paid' ? PdfColors.green : PdfColors.orange,
                      )),
                  if (sheet.paidAt != null)
                    pw.Text(
                        'Payé le: ${DateFormat('dd/MM/yyyy').format(sheet.paidAt!)}',
                        style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 40),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Signature employeur: __________________',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Signature employé: __________________',
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }
}
