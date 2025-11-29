import 'package:flutter/foundation.dart';
import '../../../../core/network/http_client.dart';
import '../../data/datasources/subscription_api_service.dart';
import '../../data/models/subscription_plan_model.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionApiService _apiService;

  List<SubscriptionPlanModel> _plans = [];
  bool _isLoading = false;
  String? _error;

  List<SubscriptionPlanModel> get plans => _plans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // HttpClient در سازنده تزریق می‌شود
  SubscriptionProvider({required HttpClient httpClient})
      : _apiService = SubscriptionApiService(httpClient);

  Future<void> fetchPlans() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _plans = await _apiService.getPlans();
    } catch (e) {
      _error = 'خطا در دریافت پلن‌ها. اتصال اینترنت را بررسی کنید.';
      if (kDebugMode) {
        print('Subscription Fetch Error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// خروجی true یعنی خرید موفق بود
  Future<bool> purchasePlan(int planId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.purchasePlan(planId);
      // بعد از خرید موفق، لیست را رفرش می‌کنیم (که احتمالاً خالی برمی‌گردد چون اشتراک فعال داریم)
      await fetchPlans();
      return true;
    } catch (e) {
      _error = 'خطا در انجام تراکنش';
      if (kDebugMode) {
        print('Purchase Error: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
