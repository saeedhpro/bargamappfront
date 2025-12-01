import 'package:flutter/material.dart';
import '../../domain/entities/tool.dart';

class ToolCard extends StatelessWidget {
  final Tool tool;
  final VoidCallback onTap;
  final int remainingLimit; // ✅ اضافه شد

  const ToolCard({
    super.key,
    required this.tool,
    required this.onTap,
    required this.remainingLimit, // ✅ اضافه شد
  });

  @override
  Widget build(BuildContext context) {
    final isPlantId = tool.iconName == 'eco';
    final colorTheme = isPlantId ? const Color(0xFF569D59) : const Color(0xFF2D8EFF);
    final iconData = _getIconData(tool.iconName);

    return Directionality(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(iconData, color: colorTheme, size: 32),
                    const SizedBox(width: 10),
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

                // ✅ نمایش تعداد فرصت باقی‌مانده
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: remainingLimit > 0
                          ? colorTheme.withOpacity(0.5)
                          : Colors.red.withOpacity(0.5),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    remainingLimit > 0
                        ? '$remainingLimit فرصت باقی‌مانده'
                        : 'بدون فرصت',
                    style: TextStyle(
                      color: remainingLimit > 0 ? colorTheme : Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            Text(
              tool.description,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 20),

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
