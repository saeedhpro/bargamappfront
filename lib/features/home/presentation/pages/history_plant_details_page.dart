import 'package:bargam_app/features/tools/presentation/providers/tool_provider.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/plant.dart';

class HistoryPlantDetailsPage extends StatefulWidget {
  final Plant plant;

  const HistoryPlantDetailsPage({super.key, required this.plant});

  @override
  State<HistoryPlantDetailsPage> createState() => _HistoryPlantDetailsPageState();
}

class _HistoryPlantDetailsPageState extends State<HistoryPlantDetailsPage> {
  bool _isAdding = false; // برای نمایش وضعیت لودینگ دکمه

  Future<void> _addToGarden() async {
    setState(() => _isAdding = true);

    // ✅ ذخیره ScaffoldMessenger قبل از async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await context.read<ToolProvider>().addToGarden(widget.plant.id);

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text("✅ با موفقیت به باغچه شما افزوده شد!"),
            backgroundColor: Color(0xFF5D8F67),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text("خطا: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // دسترسی به جزئیات ذخیره شده در مپ details
    final details = widget.plant.details;

    // نام فارسی یا علمی
    final commonName = (widget.plant.commonName != null && widget.plant.commonName!.isNotEmpty)
        ? widget.plant.commonName!
        : widget.plant.plantName;

    final scientificName = widget.plant.plantName;
    final imagePath = widget.plant.imagePath;

    // خواندن امن اطلاعات با مقادیر پیش‌فرض
    final description = details['description'] ?? 'توضیحات موجود نیست';
    final waterShort = details['water'] ?? 'نامشخص';
    final lightShort = details['light'] ?? 'نامشخص';
    final tempShort = details['temp'] ?? 'نامشخص';
    final difficulty = details['difficulty'] ?? 'نامشخص';
    final waterDetail = details['water_detail'] ?? description;
    final nameFa = details['name_fa'] ?? commonName;
    final lightDetail = details['light_detail'] ?? 'اطلاعات دقیق موجود نیست';
    final fertilizer = details['fertilizer'] ?? 'کود عمومی';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // 1. هدر و عکس پس‌زمینه
          Positioned(
            top: 0, left: 0, right: 0, height: 300,
            child: _buildHeaderImage(imagePath),
          ),

          // 2. دکمه بازگشت
          Positioned(
            top: 40, left: 20, right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Text(
                    "مشخصات گیاه",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black45)]
                    )
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // 3. کارت سفید و محتوا
          Positioned.fill(
            top: 220,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30)
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 100), // ✅ پدینگ پایین برای دکمه
                child: Column(
                  children: [
                    Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2)
                        )
                    ),
                    const SizedBox(height: 20),

                    // نام‌ها
                    Text(
                        nameFa,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center
                    ),
                    const SizedBox(height: 8),
                    Text(
                        scientificName,
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic
                        ),
                        textAlign: TextAlign.center
                    ),
                    const SizedBox(height: 30),

                    // کارت‌های وضعیت (آب، نور، دما)
                    const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                            "مراقبت و شرایط نگهداری",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                        )
                    ),
                    const SizedBox(height: 15),
                    _buildStatusCard(
                        title: "آبیاری مناسب",
                        value: waterShort,
                        icon: Icons.water_drop_outlined
                    ),
                    const SizedBox(height: 10),
                    _buildStatusCard(
                        title: "نور مناسب",
                        value: lightShort,
                        icon: Icons.wb_sunny_outlined
                    ),
                    const SizedBox(height: 10),
                    _buildStatusCard(
                        title: "دمای مناسب",
                        value: tempShort,
                        icon: Icons.thermostat_outlined
                    ),
                    const SizedBox(height: 20),
                    const Divider(),

                    // لیست‌های بازشو برای جزئیات بیشتر
                    _buildExpandableTile(
                        context,
                        title: "سختی نگهداری",
                        value: difficulty,
                        icon: Icons.equalizer,
                        isSimpleText: true
                    ),
                    _buildExpandableTile(
                        context,
                        title: "توضیحات کلی",
                        value: description,
                        icon: Icons.info_outline
                    ),
                    _buildExpandableTile(
                        context,
                        title: "نحوه آبیاری",
                        value: waterDetail,
                        icon: Icons.water_drop
                    ),
                    _buildExpandableTile(
                        context,
                        title: "کود مناسب",
                        value: fertilizer,
                        icon: Icons.spa_outlined
                    ),
                    _buildExpandableTile(
                        context,
                        title: "جزئیات نور",
                        value: lightDetail,
                        icon: Icons.light_mode_outlined
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ✅ دکمه شناور پایین (مثل PlantDetailsPage)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _isAdding ? null : _addToGarden,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D8F67),
                disabledBackgroundColor: Colors.grey[300],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)
                ),
              ),
              child: _isAdding
                  ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2
                  )
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add),
                  SizedBox(width: 8),
                  Text(
                      "افزودن به باغچه من",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold
                      )
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderImage(String imagePath) {
    if (imagePath.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator())
        ),
        errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 50, color: Colors.grey)
        ),
      );
    }
    return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.local_florist, size: 50, color: Colors.grey)
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String value,
    required IconData icon
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2)
            )
          ]
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
            children: [
              Icon(icon, color: const Color(0xFF5D8F67), size: 28),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            title,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87
                            )
                        ),
                        const SizedBox(height: 4),
                        Text(
                            value,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500])
                        )
                      ]
                  )
              )
            ]
        ),
      ),
    );
  }

  Widget _buildExpandableTile(
      BuildContext context, {
        required String title,
        required String value,
        required IconData icon,
        bool isSimpleText = false
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12)
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ExpansionTile(
            leading: Icon(icon, color: const Color(0xFF5D8F67)),
            title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
            ),
            trailing: isSimpleText
                ? Text(
                value,
                style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold
                )
            )
                : const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            children: isSimpleText
                ? []
                : [
              Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                      value,
                      style: TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          color: Colors.grey[700]
                      ),
                      textAlign: TextAlign.justify
                  )
              )
            ],
          ),
        ),
      ),
    );
  }
}
