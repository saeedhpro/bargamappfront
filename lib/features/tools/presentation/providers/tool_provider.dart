import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/tool.dart';
import '../../../../core/network/http_client.dart';
// import 'dart:io'; // حذف شد: این ایمپورت در وب باعث ارور می‌شود

class ToolProvider extends ChangeNotifier {
  final HttpClient httpClient;

  ToolProvider({required this.httpClient});

  final List<Tool> _tools = [
    const Tool(
      id: 'plant_id',
      title: 'شناسایی گیاه',
      description: 'با گرفتن عکس از گیاه، نام و مشخصات آن را پیدا کنید.',
      iconName: 'eco',
      isActive: true,
    ),
    const Tool(
      id: 'disease_id',
      title: 'گیاه پزشک',
      description: 'تشخیص بیماری‌های گیاه و ارائه راهکار درمانی.',
      iconName: 'healing',
      isActive: true,
    ),
  ];

  List<Tool> get tools => _tools;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // متد اصلی شناسایی
  Future<Map<String, dynamic>> identifyPlant(XFile imageFile) async {
    _setLoading(true);
    try {
      // نکته مهم ۱: خط زیر حذف شد چون در وب کار نمی‌کند و نیازی هم نیست
      // final file = File(imageFile.path);

      // ارسال به بک‌اند
      final response = await httpClient.uploadPhoto(
        '/tools/identify-plant',
        file: imageFile, // نکته مهم ۲: ارسال مستقیم XFile
        fieldName: 'images', // نکته مهم ۳: تغییر نام به 'images' طبق فایل main.py
      );

      _setLoading(false);
      return response as Map<String, dynamic>;

    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }
  Future<void> addToGarden(int historyId, {String? nickname}) async {
    try {
      await httpClient.post(
        '/garden/add',
        body: {
          'history_id': historyId,
          'nickname': nickname,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeFromGarden(int historyId) async {
    try {
      // فراخوانی اندپوینت جدیدی که در پایتون ساختیم
      await httpClient.delete(
        '/garden/history/$historyId',
      );
    } catch (e) {
      rethrow;
    }
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadTools() async {
    notifyListeners();
  }
}
