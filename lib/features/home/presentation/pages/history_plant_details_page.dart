import 'package:bargam_app/features/tools/presentation/providers/tool_provider.dart';
import 'package:bargam_app/features/garden/presentation/providers/garden_provider.dart';
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
  bool _isProcessing = false;
  late bool _isInGarden;
  int? _gardenId;

  @override
  void initState() {
    super.initState();
    _isInGarden = widget.plant.inGarden ?? false;
    _gardenId = widget.plant.gardenId;
  }

  Future<void> _addToGarden() async {
    setState(() => _isProcessing = true);
    final scaffold = ScaffoldMessenger.of(context);

    try {
      final res = await context.read<ToolProvider>().addToGarden(
        widget.plant.id,
        nickname: widget.plant.commonName,
      );
      setState(() {
        _isInGarden = true;
        _gardenId = res["garden_id"];
      });

      scaffold.showSnackBar(
        const SnackBar(
          content: Text("با موفقیت به باغچه افزوده شد"),
          backgroundColor: Color(0xFF5D8F67),
        ),
      );
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(
          content: Text("خطا: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _removeFromGarden() async {
    if (_gardenId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("حذف گیاه", textAlign: TextAlign.right),
        content: const Text(
          "آیا مطمئن هستید که می‌خواهید این گیاه را از باغچه حذف کنید؟",
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            child: const Text("لغو"),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          TextButton(
            child: const Text("حذف", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    final scaffold = ScaffoldMessenger.of(context);

    try {
      await context.read<ToolProvider>().removeFromGardenByGardenId(_gardenId!);

      setState(() {
        _isInGarden = false;
        _gardenId = null;
      });

      scaffold.showSnackBar(const SnackBar(
        content: Text("گیاه با موفقیت حذف شد"),
        backgroundColor: Colors.red,
      ));
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(content: Text("خطا: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = widget.plant.details;
    final imagePath = widget.plant.imagePath;

    final commonName = widget.plant.commonName?.isNotEmpty == true
        ? widget.plant.commonName!
        : widget.plant.plantName;

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
          _buildTopImage(imagePath),

          _buildHeaderBar(),

          _buildScrollableContent(
            nameFa: nameFa,
            englishName: widget.plant.plantName,
            description: description,
            waterShort: waterShort,
            lightShort: lightShort,
            tempShort: tempShort,
            difficulty: difficulty,
            waterDetail: waterDetail,
            fertilizer: fertilizer,
            lightDetail: lightDetail,
          ),

          _buildActionButton(),
        ],
      ),
    );
  }

  // --------------------- UI HELPERS ---------------------

  Widget _buildTopImage(String imagePath) {
    if (imagePath.isNotEmpty) {
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: 300,
        child: CachedNetworkImage(
          imageUrl: imagePath,
          fit: BoxFit.cover,
          placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
          errorWidget: (_, __, ___) =>
          const Icon(Icons.broken_image, color: Colors.grey, size: 50),
        ),
      );
    }
    return Container(color: Colors.grey[300]);
  }

  Widget _buildHeaderBar() {
    return Positioned(
      top: 40,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration:
            const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
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
                shadows: [
                  Shadow(blurRadius: 10, color: Colors.black45)
                ]),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildScrollableContent({
    required String nameFa,
    required String englishName,
    required String description,
    required String waterShort,
    required String lightShort,
    required String tempShort,
    required String difficulty,
    required String waterDetail,
    required String fertilizer,
    required String lightDetail,
  }) {
    return Positioned.fill(
      top: 220,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 100),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius:
          BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),

              Text(nameFa,
                  style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              Text(englishName,
                  style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey)),
              const SizedBox(height: 30),

              const Align(
                alignment: Alignment.centerRight,
                child: Text("مراقبت و شرایط نگهداری",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),

              _buildStatusCard("آبیاری مناسب", waterShort, Icons.water_drop_outlined),
              const SizedBox(height: 10),

              _buildStatusCard("نور مناسب", lightShort, Icons.wb_sunny_outlined),
              const SizedBox(height: 10),

              _buildStatusCard("دمای مناسب", tempShort, Icons.thermostat_outlined),
              const SizedBox(height: 20),

              const Divider(),

              _buildExpandableTile("سختی نگهداری", difficulty, Icons.equalizer, simple: true),
              _buildExpandableTile("توضیحات کلی", description, Icons.info_outline),
              _buildExpandableTile("نحوه آبیاری", waterDetail, Icons.water_drop),
              _buildExpandableTile("کود مناسب", fertilizer, Icons.spa_outlined),
              _buildExpandableTile("جزئیات نور", lightDetail, Icons.light_mode_outlined),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: ElevatedButton(
        onPressed: _isProcessing
            ? null
            : _isInGarden
            ? _removeFromGarden
            : _addToGarden,
        style: ElevatedButton.styleFrom(
          backgroundColor:
          _isInGarden ? Colors.red[400] : const Color(0xFF5D8F67),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isProcessing
            ? const SizedBox(
          height: 24,
          width: 24,
          child:
          CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_isInGarden ? Icons.delete_outline : Icons.add),
            const SizedBox(width: 8),
            Text(
              _isInGarden ? "حذف از باغچه من" : "افزودن به باغچه من",
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF5D8F67), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ]),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableTile(
      String title, String value, IconData icon,
      {bool simple = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration:
      BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(icon, color: const Color(0xFF5D8F67)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        trailing: simple
            ? Text(value,
            style: const TextStyle(
                color: Colors.grey, fontWeight: FontWeight.bold))
            : const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        children: simple
            ? []
            : [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              value,
              style: TextStyle(fontSize: 13, height: 1.6, color: Colors.grey[700]),
              textAlign: TextAlign.justify,
            ),
          )
        ],
      ),
    );
  }
}
