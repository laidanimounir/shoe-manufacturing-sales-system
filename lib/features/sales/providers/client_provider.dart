import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/client_model.dart';
import '../data/client_repository.dart';

final clientSearchProvider = StateProvider<String>((ref) => '');
final clientTypeFilterProvider = StateProvider<String?>((ref) => null);

final clientsProvider =
    FutureProvider.family<List<Client>, void>((ref, _) async {
  final search = ref.watch(clientSearchProvider);
  final type = ref.watch(clientTypeFilterProvider);
  return ClientRepository.getAll(
    search: search.isNotEmpty ? search : null,
    clientType: type,
  );
});

final clientDetailProvider =
    FutureProvider.family<Client?, String>((ref, id) async {
  return ClientRepository.getById(id);
});

final clientDebtProvider = FutureProvider<double>((ref) async {
  return ClientRepository.getDebtSummary();
});
