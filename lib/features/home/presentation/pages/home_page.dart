import 'package:bargam_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:bargam_app/features/tools/presentation/widgets/support_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plant_provider.dart';
import '../widgets/plant_card.dart';
import '../widgets/search_bar_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
          () => context.read<PlantProvider>().loadPlants(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    final ButtonStyle style = ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user != null ? "کاربر: ${user.phoneNumber}" : "در حال بارگذاری...",
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined, color: Colors.grey),
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
          ? const CircularProgressIndicator()
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
                          radius: 20,
                          backgroundColor: Color(0xFFE8F5E9),
                          child: Icon(Icons.person, color: Color(0xFF4CAF50)),
                        ),
                        const SizedBox(width: 12),
                        Consumer<PlantProvider>(
                          builder: (context, provider, child) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'شماره موبایل ${user!.phoneNumber}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'شما هیچ اشتراک فعالی ندارید',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SearchBarWidget(
                      onChanged: (query) {
                        context.read<PlantProvider>().searchPlants(query);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer<PlantProvider>(
                  builder: (context, provider, child) {
                    if (provider.status == PlantLoadingStatus.loading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (provider.status == PlantLoadingStatus.error) {
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
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.plants.length,
                        itemBuilder: (context, index) {
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
}
