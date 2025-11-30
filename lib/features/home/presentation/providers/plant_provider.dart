import 'package:bargam_app/features/home/domain/usecases/get_all_plants.dart';
import 'package:bargam_app/features/home/domain/usecases/search_plants.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/plant.dart';
import '../../domain/usecases/get_history_plants.dart';
import '../../domain/usecases/get_plant_details.dart';

enum PlantLoadingStatus { initial, loading, loaded, error }

class PlantProvider extends ChangeNotifier {
  final GetAllPlants getAllPlants;
  final SearchPlants searchPlants;
  final GetHistoryPlants getHistoryPlants;
  final GetPlantDetails getPlantDetails;

  PlantProvider({
    required this.getAllPlants,
    required this.searchPlants,
    required this.getHistoryPlants,
    required this.getPlantDetails,
  });

  PlantLoadingStatus _status = PlantLoadingStatus.initial;
  final List<Plant> _plants = [];
  String? _errorMessage;
  String _searchQuery = '';
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  Plant? _selectedPlant;

  // Getters
  PlantLoadingStatus get status => _status;
  List<Plant> get plants => _plants;
  String? get errorMessage => _errorMessage;
  Plant? get selectedPlant => _selectedPlant;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  String get searchQuery => _searchQuery;

  Future<void> loadPlants({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _plants.clear();
      _status = PlantLoadingStatus.loading;
      notifyListeners();
    } else {
      if (!_hasMore || _isLoadingMore) return;
      _isLoadingMore = true;
      notifyListeners();
    }

    final result = await getHistoryPlants(page: _page, search: _searchQuery);

    result.fold(
          (failure) {
        _status = PlantLoadingStatus.error;
        _errorMessage = failure.message;
        _isLoadingMore = false;
        notifyListeners();
      },
          (newPlants) {
        if (newPlants.isEmpty) {
          _hasMore = false;
        } else {
          _plants.addAll(newPlants);
          if (newPlants.length < 20) {
            _hasMore = false;
          } else {
            _page++;
          }
        }
        _status = PlantLoadingStatus.loaded;
        _isLoadingMore = false;
        _errorMessage = null;
        notifyListeners();
      },
    );
  }

  // ✅ متد جدید برای سرچ
  Future<void> searchPlantsWithQuery(String query) async {
    _searchQuery = query;
    _page = 1;
    _hasMore = true;
    _plants.clear();
    _status = PlantLoadingStatus.loading;
    notifyListeners();

    final result = await getHistoryPlants(page: _page, search: _searchQuery);

    result.fold(
          (failure) {
        _status = PlantLoadingStatus.error;
        _errorMessage = failure.message;
        notifyListeners();
      },
          (newPlants) {
        _plants.addAll(newPlants);
        if (newPlants.isEmpty || newPlants.length < 20) {
          _hasMore = false;
        } else {
          _page++;
        }
        _status = PlantLoadingStatus.loaded;
        _errorMessage = null;
        notifyListeners();
      },
    );
  }

  // ✅ پاک کردن سرچ
  void clearSearch() {
    _searchQuery = '';
    loadPlants(refresh: true);
  }

  // --- متد جزئیات ---
  Future<void> loadPlantDetails(String plantId) async {
    final result = await getPlantDetails(plantId);
    result.fold(
          (failure) {
        _errorMessage = failure.message;
        _selectedPlant = null;
      },
          (plant) {
        _selectedPlant = plant;
        _errorMessage = null;
      },
    );
    notifyListeners();
  }

  void clearSelectedPlant() {
    _selectedPlant = null;
    notifyListeners();
  }

  Future<void> refreshPlants() async {
    await loadPlants(refresh: true);
  }
}
