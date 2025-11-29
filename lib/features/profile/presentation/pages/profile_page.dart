import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('دستیار من'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final phoneNumber = authProvider.user?.phoneNumber ?? 'کاربر';

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFFE8F5E9),
                        child: const Icon(
                          Icons.person,
                          size: 50,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        phoneNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'کاربر رایگان',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildMenuSection(
                  context,
                  title: 'اشتراک و پرداخت',
                  items: [
                    _MenuItem(
                      icon: Icons.card_membership,
                      title: 'خرید اشتراک',
                      subtitle: 'دسترسی به امکانات ویژه',
                      onTap: () => _showComingSoon(context),
                    ),
                    _MenuItem(
                      icon: Icons.history,
                      title: 'تاریخچه پرداخت‌ها',
                      onTap: () => _showComingSoon(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildMenuSection(
                  context,
                  title: 'تنظیمات',
                  items: [
                    _MenuItem(
                      icon: Icons.notifications,
                      title: 'اعلان‌ها',
                      onTap: () => _showComingSoon(context),
                    ),
                    _MenuItem(
                      icon: Icons.dark_mode,
                      title: 'تم تیره',
                      trailing: Switch(
                        value: false,
                        onChanged: (value) {},
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.language,
                      title: 'زبان',
                      subtitle: 'فارسی',
                      onTap: () => _showComingSoon(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildMenuSection(
                  context,
                  title: 'راهنما و پشتیبانی',
                  items: [
                    _MenuItem(
                      icon: Icons.help_outline,
                      title: 'راهنما',
                      onTap: () => _showComingSoon(context),
                    ),
                    _MenuItem(
                      icon: Icons.support_agent,
                      title: 'پشتیبانی',
                      onTap: () => _showComingSoon(context),
                    ),
                    _MenuItem(
                      icon: Icons.info_outline,
                      title: 'درباره ما',
                      onTap: () => _showAboutDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    onPressed: () => _logout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('خروج از حساب کاربری'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuSection(
      BuildContext context, {
        required String title,
        required List<_MenuItem> items,
      }) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ...items.map((item) => _buildMenuItem(context, item)),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, _MenuItem item) {
    return ListTile(
      leading: Icon(item.icon, color: const Color(0xFF4CAF50)),
      title: Text(item.title),
      subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
      trailing: item.trailing ?? const Icon(Icons.chevron_right),
      onTap: item.onTap,
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('این قابلیت به زودی اضافه خواهد شد')),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('درباره برگام'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('نسخه: 1.0.0'),
            SizedBox(height: 8),
            Text(
              'برگام یک اپلیکیشن کامل برای مدیریت و مراقبت از گیاهان است.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خروج از حساب'),
        content: const Text('آیا مطمئن هستید که می‌خواهید خارج شوید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pop(context);
            },
            child: const Text('خروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
}
