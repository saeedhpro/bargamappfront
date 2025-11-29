import 'package:hive/hive.dart';
import '../models/plant_model.dart';

abstract class PlantLocalDataSource {
  Future<List<PlantModel>> getCachedPlants();
  Future<void> cachePlants(List<PlantModel> plants);
  Future<PlantModel?> getCachedPlantById(String id);
  Future<void> cachePlant(PlantModel plant);
}

class PlantLocalDataSourceImpl implements PlantLocalDataSource {
  final Box _box = Hive.box('plants');

  @override
  Future<List<PlantModel>> getCachedPlants() async {
    final data = _box.get('all_plants');
    if (data == null) return [];

    final List<dynamic> jsonList = data as List<dynamic>;
    return jsonList.map((json) => PlantModel.fromJson(json)).toList();
  }

  @override
  Future<void> cachePlants(List<PlantModel> plants) async {
    final jsonList = plants.map((plant) => plant.toJson()).toList();
    await _box.put('all_plants', jsonList);
  }

  @override
  Future<PlantModel?> getCachedPlantById(String id) async {
    final data = _box.get('plant_$id');
    if (data == null) return null;
    return PlantModel.fromJson(data);
  }

  @override
  Future<void> cachePlant(PlantModel plant) async {
    await _box.put('plant_${plant.id}', plant.toJson());
  }
}
