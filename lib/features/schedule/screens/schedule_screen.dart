import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule_config_model.dart';
import 'schedule_settings_screen.dart';

const Color _accentGreen = Color(0xFF2d694f);

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
          ? const Center(child: CircularProgressIndicator(color: _accentGreen))
          : plants.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco_outlined,
              size: 80,
              color: _accentGreen.withAlpha(150),
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
          return _PlantScheduleCard(plant: plant);
        },
      ),
    );
  }
}

class _PlantScheduleCard extends StatefulWidget {
  final dynamic plant;
  const _PlantScheduleCard({required this.plant});

  @override
  State<_PlantScheduleCard> createState() => _PlantScheduleCardState();
}

class _PlantScheduleCardState extends State<_PlantScheduleCard> {
  bool _isExpanded = false;

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _showTopNotification(String plantName, String actionText) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _AnimatedNotification(
        message: '$plantName has been $actionText!',
        onDismissed: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
      ),
    );

    overlay.insert(overlayEntry);
  }

  String _getDueText(DateTime lastDate, int interval, {bool isMonth = false}) {
    DateTime nextDate;
    if (isMonth) {
      nextDate = DateTime(lastDate.year, lastDate.month + interval, lastDate.day);
    } else {
      nextDate = lastDate.add(Duration(days: interval));
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(nextDate.year, nextDate.month, nextDate.day);

    int diffDays = target.difference(today).inDays;

    if (diffDays < 0) {
      int absDiff = diffDays.abs();
      if (isMonth && absDiff >= 30) {
        return "overdue ${absDiff ~/ 30}m";
      }
      return "overdue ${absDiff}d";
    } else {
      if (isMonth && diffDays >= 30) {
        return "in ${diffDays ~/ 30}m";
      }
      return "in ${diffDays}d";
    }
  }

  Widget _buildScheduleRow(
      String title,
      IconData icon,
      DateTime lastDate,
      int interval,
      String actionType,
      String actionPastTense,
      String plantName, {
        bool isMonth = false,
      }) {
    String dueText = _getDueText(lastDate, interval, isMonth: isMonth);
    bool isOverdue = dueText.contains("overdue");

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  "$title : ",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Flexible(
                  child: Text(
                    dueText,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isOverdue ? Colors.red : _accentGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              context.read<ScheduleProvider>().performAction((widget.plant as dynamic).id, actionType);
              _showTopNotification(plantName, actionPastTense);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _accentGreen.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: _accentGreen),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plantId = (widget.plant as dynamic).id;
    final String plantName = (widget.plant as dynamic).name ?? 'Unknown Plant';
    final String plantSpecies = (widget.plant as dynamic).species ?? 'Unknown Species';

    String? imageUrl;
    try { imageUrl = (widget.plant as dynamic).imageUrl; } catch (_) {}

    final scheduleProvider = context.watch<ScheduleProvider>();
    ScheduleConfigModel? config = scheduleProvider.getConfigForPlant(plantId);

    config ??= ScheduleConfigModel(
      plantId: plantId,
      waterIntervalDays: 1,
      isFertilizingEnabled: false,
      fertilizeIntervalDays: 14,
      isRepottingEnabled: false,
      repotIntervalMonths: 6,
      isPesticideEnabled: false,
      pesticideIntervalDays: 30,
      lastWateredDate: DateTime.now(),
      lastFertilizedDate: DateTime.now(),
      lastRepottedDate: DateTime.now(),
      lastPesticideDate: DateTime.now(),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 100,
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
            )
                : _buildPlaceholder(),
          ),

          Container(
            margin: const EdgeInsets.only(left: 100),
            child: InkWell(
              onTap: _toggleExpand,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                              const SizedBox(height: 2),
                              Text(
                                plantSpecies,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ScheduleSettingsScreen(plant: widget.plant),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Icon(Icons.edit_square, color: _accentGreen, size: 24),
                          ),
                        ),
                      ],
                    ),

                    ClipRect(
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        alignment: Alignment.topCenter,
                        child: _isExpanded
                            ? SizedBox(
                          width: double.infinity,
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildScheduleRow(
                                    'Watering',
                                    Icons.water_drop,
                                    config.lastWateredDate,
                                    config.waterIntervalDays,
                                    'water',
                                    'watered',
                                    plantName,
                                  ),
                                  if (config.isFertilizingEnabled)
                                    _buildScheduleRow(
                                      'Fertilizing',
                                      Icons.science,
                                      config.lastFertilizedDate,
                                      config.fertilizeIntervalDays,
                                      'fertilize',
                                      'fertilized',
                                      plantName,
                                    ),
                                  if (config.isRepottingEnabled)
                                    _buildScheduleRow(
                                      'Repotting',
                                      Icons.yard,
                                      config.lastRepottedDate,
                                      config.repotIntervalMonths,
                                      'repot',
                                      'repotted',
                                      plantName,
                                      isMonth: true,
                                    ),
                                  if (config.isPesticideEnabled)
                                    _buildScheduleRow(
                                      'Pesticide',
                                      Icons.bug_report,
                                      config.lastPesticideDate,
                                      config.pesticideIntervalDays,
                                      'pesticide',
                                      'treated with pesticide',
                                      plantName,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        )
                            : const SizedBox(width: double.infinity, height: 0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF5ED596),
            _accentGreen,
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.local_florist, color: Colors.white, size: 40),
      ),
    );
  }
}

// Komponen Widget untuk animasi notifikasi (Pop-in & Pop-out)
class _AnimatedNotification extends StatefulWidget {
  final String message;
  final VoidCallback onDismissed;

  const _AnimatedNotification({required this.message, required this.onDismissed});

  @override
  State<_AnimatedNotification> createState() => _AnimatedNotificationState();
}

class _AnimatedNotificationState extends State<_AnimatedNotification> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Memutar animasi balik setelah 2.5 detik
    Future.delayed(const Duration(milliseconds: 2500), () async {
      if (mounted) {
        await _controller.reverse();
        widget.onDismissed();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _accentGreen,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}