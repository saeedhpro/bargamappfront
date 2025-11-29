import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../core/error/exceptions.dart';
import '../models/plant_model.dart';

abstract class PlantLocalDataSource {
  Future<List<PlantModel>> getCachedPlants();
  Future<void> cachePlants(List<PlantModel> plants);
}

class PlantLocalDataSourceImpl implements PlantLocalDataSource {
  static const String _cachedPlantsKey = 'cached_plants';

  @override
  Future<List<PlantModel>> getCachedPlants() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cachedPlantsKey);

      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => PlantModel.fromJson(json)).toList();
    } catch (e) {
      throw CacheException('Failed to get cached plants: $e');
    }
  }

  @override
  Future<void> cachePlants(List<PlantModel> plants) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(
        plants.map((plant) => (plant as PlantModel).toJson()).toList(),
      );
      await prefs.setString(_cachedPlantsKey, jsonString);
    } catch (e) {
      throw CacheException('Failed to cache plants: $e');
    }
  }
}
