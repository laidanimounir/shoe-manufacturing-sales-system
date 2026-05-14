import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/invoice_model.dart';
import '../data/invoice_repository.dart';

final invoiceStatusFilterProvider = StateProvider<String>((ref) => 'all');
final invoiceWarehouseFilterProvider = StateProvider<String?>((ref) => null);
final invoiceDateFromProvider = StateProvider<DateTime?>((ref) => null);
final invoiceDateToProvider = StateProvider<DateTime?>((ref) => null);
final invoiceSearchProvider = StateProvider<String>((ref) => '');

final invoicesProvider =
    FutureProvider.family<List<Invoice>, void>((ref, _) async {
  final status = ref.watch(invoiceStatusFilterProvider);
  final warehouseId = ref.watch(invoiceWarehouseFilterProvider);
  final dateFrom = ref.watch(invoiceDateFromProvider);
  final dateTo = ref.watch(invoiceDateToProvider);
  final search = ref.watch(invoiceSearchProvider);
  return InvoiceRepository.getAll(
    status: status != 'all' ? status : null,
    warehouseId: warehouseId,
    dateFrom: dateFrom,
    dateTo: dateTo,
    search: search.isNotEmpty ? search : null,
  );
});

final invoiceDetailProvider =
    FutureProvider.family<Invoice?, String>((ref, id) async {
  return InvoiceRepository.getById(id);
});

final todaySalesProvider =
    FutureProvider.family<List<Invoice>, void>((ref, _) async {
  final warehouseId = ref.watch(invoiceWarehouseFilterProvider);
  return InvoiceRepository.getTodaySales(warehouseId: warehouseId);
});

final dailySummaryProvider =
    FutureProvider.family<Map<String, dynamic>, void>((ref, _) async {
  final warehouseId = ref.watch(invoiceWarehouseFilterProvider);
  return InvoiceRepository.getDailySummary(warehouseId: warehouseId);
});
