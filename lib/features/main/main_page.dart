import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

import '../home/presentation/pages/home_page.dart';
import '../tools/presentation/pages/tools_page.dart';
import '../garden/presentation/pages/garden_page.dart';
import '../profile/presentation/pages/profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final _picker = ImagePicker();
  XFile? _selectedImage;

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
        onPressed: _showCameraOptions,
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

  // CAMERA OR GALLERY BOTTOM SHEET
  void _showCameraOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF4CAF50)),
              title: const Text('دوربین'),
              onTap: () async {
                Navigator.pop(context);
                await _pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF4CAF50)),
              title: const Text('گالری'),
              onTap: () async {
                Navigator.pop(context);
                await _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  // PICK IMAGE FROM CAMERA
  Future<void> _pickFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() => _selectedImage = image);
      _previewImage(image);
    }
  }

  // PICK IMAGE FROM GALLERY
  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _selectedImage = image);
      _previewImage(image);
    }
  }

  // SHOW PREVIEW DIALOG
  void _previewImage(XFile file) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("عکس انتخاب‌شده"),
          content: Image.network(file.path), // For web support
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("باشه"),
            )
          ],
        );
      },
    );
  }
}
