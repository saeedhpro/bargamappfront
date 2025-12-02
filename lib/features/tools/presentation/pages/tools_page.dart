import 'dart:async';
import 'dart:io' ;
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_image_compress/flutter_image_compress.dart';

// Web‑only imports
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

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
        title: const Text(
          'ابزارها',
          style: TextStyle(color: Color(0xFF2E3E5C), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined, color: Colors.grey),
            onPressed: () => showModalBottomSheet(
              context: context,
              builder: (_) => const SupportBottomSheet(),
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
      if (user?.subscription != null) {
        remainingLimit = user.subscription!.frozenDailyPlantIdLimit;
      }
    } catch (e) {
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
          final updatedUser = context.read<AuthProvider>().user;
          int newLimit = updatedUser?.subscription?.frozenDailyPlantIdLimit ?? 0;

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
                      content: Text('دوربین در نسخه دسکتاپ پشتیبانی نمی‌شود.'),
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
    debugPrint("===== PICK IMAGE =====");

    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 100);
      if (image == null) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      XFile? finalImage;

      if (kIsWeb) {
        Uint8List? compressed = await _compressImageWeb(image);
        if (compressed != null) {
          finalImage = XFile.fromData(
            compressed,
            mimeType: 'image/jpeg',
            name: 'plant_web.jpg',
          );
        }
      } else {
        File? compressed = await _compressImageMobile(File(image.path));
        if (compressed != null) {
          finalImage = XFile(compressed.path);
        }
      }

      Navigator.of(context, rootNavigator: true).pop();

      if (finalImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("خطا در پردازش تصویر")),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlantIdentificationPage(imageFile: finalImage!),
        ),
      );

    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      debugPrint("ERROR in _pickImage: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطا: $e")),
      );
    }
  }

  // ----------------------------------------------------
  // MOBILE COMPRESSION
  // ----------------------------------------------------
  Future<File?> _compressImageMobile(File file) async {
    const int targetSize = 500 * 1024;
    int quality = 95;

    final Directory tempDir = await getTemporaryDirectory();
    final String targetPath = p.join(
      tempDir.path,
      "plant_mobile_${DateTime.now().millisecondsSinceEpoch}.jpg",
    );

    try {
      File? output = (await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: quality,
        format: CompressFormat.jpeg,
      )) as File?;

      if (output == null) return file;

      int size = await output.length();

      while (size > targetSize && quality > 10) {
        quality -= 10;
        output = (await FlutterImageCompress.compressAndGetFile(
          output!.path,
          targetPath,
          quality: quality,
          format: CompressFormat.jpeg,
        )) as File?;

        if (output == null) break;
        size = await output.length();
      }

      return output ?? file;

    } catch (_) {
      return file;
    }
  }

  // ----------------------------------------------------
  // WEB COMPRESSION — Canvas‑Based (FINAL)
  // ----------------------------------------------------
  Future<Uint8List?> _compressImageWeb(XFile file) async {
    try {
      debugPrint("===== WEB COMPRESS START =====");

      final Uint8List inputBytes = await file.readAsBytes();

      final blob = html.Blob([inputBytes]);
      final reader = html.FileReader();

      reader.readAsDataUrl(blob);
      await reader.onLoad.first;

      final String dataUrl = reader.result as String;

      final img = html.ImageElement();
      final Completer<void> completer = Completer();

      img.src = dataUrl;

      img.onLoad.listen((_) => completer.complete());
      img.onError.listen((err) {
        debugPrint("❌ IMG LOAD ERROR → $err");
        if (!completer.isCompleted) completer.complete();
      });

      await completer.future;

      if (img.width == 0 || img.height == 0) {
        debugPrint("❌ INVALID WEB IMAGE");
        return inputBytes;
      }

      final canvas = html.CanvasElement(width: img.width, height: img.height);
      final ctx = canvas.context2D;

      ctx.drawImage(img, 0, 0);

      final String compressedDataUrl = canvas.toDataUrl("image/jpeg", 0.7);
      final String base64String = compressedDataUrl.split(",").last;

      final Uint8List result = base64Decode(base64String);

      debugPrint("===== WEB COMPRESS DONE (${(result.length / 1024).toStringAsFixed(2)} KB) =====");
      return result;

    } catch (e) {
      debugPrint("Web Canvas Error: $e");
      return null;
    }
  }
}
