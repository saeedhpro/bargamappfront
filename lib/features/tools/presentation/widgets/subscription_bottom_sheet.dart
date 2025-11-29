import 'package:bargam_app/features/subscription/data/models/subscription_plan_model.dart';
import 'package:bargam_app/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SubscriptionBottomSheet extends StatefulWidget {
  const SubscriptionBottomSheet({super.key});

  @override
  State<SubscriptionBottomSheet> createState() => _SubscriptionBottomSheetState();
}

class _SubscriptionBottomSheetState extends State<SubscriptionBottomSheet> {

  @override
  void initState() {
    super.initState();
    // به محض باز شدن شیت، درخواست به سرور ارسال می‌شود
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // بررسی می‌کنیم اگر دیتا قبلاً لود نشده، لود کنیم
      context.read<SubscriptionProvider>().fetchPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    // استفاده از Directionality برای تضمین راست‌چین بودن
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        // ارتفاع داینامیک (حداکثر 70 درصد صفحه)
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            minHeight: MediaQuery.of(context).size.height * 0.4
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // هندل بالای شیت
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'برای استفاده از تمامی امکانات برنامه باید اشتراک تهیه کنید',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            // بدنه اصلی که وضعیت‌ها را مدیریت می‌کند
            Expanded(
              child: Consumer<SubscriptionProvider>(
                builder: (context, provider, child) {
                  // ۱. حالت لودینگ
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // ۲. حالت خطا
                  if (provider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            provider.error!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          TextButton.icon(
                            onPressed: () => provider.fetchPlans(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('تلاش مجدد'),
                          )
                        ],
                      ),
                    );
                  }

                  // ۳. حالت لیست خالی (یعنی کاربر اشتراک دارد)
                  if (provider.plans.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
                          SizedBox(height: 16),
                          Text(
                            'شما یک اشتراک فعال دارید.',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // ۴. نمایش لیست پلن‌ها
                  return ListView.separated(
                    itemCount: provider.plans.length,
                    separatorBuilder: (ctx, index) => const SizedBox(height: 12),
                    itemBuilder: (ctx, index) {
                      final plan = provider.plans[index];
                      return _SubscriptionItem(
                        plan: plan,
                        onBuy: () async {
                          final success = await provider.purchasePlan(plan.id);
                          if (success && mounted) {
                            Navigator.pop(context); // بستن شیت
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('اشتراک با موفقیت فعال شد'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionItem extends StatelessWidget {
  final SubscriptionPlanModel plan;
  final VoidCallback onBuy;

  const _SubscriptionItem({
    required this.plan,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9), // سبز خیلی روشن
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          // ستون اطلاعات (راست)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${plan.formattedPrice} تومان',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // دکمه خرید (چپ)
          ElevatedButton(
            onPressed: onBuy,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              elevation: 0,
            ),
            child: const Text(
              'خرید اشتراک',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
