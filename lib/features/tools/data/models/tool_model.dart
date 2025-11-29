import '../../domain/entities/tool.dart';

class ToolModel extends Tool {
  const ToolModel({
    required super.id,
    required super.title,
    required super.description,
    required super.iconName,
    super.isActive = true,
  });

  factory ToolModel.fromJson(Map<String, dynamic> json) {
    return ToolModel(
      id: json['id'].toString(),
      title: json['title'] as String,
      description: json['description'] as String,
      iconName: json['icon_name'] as String,
      // route حذف شد
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon_name': iconName,
      // route حذف شد
      'is_active': isActive,
    };
  }

  // لیست استاتیک به‌روزرسانی شده با دو ابزار اصلی پروژه
  static List<ToolModel> getStaticTools() {
    return [
      const ToolModel(
        id: '1',
        title: 'شناسایی گیاه',
        description: 'با گرفتن عکس از گیاه، نام و مشخصات آن را پیدا کنید.',
        iconName: 'eco',
        isActive: true,
      ),
      const ToolModel(
        id: '2',
        title: 'گیاه پزشک',
        description: 'تشخیص بیماری‌های گیاه و ارائه راهکار درمانی.',
        iconName: 'healing',
        isActive: true,
      ),
    ];
  }
}
