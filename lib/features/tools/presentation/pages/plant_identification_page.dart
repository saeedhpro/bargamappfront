import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// ایمپورت‌های پروژه شما
import 'package:bargam_app/core/error/exceptions.dart';
import 'package:bargam_app/features/auth/presentation/providers/auth_provider.dart';
import '../providers/tool_provider.dart';
import 'plant_details_page.dart';

class PlantIdentificationPage extends StatefulWidget {
  final XFile imageFile;

  const PlantIdentificationPage({super.key, required this.imageFile});

  @override
  State<PlantIdentificationPage> createState() => _PlantIdentificationPageState();
}

class _PlantIdentificationPageState extends State<PlantIdentificationPage> {
  String? _error;
  // ignore: unused_field
  bool _isThinking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processImage(widget.imageFile);
    });
  }

  Future<void> _processImage(XFile image) async {
    final toolProvider = Provider.of<ToolProvider>(context, listen: false);
    // ignore: unused_local_variable
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // درخواست به سرور ارسال می‌شود
      final result = await toolProvider.identifyPlant(image);

      // ---------------------------------------------------------
      // >>> چاپ پاسخ سرور در کنسول (اینجا اضافه شد) <<<
      // ---------------------------------------------------------
      debugPrint("=================================================");
      // debugPrint(">>> 📡 SERVER RESPONSE RECEIVED:");
      // debugPrint(">>> Type: ${result.runtimeType}");
      debugPrint(">>> Data: $result");
      // debugPrint("=================================================");
      // ---------------------------------------------------------

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PlantDetailsPage(
              data: result,
              userImageFile: widget.imageFile,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(">>> ❌ SERVER ERROR: $e"); // چاپ خطای احتمالی سرور

      if (!mounted) return;
      if (e is AuthException) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _error = e.toString();
          _isThinking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('شناسایی هوشمند')),
      body: Center(
        child: _error != null
            ? _buildErrorMessage(_error!)
            : _buildLoadingMessage(),
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // نمایش عکس کوچک
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 150, height: 150,
            child: kIsWeb
                ? Image.network(widget.imageFile.path, fit: BoxFit.cover)
                : Image.file(File(widget.imageFile.path), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 30),
        const CircularProgressIndicator(),
        const SizedBox(height: 20),
        Text("در حال تحلیل گیاه...", style: TextStyle(color: Colors.grey[700], fontSize: 16)),
      ],
    );
  }

  Widget _buildErrorMessage(String error) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 50),
          const SizedBox(height: 10),
          Text("خطا در شناسایی", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[800])),
          const SizedBox(height: 10),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("بازگشت"))
        ],
      ),
    );
  }
}
