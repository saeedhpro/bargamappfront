import '../../../../core/network/http_client.dart';
import '../models/subscription_plan_model.dart';

class SubscriptionApiService {
  final HttpClient _httpClient;

  SubscriptionApiService(this._httpClient);

  Future<List<SubscriptionPlanModel>> getPlans() async {
    try {
      // فرض: روت بک‌اند شما /subscriptions/plans است
      final response = await _httpClient.get('/subscriptions/plans');

      // چون خروجی HttpClient رو dynamic کردیم، اینجا چک میکنیم لیسته یا نه
      if (response is List) {
        return response.map((e) => SubscriptionPlanModel.fromJson(e)).toList();
      } else {
        // اگر بک‌اند لیست رو داخل یک آبجکت مثل { "data": [...] } گذاشته باشد
        if (response['data'] != null && response['data'] is List) {
          return (response['data'] as List)
              .map((e) => SubscriptionPlanModel.fromJson(e))
              .toList();
        }
        return [];
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> purchasePlan(int planId) async {
    try {
      // متد POST برای خرید
      await _httpClient.post('/subscriptions/purchase/$planId');
    } catch (e) {
      rethrow;
    }
  }
}
