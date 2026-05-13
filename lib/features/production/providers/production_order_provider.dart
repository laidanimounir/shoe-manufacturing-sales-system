import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/production_order_model.dart';
import '../data/production_order_repository.dart';

final orderStatusFilterProvider = StateProvider<String>((ref) => 'all');
final orderWarehouseFilterProvider = StateProvider<String?>((ref) => null);

final productionOrdersProvider =
    FutureProvider.family<List<ProductionOrder>, void>((ref, _) async {
  final status = ref.watch(orderStatusFilterProvider);
  final warehouseId = ref.watch(orderWarehouseFilterProvider);
  return ProductionOrderRepository.getAll(
    status: status,
    warehouseId: warehouseId,
  );
});

final productionOrderDetailProvider =
    FutureProvider.family<ProductionOrder?, String>((ref, id) async {
  return ProductionOrderRepository.getById(id);
});

final productionOrderLogsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, orderId) async {
  return ProductionOrderRepository.getLogs(orderId);
});

final productionOrderCostProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, orderId) async {
  return ProductionOrderRepository.getCostSummary(orderId);
});
