import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/supplier_model.dart';
import '../data/supplier_repository.dart';

final supplierSearchProvider = StateProvider<String>((ref) => '');
final supplierTypeFilterProvider = StateProvider<String?>((ref) => null);

final suppliersProvider =
    FutureProvider.family<List<Supplier>, void>((ref, _) async {
  final search = ref.watch(supplierSearchProvider);
  final type = ref.watch(supplierTypeFilterProvider);
  return SupplierRepository.getAll(
    search: search.isNotEmpty ? search : null,
    supplyType: type,
  );
});

final supplierDetailProvider =
    FutureProvider.family<Supplier?, String>((ref, id) async {
  return SupplierRepository.getById(id);
});

final supplierTotalDebtProvider = FutureProvider<double>((ref) async {
  return SupplierRepository.getTotalDebt();
});
