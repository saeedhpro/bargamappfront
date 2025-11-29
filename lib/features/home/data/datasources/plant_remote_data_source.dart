import '../../../../core/network/http_client.dart';
import '../../../../core/error/exceptions.dart';
import '../models/plant_model.dart';

abstract class PlantRemoteDataSource {
  Future<List<PlantModel>> getAllPlants();
  Future<List<PlantModel>> searchPlants(String query);
  Future<PlantModel> getPlantById(String id);
  Future<List<PlantModel>> getHistoryPlants({int page = 1, String? search});
}

class PlantRemoteDataSourceImpl implements PlantRemoteDataSource {
  final HttpClient httpClient;

  PlantRemoteDataSourceImpl({required this.httpClient});

  @override
  Future<List<PlantModel>> getAllPlants() async {
    try {
      final response = await httpClient.get('/plants');
      // response از نوع Map<String, dynamic> است
      final List<dynamic> data = response['data'] as List<dynamic>;
      return data.map((json) => PlantModel.fromJson(json)).toList();
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<List<PlantModel>> searchPlants(String query) async {
    try {
      final response = await httpClient.get('/plants/search?q=$query');
      final List<dynamic> data = response['data'] as List<dynamic>;
      return data.map((json) => PlantModel.fromJson(json)).toList();
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<PlantModel> getPlantById(String id) async {
    try {
      final response = await httpClient.get('/plants/$id');
      return PlantModel.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<List<PlantModel>> getHistoryPlants({int page = 1, String? search}) async {
    final StringBuffer queryString = StringBuffer('?page=$page&limit=20');

    if (search != null && search.isNotEmpty) {
      queryString.write('&search=$search');
    }

    try {
      final response = await httpClient.get('/garden/history${queryString.toString()}');

      List<dynamic> data;
      if (response is List) {
        data = response;
      } else if (response is Map && response.containsKey('data')) {
        data = response['data'];
      } else {
        return [];
      }

      return data.map((json) => PlantModel.fromJson(json)).toList();
    } catch (e) {
      if (e is! AuthException && e is! NetworkException) {
        throw ServerException();
      }
      rethrow;
    }
  }
}
