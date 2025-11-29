import '../../../../core/network/http_client.dart';
import '../../../../core/error/exceptions.dart';
import '../models/plant_model.dart';

abstract class PlantRemoteDataSource {
  Future<List<PlantModel>> getPlants();
  Future<PlantModel> getPlantById(String id);
  Future<List<PlantModel>> searchPlants(String query);
}

class PlantRemoteDataSourceImpl implements PlantRemoteDataSource {
  final HttpClient httpClient;

  PlantRemoteDataSourceImpl({required this.httpClient});

  @override
  Future<List<PlantModel>> getPlants() async {
    try {
      final response = await httpClient.get('/plants');
      final List<dynamic> plantsJson = response['data'] ?? [];
      return plantsJson.map((json) => PlantModel.fromJson(json)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch plants: $e');
    }
  }

  @override
  Future<PlantModel> getPlantById(String id) async {
    try {
      final response = await httpClient.get('/plants/$id');
      return PlantModel.fromJson(response['data']);
    } catch (e) {
      throw ServerException('Failed to fetch plant: $e');
    }
  }

  @override
  Future<List<PlantModel>> searchPlants(String query) async {
    try {
      final response = await httpClient.get('/plants/search?q=$query');
      final List<dynamic> plantsJson = response['data'] ?? [];
      return plantsJson.map((json) => PlantModel.fromJson(json)).toList();
    } catch (e) {
      throw ServerException('Failed to search plants: $e');
    }
  }
}
