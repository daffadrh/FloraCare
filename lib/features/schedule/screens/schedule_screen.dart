import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import 'schedule_settings_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.uid;
      if (userId != null) {
        context.read<ScheduleProvider>().loadConfigs(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = context.watch<InventoryProvider>();
    final scheduleProvider = context.watch<ScheduleProvider>();
    final plants = inventoryProvider.plants;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Care Schedule'),
      ),
      body: inventoryProvider.isLoading || scheduleProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : plants.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco_outlined,
              size: 80,
              color: theme.colorScheme.primary.withAlpha(150),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                "You can't add schedules when you don't have any plants.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withAlpha(180),
                ),
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: plants.length,
        itemBuilder: (context, index) {
          final plant = plants[index];
          final plantId = (plant as dynamic).id;
          final String plantName = (plant as dynamic).name ?? 'Unknown Plant';
          final String plantSpecies = (plant as dynamic).species ?? 'Unknown Species';

          final config = scheduleProvider.getConfigForPlant(plantId);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScheduleSettingsScreen(plant: plant),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.local_florist, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plantName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            plantSpecies,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface.withAlpha(150),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Watering (Mandatory)
                          _buildProgressBar(
                            icon: Icons.water_drop,
                            color: Colors.blue[400]!,
                            value: 0.5, // Placeholder ratio
                            theme: theme,
                          ),

                          // Fertilizing
                          if (config?.isFertilizingEnabled ?? false) ...[
                            const SizedBox(height: 8),
                            _buildProgressBar(
                              icon: Icons.science,
                              color: Colors.purple[400]!,
                              value: 0.7,
                              theme: theme,
                            ),
                          ],

                          // Repotting
                          if (config?.isRepottingEnabled ?? false) ...[
                            const SizedBox(height: 8),
                            _buildProgressBar(
                              icon: Icons.yard,
                              color: Colors.brown[400]!,
                              value: 0.3,
                              theme: theme,
                            ),
                          ],

                          // Rotating
                          if (config?.isRotatingEnabled ?? false) ...[
                            const SizedBox(height: 8),
                            _buildProgressBar(
                              icon: Icons.rotate_right,
                              color: Colors.amber[400]!,
                              value: 0.8,
                              theme: theme,
                            ),
                          ],

                          // Pesticide
                          if (config?.isPesticideEnabled ?? false) ...[
                            const SizedBox(height: 8),
                            _buildProgressBar(
                              icon: Icons.bug_report,
                              color: Colors.red[400]!,
                              value: 0.2,
                              theme: theme,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Align(
                      alignment: Alignment.center,
                      child: Icon(Icons.chevron_right, color: theme.dividerColor),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressBar({
    required IconData icon,
    required Color color,
    required double value,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: theme.dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}