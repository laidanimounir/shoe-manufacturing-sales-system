import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/raw_material_model.dart';
import '../data/raw_material_repository.dart';

final rawMaterialWarehouseFilterProvider = StateProvider<String?>((ref) => null);
final rawMaterialSearchProvider = StateProvider<String>((ref) => '');

final rawMaterialsProvider =
    FutureProvider.family<List<RawMaterial>, void>((ref, _) async {
  final search = ref.watch(rawMaterialSearchProvider);
  final warehouseId = ref.watch(rawMaterialWarehouseFilterProvider);
  return RawMaterialRepository.getAll(
    search: search.isNotEmpty ? search : null,
    warehouseId: warehouseId,
  );
});

final lowStockProvider = FutureProvider<List<RawMaterial>>((ref) async {
  return RawMaterialRepository.getLowStock();
});
