import 'package:bargam_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:bargam_app/features/chat/presentation/pages/chat_list_page.dart';
import 'package:bargam_app/features/tools/presentation/widgets/support_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // ✅ اضافه کن
import '../providers/plant_provider.dart';
import '../widgets/plant_card.dart';
import '../widgets/search_bar_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;

  final ScrollController _scrollController = ScrollController();
  bool _hasLoadedOnce = false;

  // ✅ برای Debounce
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasLoadedOnce) {
        _loadData();
        _hasLoadedOnce = true;
      }
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (mounted && _hasLoadedOnce) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadData();
        }
      });
    }
  }

  Future<void> _loadData() async {
    final provider = context.read<PlantProvider>();
    await provider.loadPlants(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounceTimer?.cancel(); // ✅ کنسل کردن تایمر
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<PlantProvider>();

      if (!provider.isLoadingMore && provider.hasMore) {
        provider.loadPlants();
      }
    }
  }

  Future<void> _onRefresh() async {
    await context.read<PlantProvider>().loadPlants(refresh: true);
  }

  // ✅ متد برای سرچ با Debounce
  void _onSearchChanged(String query) {
    // اگر تایمر قبلی داریم، کنسلش کن
    _debounceTimer?.cancel();

    // تایمر جدید بساز که بعد از 500 میلی‌ثانیه اجرا شه
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.isEmpty) {
        context.read<PlantProvider>().clearSearch();
      } else {
        context.read<PlantProvider>().searchPlantsWithQuery(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatListPage()),
              );
              // showModalBottomSheet(
              //   context: context,
              //   backgroundColor: Colors.transparent,
              //   isScrollControlled: true,
              //   builder: (context) => const SupportBottomSheet(),
              // );
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
                      child: Icon(
                        Icons.person,
                        color: Color(0xFF4CAF50),
                        size: 28,
                      ),
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
                  onChanged: _onSearchChanged, // ✅ استفاده از متد جدید
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<PlantProvider>(
              builder: (context, provider, child) {
                if (provider.status == PlantLoadingStatus.loading &&
                    provider.plants.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.status == PlantLoadingStatus.error &&
                    provider.plants.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.errorMessage ?? 'خطایی رخ داده است',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.loadPlants(refresh: true),
                          child: const Text('تلاش مجدد'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.plants.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Text(
                            'گیاهی یافت نشد',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: Colors.green,
                  backgroundColor: Colors.white,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.plants.length +
                        (provider.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.plants.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
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
