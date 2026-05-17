import '../../domain/entities/history_item_entity.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_remote_data_source.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryRemoteDataSource remoteDataSource;
  HistoryRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<HistoryItemEntity>> getHistory(String token) async {
    final models = await remoteDataSource.getHistory(token);
    return models.map((item) => item.toEntity()).toList();
  }
}
