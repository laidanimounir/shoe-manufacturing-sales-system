import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/warehouse_model.dart';
import '../data/warehouse_repository.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final warehouseListProvider =
    FutureProvider.family<List<Warehouse>, String>((ref, search) async {
  final query = ref.watch(searchQueryProvider);
  return WarehouseRepository.getAll(search: query.isNotEmpty ? query : null);
});

final warehouseDetailProvider =
    FutureProvider.family<Warehouse?, String>((ref, id) async {
  return WarehouseRepository.getById(id);
});

final warehouseStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  return WarehouseRepository.getStats(id);
});

final warehouseEmployeesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, id) async {
  return WarehouseRepository.getEmployees(id);
});

final warehouseInventoryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, id) async {
  return WarehouseRepository.getInventorySummary(id);
});
