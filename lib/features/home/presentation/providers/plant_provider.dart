import 'package:bargam_app/features/home/domain/usecases/get_all_plants.dart';
import 'package:bargam_app/features/home/domain/usecases/get_plant_details.dart';
import 'package:bargam_app/features/home/domain/usecases/search_plants.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/plant.dart';

enum PlantLoadingStatus { initial, loading, loaded, error }

class PlantProvider extends ChangeNotifier {
  final GetAllPlants getAllPlants;
  final SearchPlants searchPlants;
  final GetPlantDetails getPlantDetails;

  PlantProvider({
    required this.getAllPlants,
    required this.searchPlants,
    required this.getPlantDetails,
  });

  PlantLoadingStatus _status = PlantLoadingStatus.initial;
  List<Plant> _plants = [];
  List<Plant> _filteredPlants = [];
  String? _errorMessage;
  String _searchQuery = '';
  Plant? _selectedPlant;

  PlantLoadingStatus get status => _status;
  List<Plant> get plants => _searchQuery.isEmpty ? _plants : _filteredPlants;
  String? get errorMessage => _errorMessage;
  Plant? get selectedPlant => _selectedPlant;

  Future<void> loadPlants() async {
    _status = PlantLoadingStatus.loading;
    notifyListeners();

    final result = await getAllPlants();
    result.fold(
          (failure) {
        _status = PlantLoadingStatus.error;
        _errorMessage = failure.message;
      },
          (plants) {
        _plants = plants;
        _status = PlantLoadingStatus.loaded;
        _errorMessage = null;
      },
    );
    notifyListeners();
  }

  Future<void> search(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      _filteredPlants = [];
      notifyListeners();
      return;
    }

    _status = PlantLoadingStatus.loading;
    notifyListeners();

    final result = await searchPlants(query);
    result.fold(
          (failure) {
        _status = PlantLoadingStatus.error;
        _errorMessage = failure.message;
        _filteredPlants = [];
      },
          (plants) {
        _filteredPlants = plants;
        _status = PlantLoadingStatus.loaded;
        _errorMessage = null;
      },
    );
    notifyListeners();
  }

  Future<void> loadPlantDetails(String plantId) async {
    _status = PlantLoadingStatus.loading;
    notifyListeners();

    final result = await getPlantDetails(plantId);
    result.fold(
          (failure) {
        _status = PlantLoadingStatus.error;
        _errorMessage = failure.message;
        _selectedPlant = null;
      },
          (plant) {
        _selectedPlant = plant;
        _status = PlantLoadingStatus.loaded;
        _errorMessage = null;
      },
    );
    notifyListeners();
  }

  Future<void> refreshPlants() async {
    await loadPlants();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredPlants = [];
    notifyListeners();
  }

  void clearSelectedPlant() {
    _selectedPlant = null;
    notifyListeners();
  }
}
