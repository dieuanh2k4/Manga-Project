import '../entities/history_item_entity.dart';

abstract class HistoryRepository {
  Future<List<HistoryItemEntity>> getHistory(String token);
}
