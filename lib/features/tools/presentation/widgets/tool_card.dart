import 'package:flutter/material.dart';
import '../../domain/entities/tool.dart';

class ToolCard extends StatelessWidget {
  final Tool tool;
  final VoidCallback onTap;

  const ToolCard({
    super.key,
    required this.tool,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPlantId = tool.iconName == 'eco';
    final colorTheme = isPlantId ? const Color(0xFF569D59) : const Color(0xFF2D8EFF);
    final iconData = _getIconData(tool.iconName);

    return Directionality(
      // اطمینان از اینکه کارت حتما راست‌چین رندر شود
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // در RTL یعنی سمت راست
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. سمت راست: آیکون و تیتر
                Row(
                  children: [
                    // آیکون (اولین آیتم از راست)
                    Icon(iconData, color: colorTheme, size: 32),
                    const SizedBox(width: 10),
                    // متن (دومین آیتم از راست)
                    Text(
                      tool.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),

                // 2. سمت چپ: بج (Badge)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: colorTheme.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'یک فرصت رایگان',
                    style: TextStyle(
                      color: colorTheme,
                      fontSize: 11, // فونت کمی ریزتر برای جا شدن
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // توضیحات
            Text(
              tool.description,
              textAlign: TextAlign.right, // متن راست‌چین
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                height: 1.6, // فاصله خطوط بهتر برای فارسی
              ),
            ),

            const SizedBox(height: 20),

            // دکمه
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorTheme,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'ورود به ${tool.title}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'eco':
        return Icons.image_search;
      case 'healing':
        return Icons.monitor_heart_outlined;
      default:
        return Icons.apps;
    }
  }
}
