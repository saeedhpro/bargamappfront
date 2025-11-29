import 'package:bargam_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:bargam_app/features/tools/presentation/widgets/support_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plant_provider.dart';
import '../widgets/plant_card.dart';
import '../widgets/search_bar_widget.dart';
// مدل Plant را ایمپورت کنید (نه مدل دیتابیس، مدل دامین)
// import '../../domain/entities/plant.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // لود اولیه
    Future.microtask(
          () => context.read<PlantProvider>().loadPlants(refresh: true),
    );

    // لیسنر برای اسکرول بی نهایت
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // اگر به ۲۰۰ پیکسل آخر لیست رسیدیم، صفحه بعد را لود کن
      context.read<PlantProvider>().loadPlants(); // بدون refresh یعنی صفحه بعد
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user != null ? "کاربر: ${user.phoneNumber}" : "در حال بارگذاری...",
              style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined, color: Colors.white),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => const SupportBottomSheet(),
              );
            },
          ),
        ],
      ),
      body: authProvider.status == AuthStatus.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFFE8F5E9),
                      child: Icon(Icons.person, color: Color(0xFF4CAF50), size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'شماره موبایل ${user?.phoneNumber ?? "---"}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildSubscriptionStatus(user),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SearchBarWidget(
                  onChanged: (query) {
                    // استفاده از متد جدید سرچ
                    context.read<PlantProvider>().searchPlants(query);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<PlantProvider>(
              builder: (context, provider, child) {
                // فقط در لود اولیه یا رفرش کامل اسپینر اصلی را نشان بده
                if (provider.status == PlantLoadingStatus.loading && provider.plants.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.status == PlantLoadingStatus.error && provider.plants.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          provider.errorMessage ?? 'خطایی رخ داده است',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.refreshPlants(),
                          child: const Text('تلاش مجدد'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.plants.isEmpty) {
                  return const Center(
                    child: Text(
                      'گیاهی یافت نشد',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.refreshPlants(),
                  child: ListView.builder(
                    controller: _scrollController, // اتصال کنترلر اسکرول
                    padding: const EdgeInsets.all(16),
                    // اگر "دیتای بیشتر" داریم، یک آیتم اضافه برای لودینگ پایین لیست در نظر بگیر
                    itemCount: provider.plants.length + (provider.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.plants.length) {
                        // نمایش لودینگ در انتهای لیست
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return PlantCard(plant: provider.plants[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionStatus(dynamic user) {
    if (user == null) return const SizedBox();

    if (user.hasSubscription && user.subscription != null) {
      final sub = user.subscription!;
      final planName = sub.planTitle;
      String daysLeftText = "";
      if (sub.expiresAt != null) {
        try {
          final expiryDate = DateTime.parse(sub.expiresAt!);
          final now = DateTime.now();
          final difference = expiryDate.difference(now).inDays;
          final days = difference > 0 ? difference : 0;
          daysLeftText = " - $days روز مانده";
        } catch (e) {
          // ignore
        }
      }
      return Row(
        children: [
          Icon(Icons.verified, size: 16, color: Colors.green[700]),
          const SizedBox(width: 4),
          Text(
            '$planName$daysLeftText',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.red[400]),
          const SizedBox(width: 4),
          Text(
            'شما هیچ اشتراک فعالی ندارید',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.red[400],
            ),
          ),
        ],
      );
    }
  }
}
