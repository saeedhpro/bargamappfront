import 'dart:io';
import 'package:bargam_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/tool_provider.dart';
import '../widgets/tool_card.dart';
import '../widgets/subscription_bottom_sheet.dart';
import '../widgets/support_bottom_sheet.dart';
import 'plant_identification_page.dart';

class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final tools = context.read<ToolProvider>().tools;
    // فرض بر این است که UserProvider اطلاعات اشتراک کاربر را دارد
    // اگر جای دیگری است، آن را اینجا فراخوانی کنید
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('ابزارها', style: TextStyle(color: Color(0xFF2E3E5C), fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined, color: Colors.grey),
            onPressed: () => showModalBottomSheet(
                context: context,
                builder: (_) => const SupportBottomSheet()
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: tools.length,
        itemBuilder: (context, index) {
          final tool = tools[index];
          return ToolCard(
            tool: tool,
            onTap: () => _handleToolClick(context, tool, user),
          );
        },
      ),
    );
  }

  void _handleToolClick(BuildContext context, dynamic tool, dynamic user) {
    int remainingLimit = 0;

    try {
      if (user != null && user.subscription != null) {
        remainingLimit = user.subscription!.frozenDailyPlantIdLimit;
      }
    } catch (e) {
      print("Error reading subscription: $e");
      remainingLimit = 0;
    }

    bool hasAccess = remainingLimit > 0;


    if (tool.id == 'plant_id') {
      if (hasAccess) {
        // اگر لیمیت دارد، انتخاب دوربین/گالری
        _showImageSourceOptions(context);
      } else {
        // اگر لیمیت ندارد، پیشنهاد خرید اشتراک
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => const SubscriptionBottomSheet(),
        );
      }
    } else {
      // برای سایر ابزارها (مثل گیاه‌پزشک)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('این ابزار به زودی فعال می‌شود')),
      );
    }
  }

  void _showImageSourceOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF4CAF50)),
              title: const Text('دوربین'),
              onTap: () {
                Navigator.pop(ctx); // بستن شیت
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF4CAF50)),
              title: const Text('گالری'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 80);
      if (image != null) {
        // رفتن به صفحه چت و ارسال عکس
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlantIdentificationPage(imageFile: image),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }
}
