import 'dart:io';
import 'dart:typed_data';
import 'package:bargam_app/features/garden/presentation/providers/garden_provider.dart';
import 'package:bargam_app/features/home/presentation/providers/plant_provider.dart';
import 'package:flutter/foundation.dart'; // برای kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../home/presentation/pages/home_page.dart';
import '../tools/presentation/pages/tools_page.dart';
import '../tools/presentation/pages/plant_identification_page.dart';
import '../tools/presentation/providers/tool_provider.dart';
import '../garden/presentation/pages/garden_page.dart';
import '../profile/presentation/pages/profile_page.dart';
import '../auth/presentation/providers/auth_provider.dart';
import '../tools/presentation/widgets/subscription_bottom_sheet.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final ImagePicker _picker = ImagePicker();

  final _pages = const [
    HomePage(),
    GardenPage(),
    ToolsPage(),
    ProfilePage(),
  ];

  final _icons = const [
    Icons.home_outlined,
    Icons.local_florist_outlined,
    Icons.build_outlined,
    Icons.person_outline,
  ];

  final _labels = const [
    'خانه',
    'باغچه',
    'ابزارها',
    'دستیار من',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'camera_selector_button',
        onPressed: _onCameraButtonPressed,
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.photo_camera, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar.builder(
        itemCount: _icons.length,
        tabBuilder: (int index, bool isActive) {
          final color = isActive ? const Color(0xFF4CAF50) : Colors.grey;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_icons[index], color: color, size: isActive ? 28 : 24),
              const SizedBox(height: 4),
              Text(
                _labels[index],
                style: TextStyle(
                  color: color,
                  fontSize: isActive ? 13 : 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              )
            ],
          );
        },
        activeIndex: _currentIndex,
        gapLocation: GapLocation.center,
        notchSmoothness: NotchSmoothness.smoothEdge,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            context.read<PlantProvider>().loadPlants(refresh: true);
          }
          if (index == 1) {
            context.read<GardenProvider>().fetchPlants();
          }
        },

        backgroundColor: Colors.white,
        height: 70,
      ),
    );
  }

  void _onCameraButtonPressed() {
    final user = context.read<AuthProvider>().user;
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

    if (hasAccess) {
      _showImageSourceOptions();
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => const SubscriptionBottomSheet(),
      );
    }
  }

  void _showImageSourceOptions() {
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
        Navigator.of(context, rootNavigator: true).pop();

        if (finalImage != null) {
          debugPrint(">>> ✅ Final Image Ready: ${finalImage.path}");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlantIdentificationPage(imageFile: finalImage!),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خطا در پردازش تصویر')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در انتخاب عکس: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // تابع اصلاح شده فشرده‌سازی موبایل (رفع مشکل WebP)
  // ---------------------------------------------------------------------------
  Future<File?> _compressImageMobile(File file) async {
    const int targetSize = 500 * 1024; // 500 KB
    int quality = 50; // شروع با کیفیت بالاتر
    int originalLength = await file.length();
    debugPrint("=================================================================");
    debugPrint(">>> 📸 START: Processing Image");
    debugPrint(">>> 📂 Original Path: ${file.path}");
    debugPrint(">>> 📦 Original Size: ${(originalLength / 1024).toStringAsFixed(2)} KB");

    // گرفتن مسیر تمپ
    final Directory tempDir = await getTemporaryDirectory();
    // مهم: حتما پسوند فایل خروجی jpg باشد
    final String targetPath = p.join(tempDir.path, "converted_${DateTime.now().millisecondsSinceEpoch}.jpg");

    debugPrint(">>> 🔄 Converting/Compressing: ${file.path} -> $targetPath");

    try {
      // نکته کلیدی: اگر فایل ورودی webp باشد، گاهی اوقات compressAndGetFile
      // مستقیم کپی می‌کند اگر فرمت صریح نباشد. ما اینجا صریحاً jpeg می‌خواهیم.

      var resultXFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        format: CompressFormat.jpeg, // اجبار به JPEG
      );

      if (resultXFile == null) {
        // اگر null شد (گاهی در برخی دستگاه‌ها پیش می‌آید)، یک تلاش دیگر با روش متفاوت
        debugPrint(">>> First attempt failed, trying fallback...");
        return file;
      }

      File compressedFile = File(resultXFile.path);
      debugPrint(">>> 📦 Initial Size: ${(compressedFile.lengthSync() / 1024).toStringAsFixed(2)} KB");
      int currentSize = await compressedFile.length();
      debugPrint(">>> 🔄 Converted to JPEG (Quality $quality). Size: ${(currentSize / 1024).toStringAsFixed(2)} KB");


      // حلقه کاهش حجم
      while (compressedFile.lengthSync() > targetSize && quality > 10) {
        quality -= 10;
        debugPrint(">>> 📉 Re-compressing (Q: $quality)...");

        // برای دورهای بعدی، فایل قبلی (که الان jpg است) را دوباره فشرده می‌کنیم
        // تا روی همان فایل بازنویسی نشود، یک اسم جدید موقت می‌سازیم یا روی همان targetPath بازنویسی می‌کنیم
        // نکته: برخی ورژن‌ها بازنویسی روی همان فایل را دوست ندارند، پس اسم جدید می‌سازیم
        final String newTargetPath = p.join(tempDir.path, "converted_${DateTime.now().millisecondsSinceEpoch}_$quality.jpg");

        final newResult = await FlutterImageCompress.compressAndGetFile(
          compressedFile.absolute.path, // ورودی: فایل jpg مرحله قبل
          newTargetPath,
          quality: quality,
          format: CompressFormat.jpeg,
        );

        if (newResult != null) {
          // فایل قبلی را پاک کن تا فضا اشغال نکند
          try { await compressedFile.delete(); } catch (_) {}
          compressedFile = File(newResult.path);
        }
      }

      debugPrint(">>> ✅ FINAL RESULT:");
      debugPrint(">>> 📉 Final Size: ${(currentSize / 1024).toStringAsFixed(2)} KB");
      debugPrint(">>> ✂️ Total Saved: ${((originalLength - currentSize) / 1024).toStringAsFixed(2)} KB");
      debugPrint("=================================================================");

      return compressedFile;

    } catch (e) {
      debugPrint(">>> ❌ Compression Error: $e");
      return file; // در بدترین حالت فایل اصلی برمی‌گردد
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

      debugPrint("================ WEB COMPRESSION ================");
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
          originalBytes, // همیشه از فایل اصلی کم می‌کنیم تا کیفیت داغون نشود
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
