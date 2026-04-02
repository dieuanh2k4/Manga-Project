import 'package:retrofit/retrofit.dart';
import 'package:web_admin/core/constants/constants.dart';
import 'package:dio/dio.dart';
import 'package:web_admin/featured/manage_manga/data/models/manga.dart';

part 'new_api_service.g.dart';

@RestApi(baseUrl: newAPIBaseURL)
abstract class NewApiService {
  factory NewApiService(Dio dio) = _NewApiService;

  @GET('Manga/get-all-manga')
  Future<HttpResponse<List<MangaModel>>> getManga();
}
