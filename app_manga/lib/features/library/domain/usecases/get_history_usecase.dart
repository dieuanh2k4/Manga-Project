import '../entities/history_item_entity.dart';
import '../repositories/history_repository.dart';

class GetHistoryUseCase {
  final HistoryRepository repository;
  GetHistoryUseCase(this.repository);

  Future<List<HistoryItemEntity>> call(String token) {
    return repository.getHistory(token);
  }
}
