import 'package:flutter/foundation.dart';
import '../../../../core/network/http_client.dart';
import '../../domain/entities/garden_plant.dart';

enum GardenStatus {
  initial,
  loading,
  loaded,
  empty,
  error,
}

class GardenProvider extends ChangeNotifier {
  final HttpClient httpClient;

  GardenStatus _status = GardenStatus.initial;
  List<GardenPlant> _plants = [];
  String? _errorMessage;

  // Getters
  GardenStatus get status => _status;
  List<GardenPlant> get plants => _plants;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == GardenStatus.loading;

  GardenProvider({
    required this.httpClient,
  });

  /// دریافت لیست گیاهان از سرور
  Future<void> fetchPlants() async {
    try {
      _setStatus(GardenStatus.loading);
      _clearError();

      // درخواست GET به اندپوینت لیست
      final response = await httpClient.get('/garden/list');

      if (response is List) {
        _plants = response.map((json) => GardenPlant.fromJson(json)).toList();
        print(_plants[0].pestControl);
        if (_plants.isEmpty) {
          _setStatus(GardenStatus.empty);
        } else {
          _setStatus(GardenStatus.loaded);
        }
      } else {
        throw Exception('فرمت پاسخ نامعتبر است');
      }
    } catch (e) {
      _setError('خطا در دریافت لیست گیاهان. لطفاً اتصال اینترنت را بررسی کنید.');
      // اگر لیست قبلی وجود داشت، آن را پاک نمی‌کنیم تا کاربر صفحه سفید نبیند،
      // اما اگر لیست خالی بود و ارور خوردیم، وضعیت ارور ست می‌شود.
      if (_plants.isEmpty) {
        _setStatus(GardenStatus.error);
      } else {
        // اگر دیتا داشتیم و فقط رفرش فیل شد، وضعیت را به loaded برمی‌گردانیم تا UI نپرد
        _setStatus(GardenStatus.loaded);
      }
    }
  }

  /// حذف گیاه از باغچه
  /// خروجی: true اگر موفق بود
  Future<bool> deletePlant(int id) async {
    // ذخیره وضعیت فعلی برای بازگردانی در صورت خطا (Optimistic Update)
    final previousList = List<GardenPlant>.from(_plants);
    final previousStatus = _status;

    try {
      // ۱. حذف ظاهری و سریع از لیست (برای UX بهتر)
      _plants.removeWhere((element) => element.id == id);
      if (_plants.isEmpty) {
        _status = GardenStatus.empty;
      }
      notifyListeners();

      await httpClient.delete('/garden/$id');

      return true;

    } catch (e) {
      print("Error deleting plant: $e");

      _plants = previousList;
      _status = previousStatus;
      _setError('خطا در حذف گیاه. لطفاً مجدداً تلاش کنید.');

      return false;
    }
  }

  void _setStatus(GardenStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
