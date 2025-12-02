import 'dart:io';
import 'dart:typed_data'; // برای کار با بایت‌ها در وب
import 'package:flutter/foundation.dart'; // برای kIsWeb
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:bargam_app/features/auth/presentation/providers/auth_provider.dart';
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
          final authProvider = context.read<AuthProvider>();
          final tool = tools[index];
          return ToolCard(
            tool: tool,
            onTap: () => _handleToolClick(context, tool, user),
            remainingLimit: authProvider.user?.subscription?.frozenDailyPlantIdLimit ?? 0,
          );
        },
      ),
    );
  }

  Future<void> _handleToolClick(BuildContext context, dynamic tool, dynamic user) async {
    int remainingLimit = 0;

    try {
      if (user != null && user.subscription != null) {
        remainingLimit = user.subscription!.frozenDailyPlantIdLimit;
      }
    } catch (e) {
      debugPrint("Error reading subscription: $e");
      remainingLimit = 0;
    }

    bool hasAccess = remainingLimit > 0;

    if (tool.id == 'plant_id') {
      if (!hasAccess) {
        final result = await showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => const SubscriptionBottomSheet(),
        );

        if (result == true) {
          if (!mounted) return;
          final updatedUser = context.read<AuthProvider>().user;

          int newLimit = 0;
          try {
            if (updatedUser != null && updatedUser.subscription != null) {
              newLimit = updatedUser.subscription!.frozenDailyPlantIdLimit;
            }
          } catch (e) {
            debugPrint("Error reading updated subscription: $e");
          }

          if (newLimit > 0) {
            _showImageSourceOptions(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('لطفاً ابتدا اشتراک خریداری کنید')),
            );
          }
        }
      } else {
        _showImageSourceOptions(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('این ابزار به زودی فعال می‌شود')),
      );
    }
  }

  void _showImageSourceOptions(BuildContext context) {
    // منطق تشخیص دسکتاپ برای جلوگیری از کرش دوربین
    bool isDesktop = !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

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
                Navigator.pop(ctx);
                if (isDesktop) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('دوربین در نسخه دسکتاپ پشتیبانی نمی‌شود. گالری باز می‌شود.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  _pickImage(ImageSource.gallery);
                } else {
                  _pickImage(ImageSource.camera);
                }
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
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 100);

      if (image != null) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => const Center(child: CircularProgressIndicator()),
        );

        XFile? finalImage;

        if (kIsWeb) {
          // ---- منطق وب ----
          final compressedBytes = await _compressImageWeb(image);
          if (compressedBytes != null) {
            finalImage = XFile.fromData(
                compressedBytes,
                mimeType: 'image/jpeg',
                name: 'compressed_plant.jpg'
            );
          }
        } else {
          // ---- منطق موبایل و دسکتاپ ----
          final File? compressedFile = await _compressImageMobile(File(image.path));
          if (compressedFile != null) {
            finalImage = XFile(compressedFile.path);
          }
        }

        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop(); // بستن لودینگ

        if (finalImage != null) {
          debugPrint(">>> ✅ Final Image Ready in ToolsPage: ${finalImage.path}");
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlantIdentificationPage(imageFile: finalImage!),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خطا در پردازش و فشرده‌سازی تصویر')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking/compressing image: $e');
      if(mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // اطمینان از بسته شدن لودینگ در صورت خطا
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // تابع اصلاح شده فشرده‌سازی موبایل (دقیقاً مثل MainPage)
  // ---------------------------------------------------------------------------
  Future<File?> _compressImageMobile(File file) async {
    const int targetSize = 500 * 1024; // 500 KB
    int quality = 95;

    // 1. چاپ حجم اولیه
    int originalLength = await file.length();
    debugPrint("=================================================================");
    debugPrint(">>> 📸 START (ToolsPage): Processing Image");
    debugPrint(">>> 📂 Original Path: ${file.path}");
    debugPrint(">>> 📦 Original Size: ${(originalLength / 1024).toStringAsFixed(2)} KB");

    final Directory tempDir = await getTemporaryDirectory();
    final String targetPath = p.join(tempDir.path, "tools_converted_${DateTime.now().millisecondsSinceEpoch}.jpg");

    try {
      // تبدیل اولیه به JPEG
      var resultXFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (resultXFile == null) {
        debugPrint(">>> ❌ Conversion failed, returning original.");
        return file;
      }

      File compressedFile = File(resultXFile.path);
      int currentSize = await compressedFile.length();
      debugPrint(">>> 🔄 Converted to JPEG (Quality $quality). Size: ${(currentSize / 1024).toStringAsFixed(2)} KB");

      // حلقه کاهش حجم
      while (currentSize > targetSize && quality > 10) {
        quality -= 15;
        debugPrint(">>> ⚠️ Still too big (> 500KB). Reducing quality to $quality...");

        final String newTargetPath = p.join(tempDir.path, "tools_converted_${DateTime.now().millisecondsSinceEpoch}_$quality.jpg");

        final newResult = await FlutterImageCompress.compressAndGetFile(
          compressedFile.absolute.path,
          newTargetPath,
          quality: quality,
          format: CompressFormat.jpeg,
        );

        if (newResult != null) {
          // پاک کردن فایل موقت قبلی
          try { await compressedFile.delete(); } catch (_) {}

          compressedFile = File(newResult.path);
          currentSize = await compressedFile.length();
          debugPrint(">>> 📉 New Size: ${(currentSize / 1024).toStringAsFixed(2)} KB");
        }
      }

      debugPrint(">>> ✅ FINAL RESULT (ToolsPage):");
      debugPrint(">>> 📉 Final Size: ${(currentSize / 1024).toStringAsFixed(2)} KB");
      debugPrint(">>> ✂️ Total Saved: ${((originalLength - currentSize) / 1024).toStringAsFixed(2)} KB");
      debugPrint("=================================================================");

      return compressedFile;

    } catch (e) {
      debugPrint(">>> ❌ Error during compression: $e");
      return file;
    }
  }

  // ---------------------------------------------------------------------------
  // تابع فشرده‌سازی وب
  // ---------------------------------------------------------------------------
  Future<Uint8List?> _compressImageWeb(XFile file) async {
    const int targetSize = 500 * 1024;
    int quality = 90;

    try {
      Uint8List originalBytes = await file.readAsBytes();
      int originalSize = originalBytes.lengthInBytes;

      debugPrint("================ WEB COMPRESSION (ToolsPage) ================");
      debugPrint(">>> 📦 Original Web Size: ${(originalSize / 1024).toStringAsFixed(2)} KB");

      Uint8List? result = await FlutterImageCompress.compressWithList(
        originalBytes,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      int currentSize = result.lengthInBytes;
      debugPrint(">>> 🔄 Initial Compress Size: ${(currentSize / 1024).toStringAsFixed(2)} KB");

      while (result != null && currentSize > targetSize && quality > 10) {
        quality -= 15;
        debugPrint(">>> 📉 Reducing quality to $quality...");
        result = await FlutterImageCompress.compressWithList(
          originalBytes,
          quality: quality,
          format: CompressFormat.jpeg,
        );
        currentSize = result.lengthInBytes;
      }

      debugPrint(">>> ✅ Final Web Size: ${(currentSize / 1024).toStringAsFixed(2)} KB");
      debugPrint("=================================================");
      return result;
    } catch (e) {
      debugPrint("Web Compression Error: $e");
      return null;
    }
  }
}
