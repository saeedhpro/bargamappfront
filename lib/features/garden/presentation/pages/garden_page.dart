import 'package:bargam_app/features/main/main_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/garden_provider.dart';
import 'garden_details_page.dart';
class GardenPage extends StatefulWidget {
  const GardenPage({super.key});

  @override
  State<GardenPage> createState() => _GardenPageState();
}

class _GardenPageState extends State<GardenPage> {
  @override
  void initState() {
    super.initState();
    // دریافت لیست هر بار که صفحه ساخته می‌شود
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    Provider.of<GardenProvider>(context, listen: false).fetchPlants();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GardenProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("باغچه من", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.green, size: 18),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const MainPage(),
                ),
                    (Route<dynamic> route) => false,
              );
            },
          ),
        ),
      ),
      body: Column(
        children: [
          // --- بنر سبز رنگ بالای صفحه ---
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "یادآورها تنها در نسخه اندروید فعال هستند. با این حال می‌توانید آن‌ها را اضافه یا ویرایش کنید.",
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.green[800], fontSize: 12),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.info_outline, color: Colors.green[800]),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: const Size(0, 30),
                  ),
                  child: const Text("دانلود اپ", style: TextStyle(fontSize: 10, color: Colors.white)),
                )
              ],
            ),
          ),

          // --- محتوای اصلی ---
          Expanded(
            child: Builder(
              builder: (context) {
                // ۱. حالت لودینگ
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: Colors.green));
                }

                // ۲. حالت لیست خالی
                if (provider.plants.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_florist_outlined, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          "هنوز گیاهی به باغچه اضافه نکرده‌اید\nیا ارتباط با سرور برقرار نشد.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _fetchData,
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text("دریافت مجدد", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // ۳. نمایش لیست
                return RefreshIndicator(
                  onRefresh: () async => _fetchData(),
                  color: Colors.green,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.plants.length,
                    itemBuilder: (context, index) {
                      final plant = provider.plants[index];

                      // --- تغییر اصلی: اضافه کردن GestureDetector ---
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GardenDetailsPage(plant: plant),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Row(
                              children: [
                                // عکس گیاه
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                    topLeft: Radius.circular(4),
                                    bottomLeft: Radius.circular(4),
                                  ),
                                  child: plant.imageUrl != null
                                      ? Image.network(
                                    plant.imageUrl!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, o, s) => Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image_not_supported),
                                    ),
                                  )
                                      : Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.local_florist, color: Colors.grey),
                                  ),
                                ),

                                // متن‌ها
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          plant.nickname,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          plant.plantName,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // منوی سه نقطه
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      provider.deletePlant(plant.id);
                                    }
                                    // هندل کردن یادآوری در آینده
                                  },
                                  itemBuilder: (BuildContext context) => [
                                    const PopupMenuItem(
                                      value: 'reminder',
                                      child: Row(
                                        textDirection: TextDirection.rtl,
                                        children: [
                                          Icon(Icons.add, size: 18, color: Colors.grey),
                                          SizedBox(width: 8),
                                          Text("افزودن یادآوری", style: TextStyle(fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        textDirection: TextDirection.rtl,
                                        children: [
                                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text("حذف گیاه از باغچه",
                                              style: TextStyle(fontSize: 14, color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
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
