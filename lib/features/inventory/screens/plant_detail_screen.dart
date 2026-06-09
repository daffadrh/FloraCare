import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/constants.dart';
import '../providers/inventory_provider.dart';
import '../models/plant_model.dart';
import 'add_edit_plant_screen.dart';

class PlantDetailScreen extends StatelessWidget {
  final String plantId;

  const PlantDetailScreen({super.key, required this.plantId});

  void _confirmDelete(BuildContext context, InventoryProvider provider, Plant plant) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Plant'),
          content: Text('Are you sure you want to remove "${plant.name}" from your garden?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                navigator.pop(); // pop dialog
                navigator.pop(); // pop detail screen back to inventory
                await provider.deletePlant(plant.id);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('"${plant.name}" deleted successfully.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Details'),
        actions: [
          Consumer<InventoryProvider>(
            builder: (context, provider, _) {
              final plant = provider.plants.firstWhere((p) => p.id == plantId);
              return IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Plant',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AddEditPlantScreen(plant: plant),
                    ),
                  );
                },
              );
            },
          ),
          Consumer<InventoryProvider>(
            builder: (context, provider, _) {
              final plant = provider.plants.firstWhere((p) => p.id == plantId);
              return IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete Plant',
                onPressed: () => _confirmDelete(context, provider, plant),
              );
            },
          ),
        ],
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          // In case plant was deleted
          final plantIndex = provider.plants.indexWhere((p) => p.id == plantId);
          if (plantIndex == -1) {
            return const Center(child: Text('Plant not found or has been deleted.'));
          }

          final plant = provider.plants[plantIndex];
          final dateFormat = DateFormat('MMMM dd, yyyy');
          final hydration = plant.hydrationProgress;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner / Card Graphic representation
                Container(
                  height: 200,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  ),
                  child: plant.imageUrl != null && plant.imageUrl!.isNotEmpty
                      ? Image.network(
                          plant.imageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.local_florist,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(height: AppDimensions.lg),

                // Name & Species
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plant.name,
                            style: AppTextStyles.headingLarge(context),
                          ),
                          const SizedBox(height: AppDimensions.xs),
                          Text(
                            plant.species,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Quick Action Button
                    ElevatedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await provider.waterPlant(plant);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('${plant.name} marked as watered!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      icon: const Icon(Icons.water_drop),
                      label: const Text('Water'),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.lg),

                // Care Stats Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Care Status', style: AppTextStyles.headingSmall(context)),
                        const SizedBox(height: AppDimensions.md),
                        
                        // Hydration level
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Hydration Level'),
                            Text('${(hydration * 100).toInt()}%'),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: hydration,
                            backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                            color: hydration < 0.25 ? AppColors.danger : AppColors.primary,
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.lg),

                        // Watering details list
                        _buildDetailRow(
                          context,
                          label: 'Last Watered',
                          value: dateFormat.format(plant.lastWatered),
                          icon: Icons.calendar_today,
                        ),
                        const Divider(),
                        _buildDetailRow(
                          context,
                          label: 'Watering Frequency',
                          value: 'Every ${plant.wateringFrequencyDays} days',
                          icon: Icons.repeat,
                        ),
                        const Divider(),
                        _buildDetailRow(
                          context,
                          label: 'Next Watering Due',
                          value: dateFormat.format(plant.nextWateringDate),
                          icon: Icons.water_drop_outlined,
                          valueColor: plant.needsWatering ? AppColors.danger : AppColors.success,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.md),

                // Environmental Requirements
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Requirements & Schedules', style: AppTextStyles.headingSmall(context)),
                        const SizedBox(height: AppDimensions.md),
                        _buildDetailRow(
                          context,
                          label: 'Sunlight Need',
                          value: plant.sunlightRequirement,
                          icon: Icons.wb_sunny_outlined,
                        ),
                        if (plant.fertilizingFrequencyDays != null) ...[
                          const Divider(),
                          _buildDetailRow(
                            context,
                            label: 'Fertilizing Schedule',
                            value: 'Every ${plant.fertilizingFrequencyDays} days',
                            icon: Icons.grass,
                          ),
                        ],
                        if (plant.lastFertilized != null) ...[
                          const Divider(),
                          _buildDetailRow(
                            context,
                            label: 'Last Fertilized',
                            value: dateFormat.format(plant.lastFertilized!),
                            icon: Icons.calendar_month,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.md),

                // Notes Card
                if (plant.notes.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.sticky_note_2_outlined, color: AppColors.primary),
                              const SizedBox(width: AppDimensions.sm),
                              Text('Gardener\'s Notes', style: AppTextStyles.headingSmall(context)),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.sm),
                          Text(
                            plant.notes,
                            style: AppTextStyles.bodyMedium(context),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppDimensions.md),
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
