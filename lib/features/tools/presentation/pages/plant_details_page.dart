import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/tool_provider.dart';

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
  bool _isLoading = false;
  bool _isInGarden = false;

  @override
  void initState() {
    super.initState();
    _isInGarden = widget.data['in_garden'] ?? false;
  }

  /// افزودن یا حذف از باغچه
  Future<void> _handleGardenToggle(int historyId) async {
    setState(() => _isLoading = true);
    final provider = context.read<ToolProvider>();

    try {
      if (_isInGarden) {
        await provider.removeFromGarden(historyId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("🗑️ گیاه از باغچه حذف شد."),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _isInGarden = false);
        }
      } else {
        await provider.addToGarden(historyId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ به باغچه‌ی شما افزوده شد."),
              backgroundColor: Color(0xFF5D8F67),
            ),
          );
          setState(() => _isInGarden = true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطا: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// تابع کمکی برای تبدیل مقدار به رشتهٔ خوانا،
  /// درصورتی‌که نوع آن Map یا List باشد.
  String _formatValue(dynamic value) {
    if (value == null) return 'اطلاعاتی موجود نیست';

    if (value is String) return value;
    if (value is Map) {
      return value.entries.map((e) => "• ${e.key}: ${e.value}").join("\n");
    }
    if (value is List) {
      return value.map((e) => "• $e").join("\n");
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final commonName = data['common_name'] ?? 'نامشخص';
    final nameFa = data['name_fa'] ?? commonName;
    final scientificName = data['plant_name'] ?? '';
    final historyId = data['history_id'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // ● تصویر بالا
          Positioned(
            top: 0, left: 0, right: 0, height: 300,
            child: _buildHeaderImage(widget.data['image_url']),
          ),

          // ● نوار بالا
          Positioned(
            top: 40, left: 20, right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  "مشخصات گیاه",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // ● محتوای صفحه
          Positioned.fill(
            top: 220,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 120),
                child: Column(
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 20),
                    Text(nameFa, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(scientificName, style: const TextStyle(fontSize: 16, color: Colors.grey, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
                    const SizedBox(height: 30),

                    /// --- وضعیت نگهداری ---
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text("مراقبت و شرایط نگهداری", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 15),

                    _buildStatusCard(title: "آبیاری مناسب", value: _formatValue(data['water']), icon: Icons.water_drop_outlined),
                    const SizedBox(height: 10),
                    _buildStatusCard(title: "نور مناسب", value: _formatValue(data['light']), icon: Icons.wb_sunny_outlined),
                    const SizedBox(height: 10),
                    _buildStatusCard(title: "دمای مناسب", value: _formatValue(data['temp']), icon: Icons.thermostat_outlined),

                    const SizedBox(height: 25),
                    const Divider(),
                    const SizedBox(height: 10),

                    /// --- جزئیات ---
                    _buildExpandableTile(context, title: "توضیحات کلی", value: _formatValue(data['description']), icon: Icons.info_outline),
                    _buildExpandableTile(context, title: "نحوه آبیاری", value: _formatValue(data['water_detail']), icon: Icons.water_drop),
                    _buildExpandableTile(context, title: "نور و موقعیت", value: _formatValue(data['light_detail']), icon: Icons.light_mode_outlined),
                    _buildExpandableTile(context, title: "کود مناسب", value: _formatValue(data['fertilizer']), icon: Icons.spa_outlined),
                    _buildExpandableTile(context, title: "سختی نگهداری", value: _formatValue(data['difficulty']), icon: Icons.equalizer),

                    /// --- اطلاعات سلامت گیاه ---
                    _buildExpandableTile(
                      context,
                      title: "آفات و بیماری‌های رایج",
                      value: _formatValue(data['diseases']),
                      icon: Icons.bug_report_outlined,
                    ),
                    _buildExpandableTile(
                      context,
                      title: "روش‌های کنترل آفات و بیماری‌ها",
                      value: _formatValue(data['pest_control']),
                      icon: Icons.healing_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ● دکمه پایین
          Positioned(
            bottom: 20, left: 20, right: 20,
            child: ElevatedButton(
              onPressed: _isLoading || historyId == null ? null : () => _handleGardenToggle(historyId),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isInGarden ? const Color(0xFFD32F2F) : const Color(0xFF5D8F67),
                disabledBackgroundColor: Colors.grey[300],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isInGarden ? Icons.remove_circle_outline : Icons.add_circle_outline),
                  const SizedBox(width: 8),
                  Text(
                    _isInGarden ? "حذف از باغچه من" : "افزودن به باغچه من",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ساخت ویجت تصویر سربرگ
  Widget _buildHeaderImage(String? networkUrl) {
    if (!kIsWeb && widget.userImageFile != null) {
      return Image.file(File(widget.userImageFile!.path), fit: BoxFit.cover);
    } else if (networkUrl != null && networkUrl.isNotEmpty) {
      return Image.network(
        networkUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image)),
      );
    }
    return Container(color: Colors.grey[300]);
  }

  /// کارت وضعیت (مثل آبیاری - نور - دما)
  Widget _buildStatusCard({required String title, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
      ]),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF5D8F67), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          ),
        ],
      ),
    );
  }

  /// تایل جمع‌شونده (ExpandableTile)
  Widget _buildExpandableTile(
      BuildContext context, {
        required String title,
        required String value,
        required IconData icon,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: const Color(0xFF5D8F67)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(value, style: const TextStyle(fontSize: 13, height: 1.6, color: Colors.black87), textAlign: TextAlign.justify),
            ),
          ],
        ),
      ),
    );
  }
}
