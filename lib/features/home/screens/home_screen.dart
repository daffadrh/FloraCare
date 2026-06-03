import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/constants.dart';
import '../../../core/services/weather_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../../inventory/models/plant_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherService _weatherService = WeatherService();
  
  String _city = 'Jakarta';
  WeatherData? _weatherData;
  bool _weatherLoading = true;
  String? _weatherError;

  @override
  void initState() {
    super.initState();
    _loadSavedCity();
    // Initialize provider data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        Provider.of<InventoryProvider>(context, listen: false).init(authProvider.user!.uid);
      }
    });
  }

  // Load saved city location or default
  Future<void> _loadSavedCity() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _city = prefs.getString('user_city') ?? 'Jakarta';
    });
    _fetchWeather();
  }

  // Fetch current weather data from OpenWeather API
  Future<void> _fetchWeather() async {
    if (!mounted) return;
    setState(() {
      _weatherLoading = true;
      _weatherError = null;
    });

    try {
      final data = await _weatherService.fetchWeather(_city);
      if (mounted) {
        setState(() {
          _weatherData = data;
          _weatherLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final errorStr = e.toString();
          if (errorStr.contains('API_KEY_MISSING')) {
            _weatherError = 'API_KEY_MISSING';
          } else if (errorStr.contains('API_KEY_INVALID')) {
            _weatherError = 'API_KEY_INVALID';
          } else if (errorStr.contains('CITY_NOT_FOUND')) {
            _weatherError = 'CITY_NOT_FOUND';
          } else {
            _weatherError = errorStr.replaceAll('Exception: ', '');
          }
          _weatherLoading = false;
        });
      }
    }
  }

  // Open dialog to update user location city
  void _changeCityDialog() {
    final controller = TextEditingController(text: _city);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Weather Location'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter city name (e.g. Jakarta, London)',
              labelText: 'City Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newCity = controller.text.trim();
                if (newCity.isNotEmpty) {
                  final navigator = Navigator.of(context);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('user_city', newCity);
                  if (mounted) {
                    setState(() {
                      _city = newCity;
                    });
                    navigator.pop();
                    _fetchWeather();
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Calculate pending task counts based on plant states
  int _getPendingTasksCount(List<Plant> plants) {
    int count = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final p in plants) {
      if (p.needsWatering) count++;
      if (p.fertilizingFrequencyDays != null && p.lastFertilized != null) {
        final nextFertilize = p.lastFertilized!.add(Duration(days: p.fertilizingFrequencyDays!));
        final nextFertilizeDay = DateTime(nextFertilize.year, nextFertilize.month, nextFertilize.day);
        if (nextFertilizeDay.difference(today).inDays <= 0) {
          count++;
        }
      }
    }
    return count;
  }

  // Calculate overall garden health rating based on hydration levels
  String _calculateGardenHealth(List<Plant> plants) {
    if (plants.isEmpty) return 'No Plants';
    int healthyCount = 0;
    for (final p in plants) {
      if (p.hydrationProgress > 0.3) healthyCount++;
    }
    final ratio = healthyCount / plants.length;
    if (ratio >= 0.8) return 'Excellent';
    if (ratio >= 0.5) return 'Good';
    return 'Needs Attention';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, Gardener! 👋',
                        style: AppTextStyles.headingMedium(context),
                      ),
                      const SizedBox(height: AppDimensions.xs),
                      Text(
                        'How are your green friends doing today?',
                        style: AppTextStyles.bodyMedium(context, 
                          color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted
                        ),
                      ),
                    ],
                  ),
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.lg),

              // Weather Card (Connected to OpenWeather API)
              _buildWeatherCard(isDark),
              const SizedBox(height: AppDimensions.lg),

              // Live Statistics (Connected to InventoryProvider)
              Text(
                'Today\'s Summary',
                style: AppTextStyles.headingSmall(context),
              ),
              const SizedBox(height: AppDimensions.md),
              Consumer<InventoryProvider>(
                builder: (context, inventoryProvider, _) {
                  final plants = inventoryProvider.allPlantsRaw;
                  final totalPlants = plants.length;
                  final needsWater = plants.where((p) => p.needsWatering).length;
                  final pendingTasks = _getPendingTasksCount(plants);
                  final gardenHealth = _calculateGardenHealth(plants);

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: AppDimensions.md,
                    mainAxisSpacing: AppDimensions.md,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard(
                        context,
                        title: 'Total Plants',
                        value: '$totalPlants',
                        icon: Icons.local_florist,
                        color: AppColors.primary,
                      ),
                      _buildStatCard(
                        context,
                        title: 'Needs Water',
                        value: '$needsWater',
                        icon: Icons.water_drop,
                        color: Colors.blue,
                      ),
                      _buildStatCard(
                        context,
                        title: 'Pending Tasks',
                        value: '$pendingTasks',
                        icon: Icons.assignment_turned_in,
                        color: AppColors.accent,
                      ),
                      _buildStatCard(
                        context,
                        title: 'Garden Health',
                        value: gardenHealth,
                        icon: Icons.favorite,
                        color: gardenHealth == 'Excellent' 
                            ? AppColors.success 
                            : (gardenHealth == 'Good' ? AppColors.info : AppColors.danger),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppDimensions.lg),

              // Care Tip Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.yellow, size: AppDimensions.iconMd),
                        SizedBox(width: AppDimensions.sm),
                        Text(
                          'Daily Eco-Tip',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    Text(
                      'SDG 12: Responsible Consumption. Use collected rainwater for watering your indoor plants. It contains beneficial minerals and saves tap water!',
                      style: TextStyle(
                        color: Colors.white.withAlpha(220),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherCard(bool isDark) {
    if (_weatherLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.lg),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_weatherError != null) {
      String errorMessage = 'Failed to load weather data.';
      String subMessage = 'Check internet connection and retry.';
      IconData errorIcon = Icons.error_outline;
      bool showSettingsBtn = false;

      if (_weatherError == 'API_KEY_MISSING') {
        errorMessage = 'OpenWeather API Key Not Configured';
        subMessage = 'Set openWeatherApiKey in lib/core/config/api_keys.dart to activate live weather.';
        errorIcon = Icons.vpn_key_off_outlined;
      } else if (_weatherError == 'API_KEY_INVALID') {
        errorMessage = 'Invalid OpenWeather API Key';
        subMessage = 'Your current API key seems to be invalid. Please verify it.';
        errorIcon = Icons.key_off_outlined;
      } else if (_weatherError == 'CITY_NOT_FOUND') {
        errorMessage = 'City Not Found';
        subMessage = 'Could not find city "$_city". Click to change location.';
        errorIcon = Icons.location_off_outlined;
        showSettingsBtn = true;
      }

      return Card(
        color: isDark ? const Color(0xFF231515) : const Color(0xFFFFF5F5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          side: BorderSide(color: AppColors.danger.withAlpha(50)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(errorIcon, color: AppColors.danger, size: AppDimensions.iconLg),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          errorMessage,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger),
                        ),
                        const SizedBox(height: AppDimensions.xs),
                        Text(
                          subMessage,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (showSettingsBtn) ...[
                const SizedBox(height: AppDimensions.sm),
                ElevatedButton.icon(
                  onPressed: _changeCityDialog,
                  icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
                  label: const Text('Change City'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final weather = _weatherData!;
    final tempStr = '${weather.temperature.toStringAsFixed(1)}°C';
    final descStr = weather.description[0].toUpperCase() + weather.description.substring(1);
    
    // Dynamic recommendation based on weather condition
    String weatherTip = 'Ideal weather parameters for your indoor garden.';
    if (weather.condition.toLowerCase().contains('rain')) {
      weatherTip = 'Rain detected! No need to water your outdoor plants today.';
    } else if (weather.temperature > 32.0) {
      weatherTip = 'High heat alert! Watch soil moisture parameters closely.';
    } else if (weather.condition.toLowerCase().contains('cloud')) {
      weatherTip = 'Cloudy sky today. Indirect sunlight plants are comfortable.';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          children: [
            Row(
              children: [
                // Weather icon dynamically fetched from OpenWeather CDN
                Image.network(
                  'https://openweathermap.org/img/wn/${weather.iconCode}@2x.png',
                  width: 64,
                  height: 64,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.wb_sunny_rounded, color: AppColors.accent, size: AppDimensions.iconLg * 1.5),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _city,
                              style: AppTextStyles.headingSmall(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.edit_location_alt_outlined, size: 18, color: AppColors.primary),
                            tooltip: 'Change City',
                            onPressed: _changeCityDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.xs),
                      Text(
                        '$tempStr • $descStr',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Humidity: ${weather.humidity}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.eco_outlined, color: AppColors.primary, size: 18),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Text(
                    weatherTip,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption(context,
                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted
                  ),
                ),
                Icon(icon, color: color, size: AppDimensions.iconSm),
              ],
            ),
            Text(
              value,
              style: AppTextStyles.headingMedium(context),
            ),
          ],
        ),
      ),
    );
  }
}
