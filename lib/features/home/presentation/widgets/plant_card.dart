import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/plant.dart';
import '../pages/history_plant_details_page.dart';

class PlantCard extends StatelessWidget {
  final Plant plant;

  const PlantCard({
    super.key,
    required this.plant,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = (plant.commonName != null && plant.commonName!.isNotEmpty)
        ? plant.commonName!
        : plant.plantName;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        // -------------------------------------------
        // تغییر اصلی اینجاست: نویگیت به صفحه جدید
        // -------------------------------------------
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HistoryPlantDetailsPage(plant: plant),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            // ... بقیه کدهای طراحی کارت که قبلاً داشتید
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: plant.imagePath.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: plant.imagePath,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(width: 80, height: 80, color: Colors.grey.shade200),
                  errorWidget: (context, url, error) => _buildPlaceholderImage(),
                )
                    : _buildPlaceholderImage(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plant.plantName,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // ... بقیه اطلاعات
                  ],
                ),
              ),
              // ... آیکون‌ها
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 80,
      height: 80,
      color: const Color(0xFFE8F5E9),
      child: const Icon(Icons.eco, color: Color(0xFF4CAF50), size: 40),
    );
  }
}
