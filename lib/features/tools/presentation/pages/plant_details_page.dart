import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart'; // حتماً این را اضافه کنید
import '../providers/tool_provider.dart'; // مسیر فایل پرووایدر خود را چک کنید

class PlantDetailsPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final XFile? userImageFile;

  const PlantDetailsPage({
    super.key,
    required this.data,
    this.userImageFile,
  });

  @override
  State<PlantDetailsPage> createState() => _PlantDetailsPageState();
}

class _PlantDetailsPageState extends State<PlantDetailsPage> {
  bool _isAdding = false; // برای نمایش وضعیت لودینگ دکمه

  @override
  Widget build(BuildContext context) {
    // دسترسی به داده‌ها از طریق widget.data
    final commonName = widget.data['common_name'] ?? 'نامشخص';
    final scientificName = widget.data['plant_name'] ?? '';
    final description = widget.data['description'] ?? 'توضیحات موجود نیست';

    final waterShort = widget.data['water'] ?? 'نامشخص';
    final lightShort = widget.data['light'] ?? 'نامشخص';
    final tempShort = widget.data['temp'] ?? 'نامشخص';

    final difficulty = widget.data['difficulty'] ?? 'نامشخص';
    final waterDetail = widget.data['water_detail'] ?? description;
    final lightDetail = widget.data['light_detail'] ?? 'اطلاعات دقیق موجود نیست';
    final fertilizer = widget.data['fertilizer'] ?? 'کود عمومی';

    // گرفتن History ID از پاسخ سرور
    final historyId = widget.data['history_id'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // هدر عکس
          Positioned(
            top: 0, left: 0, right: 0, height: 300,
            child: _buildHeaderImage(widget.data['image_url']),
          ),
          // دکمه بازگشت
          Positioned(
            top: 40, left: 20, right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text("مشخصات گیاه", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 48),
              ],
            ),
          ),
          // بدنه اصلی سفید
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
                    Text(commonName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(scientificName, style: TextStyle(fontSize: 16, color: Colors.grey[600], fontStyle: FontStyle.italic), textAlign: TextAlign.center),
                    const SizedBox(height: 30),
                    const Align(alignment: Alignment.centerRight, child: Text("مراقبت و شرایط نگهداری", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 15),
                    _buildStatusCard(title: "آبیاری مناسب", value: waterShort, icon: Icons.water_drop_outlined),
                    const SizedBox(height: 10),
                    _buildStatusCard(title: "نور مناسب", value: lightShort, icon: Icons.wb_sunny_outlined),
                    const SizedBox(height: 10),
                    _buildStatusCard(title: "دمای مناسب", value: tempShort, icon: Icons.thermostat_outlined),
                    const SizedBox(height: 20),
                    const Divider(),
                    // اینجا context را پاس می‌دهیم
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
          // دکمه شناور پایین (اصلاح شده)
          Positioned(
            bottom: 20, left: 20, right: 20,
            child: ElevatedButton(
              onPressed: _isAdding || historyId == null
                  ? null // اگر در حال افزودن است یا ID ندارد غیرفعال شود
                  : () async {
                setState(() => _isAdding = true);
                try {
                  // فراخوانی پرووایدر
                  await context.read<ToolProvider>().addToGarden(historyId);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("✅ با موفقیت به باغچه شما افزوده شد!"),
                        backgroundColor: Color(0xFF5D8F67),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("خطا: $e"), backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isAdding = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D8F67),
                disabledBackgroundColor: Colors.grey[300],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isAdding
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add),
                  SizedBox(width: 8),
                  Text("افزودن به باغچه من", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ... متدهای کمکی مثل قبل هستند (_buildHeaderImage, _buildStatusCard, ...)
  Widget _buildHeaderImage(String? networkUrl) {
    if (!kIsWeb && widget.userImageFile != null) {
      return Image.file(File(widget.userImageFile!.path), fit: BoxFit.cover);
    } else if (networkUrl != null && networkUrl.isNotEmpty) {
      // توجه: آدرس لوکال هاست اندروید با کامپیوتر فرق دارد.
      // اگر روی ایمولاتور هستید آدرس باید 10.0.2.2 باشد.
      // اگر عکس لود نشد، باید BaseUrl را به ابتدای networkUrl اضافه کنید
      return Image.network(networkUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300], child: Icon(Icons.broken_image)));
    }
    return Container(color: Colors.grey[300]);
  }

  Widget _buildStatusCard({required String title, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(children: [Icon(icon, color: const Color(0xFF5D8F67), size: 28), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)), const SizedBox(height: 4), Text(value, style: TextStyle(fontSize: 12, color: Colors.grey[500]))]))]),
    );
  }

  Widget _buildExpandableTile(BuildContext context, {required String title, required String value, required IconData icon, bool isSimpleText = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: const Color(0xFF5D8F67)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          trailing: isSimpleText ? Text(value, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)) : const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          children: isSimpleText ? [] : [Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: Text(value, style: TextStyle(fontSize: 13, height: 1.6, color: Colors.grey[700]), textAlign: TextAlign.justify))],
        ),
      ),
    );
  }
}
