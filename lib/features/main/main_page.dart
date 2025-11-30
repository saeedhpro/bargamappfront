import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

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
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        height: 70,
      ),
    );
  }

  // ===== هندل کلیک روی دکمه دوربین =====
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
      // اگر لیمیت دارد، نمایش انتخاب دوربین/گالری
      _showImageSourceOptions();
    } else {
      // اگر لیمیت ندارد، نمایش پنجره خرید اشتراک
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => const SubscriptionBottomSheet(),
      );
    }
  }

  // ===== نمایش BottomSheet انتخاب دوربین یا گالری =====
  void _showImageSourceOptions() {
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
                _pickImage(ImageSource.camera);
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

  // ===== انتخاب عکس و رفتن به صفحه شناسایی =====
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image != null) {
        if (!mounted) return;

        // رفتن به صفحه لودینگ و شناسایی
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlantIdentificationPage(imageFile: image),
          ),
        );
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
}
