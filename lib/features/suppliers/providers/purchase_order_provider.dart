import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/purchase_order_model.dart';
import '../data/purchase_order_item_model.dart';
import '../data/purchase_order_repository.dart';

final purchaseOrderStatusFilterProvider =
    StateProvider<String>((ref) => 'all');

final purchaseOrdersProvider =
    FutureProvider.family<List<PurchaseOrder>, void>((ref, _) async {
  final status = ref.watch(purchaseOrderStatusFilterProvider);
  return PurchaseOrderRepository.getAll(
    status: status != 'all' ? status : null,
  );
});

final purchaseOrderDetailProvider =
    FutureProvider.family<PurchaseOrder?, String>((ref, id) async {
  return PurchaseOrderRepository.getById(id);
});

final purchaseOrderItemsProvider =
    FutureProvider.family<List<PurchaseOrderItem>, String>(
        (ref, orderId) async {
  final items = await PurchaseOrderRepository.getItems(orderId);
  return items;
});
