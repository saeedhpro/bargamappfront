import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/plant.dart';

class PlantCard extends StatelessWidget {
  final Plant plant;

  const PlantCard({
    super.key,
    required this.plant,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // Navigate to plant detail
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: plant.imageUrl != null
                    ? CachedNetworkImage(
                  imageUrl: plant.imageUrl!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 80,
                    color: const Color(0xFFE8F5E9),
                    child: const Icon(
                      Icons.eco,
                      color: Color(0xFF4CAF50),
                      size: 40,
                    ),
                  ),
                )
                    : Container(
                  width: 80,
                  height: 80,
                  color: const Color(0xFFE8F5E9),
                  child: const Icon(
                    Icons.eco,
                    color: Color(0xFF4CAF50),
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plant.scientificName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildIconInfo(
                          Icons.water_drop,
                          '${plant.wateringInterval} روز',
                        ),
                        const SizedBox(width: 16),
                        _buildIconInfo(
                          Icons.wb_sunny_outlined,
                          _getLightText(plant.lightRequirement),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      plant.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: plant.isFavorite ? Colors.red : Colors.grey,
                    ),
                    onPressed: () {
                      // Toggle favorite
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.alarm, color: Color(0xFF4CAF50)),
                    onPressed: () {
                      // Set reminder
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF4CAF50)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  String _getLightText(String lightRequirement) {
    switch (lightRequirement.toLowerCase()) {
      case 'high':
        return 'نور زیاد';
      case 'medium':
        return 'نور متوسط';
      case 'low':
        return 'نور کم';
      default:
        return lightRequirement;
    }
  }
}
