import 'package:bargam_app/features/garden/domain/entities/garden_plant.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/garden_provider.dart';

class GardenDetailsPage extends StatefulWidget {
  final GardenPlant plant;

  const GardenDetailsPage({super.key, required this.plant});

  @override
  State<GardenDetailsPage> createState() => _GardenDetailsPageState();
}

class _GardenDetailsPageState extends State<GardenDetailsPage> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    // دسترسی به جزئیات ذخیره شده در مپ details
    final details = widget.plant.details;

    final commonName = widget.plant.nickname;
    final scientificName = widget.plant.plantName;
    final imageUrl = widget.plant.imageUrl;

    // خواندن امن اطلاعات با مقادیر پیش‌فرض
    final description = details['description'] ?? 'توضیحات موجود نیست';
    final waterShort = details['water'] ?? 'نامشخص';
    final lightShort = details['light'] ?? 'نامشخص';
    final tempShort = details['temp'] ?? 'نامشخص';
    final difficulty = details['difficulty'] ?? 'نامشخص';
    final waterDetail = details['water_detail'] ?? description;
    final lightDetail = details['light_detail'] ?? 'اطلاعات دقیق موجود نیست';
    final fertilizer = details['fertilizer'] ?? 'کود عمومی';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // 1. هدر و عکس پس‌زمینه
          Positioned(
            top: 0, left: 0, right: 0, height: 300,
            child: _buildHeaderImage(imageUrl),
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
                const Text("مشخصات گیاه", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 10, color: Colors.black45)])),
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
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 100),
                child: Column(
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 20),

                    // نام‌ها
                    Text(commonName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(scientificName, style: TextStyle(fontSize: 16, color: Colors.grey[600], fontStyle: FontStyle.italic), textAlign: TextAlign.center),
                    const SizedBox(height: 30),

                    // کارت‌های وضعیت (آب، نور، دما)
                    const Align(alignment: Alignment.centerRight, child: Text("مراقبت و شرایط نگهداری", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 15),
                    _buildStatusCard(title: "آبیاری مناسب", value: waterShort, icon: Icons.water_drop_outlined),
                    const SizedBox(height: 10),
                    _buildStatusCard(title: "نور مناسب", value: lightShort, icon: Icons.wb_sunny_outlined),
                    const SizedBox(height: 10),
                    _buildStatusCard(title: "دمای مناسب", value: tempShort, icon: Icons.thermostat_outlined),
                    const SizedBox(height: 20),
                    const Divider(),

                    // لیست‌های بازشو برای جزئیات بیشتر
                    _buildExpandableTile(context, title: "سختی نگهداری", value: difficulty, icon: Icons.equalizer, isSimpleText: true),
                    _buildExpandableTile(context, title: "توضیحات کلی", value: description, icon: Icons.info_outline),
                    _buildExpandableTile(context, title: "نحوه آبیاری", value: waterDetail, icon: Icons.water_drop),
                    _buildExpandableTile(context, title: "کود مناسب", value: fertilizer, icon: Icons.spa_outlined),
                    _buildExpandableTile(context, title: "جزئیات نور", value: lightDetail, icon: Icons.light_mode_outlined),
                  ],
                ),
              ),
            ),
          ),

          // 4. دکمه حذف شناور در پایین
          Positioned(
            bottom: 20, left: 20, right: 20,
            child: ElevatedButton(
              onPressed: _isDeleting
                  ? null
                  : () async {
                // دیالوگ تایید حذف
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("حذف گیاه", textAlign: TextAlign.right),
                    content: const Text("آیا مطمئن هستید که می‌خواهید این گیاه را از باغچه حذف کنید؟", textAlign: TextAlign.right),
                    actions: [
                      TextButton(child: const Text("لغو"), onPressed: () => Navigator.pop(ctx, false)),
                      TextButton(child: const Text("حذف", style: TextStyle(color: Colors.red)), onPressed: () => Navigator.pop(ctx, true)),
                    ],
                  ),
                );

                if (confirm == true) {
                  setState(() => _isDeleting = true);
                  // فراخوانی حذف از طریق Provider
                  await context.read<GardenProvider>().deletePlant(widget.plant.id);
                  if (mounted) {
                    Navigator.pop(context); // بازگشت به لیست بعد از حذف
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400], // قرمز برای حذف
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isDeleting
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline),
                  SizedBox(width: 8),
                  Text("حذف از باغچه من", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ویجت کمکی برای عکس هدر
  Widget _buildHeaderImage(String? networkUrl) {
    if (networkUrl != null && networkUrl.isNotEmpty) {
      return Image.network(
        networkUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 50, color: Colors.grey)),
      );
    }
    return Container(color: Colors.grey[300], child: const Icon(Icons.local_florist, size: 50, color: Colors.grey));
  }

  // ویجت کمکی برای کارت‌های وضعیت (آب، نور...)
  Widget _buildStatusCard({required String title, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(children: [Icon(icon, color: const Color(0xFF5D8F67), size: 28), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)), const SizedBox(height: 4), Text(value, style: TextStyle(fontSize: 12, color: Colors.grey[500]))]))]),
      ),
    );
  }

  // ویجت کمکی برای لیست‌های بازشو
  Widget _buildExpandableTile(BuildContext context, {required String title, required String value, required IconData icon, bool isSimpleText = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ExpansionTile(
            leading: Icon(icon, color: const Color(0xFF5D8F67)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            trailing: isSimpleText ? Text(value, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)) : const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            children: isSimpleText ? [] : [Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: Text(value, style: TextStyle(fontSize: 13, height: 1.6, color: Colors.grey[700]), textAlign: TextAlign.justify))],
          ),
        ),
      ),
    );
  }
}
