import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/inventory_provider.dart';
import '../models/plant_model.dart';
import 'add_edit_plant_screen.dart';
import 'plant_detail_screen.dart';

class PlantListScreen extends StatefulWidget {
  const PlantListScreen({super.key});

  @override
  State<PlantListScreen> createState() => _PlantListScreenState();
}

class _PlantListScreenState extends State<PlantListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize provider when screen is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        Provider.of<InventoryProvider>(context, listen: false).init(authProvider.user!.uid);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
      ),
      builder: (context) {
        return Consumer<InventoryProvider>(
          builder: (context, provider, _) {
            Widget buildSortOption(String value, String title, IconData icon) {
              final isSelected = provider.sortBy == value;
              return ListTile(
                leading: Icon(icon, color: isSelected ? AppColors.primary : null),
                title: Text(
                  title,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : null,
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  provider.setSortBy(value);
                  Navigator.of(context).pop();
                },
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    child: Text('Sort Plants By', style: AppTextStyles.headingSmall(context)),
                  ),
                  const Divider(),
                  buildSortOption('nextWatering', 'Watering Urgency', Icons.water_drop_outlined),
                  buildSortOption('nameAsc', 'Name: A to Z', Icons.sort_by_alpha),
                  buildSortOption('nameDesc', 'Name: Z to A', Icons.sort_by_alpha),
                  buildSortOption('hydration', 'Hydration Level', Icons.opacity),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Garden'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.plants.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Search & Filter header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search plants...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    provider.setSearchQuery('');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                        onChanged: (val) {
                          provider.setSearchQuery(val);
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    IconButton(
                      icon: const Icon(Icons.sort),
                      onPressed: () => _showSortSheet(context),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Needs Water'),
                      selected: provider.filterNeedsWaterOnly,
                      onSelected: (val) => provider.setNeedsWaterOnly(val),
                      selectedColor: AppColors.primary.withAlpha(40),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: provider.filterNeedsWaterOnly
                            ? AppColors.primary
                            : (isDark ? AppColors.textDark : AppColors.textLight),
                        fontWeight: provider.filterNeedsWaterOnly ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    ...['All', 'Low', 'Medium', 'Bright Indirect', 'Direct'].map((sun) {
                      final isSelected = provider.selectedSunlightFilter.toLowerCase() == sun.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: AppDimensions.sm),
                        child: FilterChip(
                          label: Text('$sun Light'),
                          selected: isSelected,
                          onSelected: (val) => provider.setSunlightFilter(val ? sun : 'All'),
                          selectedColor: AppColors.primary.withAlpha(40),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primary : (isDark ? AppColors.textDark : AppColors.textLight),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Main plants list/grid
              Expanded(
                child: provider.plants.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.eco_outlined,
                              size: 70,
                              color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                            ),
                            const SizedBox(height: AppDimensions.md),
                            Text(
                              provider.allPlantsRaw.isEmpty
                                  ? 'Your garden is empty!'
                                  : 'No plants match filters.',
                              style: AppTextStyles.headingSmall(context),
                            ),
                            const SizedBox(height: AppDimensions.sm),
                            Text(
                              provider.allPlantsRaw.isEmpty
                                  ? 'Tap the button below to add your first plant.'
                                  : 'Try adjusting your search or filters.',
                              style: AppTextStyles.bodyMedium(context,
                                  color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(AppDimensions.md),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppDimensions.md,
                          mainAxisSpacing: AppDimensions.md,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: provider.plants.length,
                        itemBuilder: (context, index) {
                          final plant = provider.plants[index];
                          return _buildPlantCard(context, plant);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddEditPlantScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPlantCard(BuildContext context, Plant plant) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = plant.hydrationProgress;
    
    Color scheduleColor;
    String scheduleText;
    if (plant.daysUntilWatering < 0) {
      scheduleColor = AppColors.danger;
      scheduleText = 'Overdue ${-plant.daysUntilWatering}d';
    } else if (plant.daysUntilWatering == 0) {
      scheduleColor = AppColors.warning;
      scheduleText = 'Water Today';
    } else {
      scheduleColor = AppColors.success;
      scheduleText = 'Water in ${plant.daysUntilWatering}d';
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PlantDetailScreen(plantId: plant.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Plant image placeholder with plant type
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                      ? [AppColors.primaryDark, AppColors.cardDark] 
                      : [AppColors.secondary.withAlpha(80), AppColors.bgLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (plant.imageUrl != null && plant.imageUrl!.isNotEmpty)
                      Image.network(
                        plant.imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.danger,
                            size: 30,
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Icon(
                          Icons.local_florist,
                          size: 50,
                          color: AppColors.primary.withAlpha(160),
                        ),
                      ),
                    // Days left badge
                    Positioned(
                      top: AppDimensions.sm,
                      right: AppDimensions.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sm, vertical: AppDimensions.xs),
                        decoration: BoxDecoration(
                          color: scheduleColor.withAlpha(220),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                        ),
                        child: Text(
                          scheduleText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info content
            Padding(
              padding: const EdgeInsets.all(AppDimensions.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    plant.species,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  // Progress indicator of watering
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                            color: progress < 0.25 ? AppColors.danger : AppColors.primary,
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      // Quick water action
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.water_drop, size: 20),
                        color: AppColors.primary,
                        tooltip: 'Mark Watered',
                        onPressed: () {
                          Provider.of<InventoryProvider>(context, listen: false).waterPlant(plant);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Marked "${plant.name}" as watered!'),
                              backgroundColor: AppColors.success,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
