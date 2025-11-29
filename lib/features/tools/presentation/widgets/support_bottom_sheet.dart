import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

class SupportBottomSheet extends StatelessWidget {
  const SupportBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)), // گردی بالای باتم‌شیت
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // ارتفاع بر اساس محتوا
        children: [
          // خط خاکستری کوچک بالای باتم‌شیت (Handle bar)
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // عنوان
          const Text(
            'ارتباط با پشتیبانی',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),

          // دکمه واتساپ
          _buildSupportButton(
            label: 'واتساپ',
            icon: Icons.chat_bubble_outline, // یا آیکون اختصاصی واتساپ
            color: const Color(0xFF58AA5C), // سبز مشابه عکس
            onTap: () {
              // منطق باز کردن واتساپ
              // _launchURL('https://wa.me/989123456789');
            },
          ),
          const SizedBox(height: 16),

          // دکمه تلگرام
          _buildSupportButton(
            label: 'تلگرام',
            icon: Icons.send_rounded, // یا آیکون اختصاصی تلگرام
            color: const Color(0xFF3B96E3), // آبی مشابه عکس
            onTap: () {
              // منطق باز کردن تلگرام
              // _launchURL('https://t.me/your_id');
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSupportButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

/*
  // تابع کمکی برای باز کردن لینک (نیاز به پکیج url_launcher دارد)
  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
  */
}
