import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule_config_model.dart';

class ScheduleSettingsScreen extends StatefulWidget {
  final dynamic plant;

  const ScheduleSettingsScreen({super.key, required this.plant});

  @override
  State<ScheduleSettingsScreen> createState() => _ScheduleSettingsScreenState();
}

class _ScheduleSettingsScreenState extends State<ScheduleSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  int _waterIntervalDays = 1;

  bool _isFertilizingEnabled = false;
  int _fertilizeIntervalDays = 14;

  bool _isRepottingEnabled = false;
  int _repotIntervalDays = 30;

  bool _isRotatingEnabled = false;
  int _rotateIntervalDays = 7;

  bool _isPesticideEnabled = false;
  int _pesticideIntervalDays = 30;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingConfig();
  }

  void _loadExistingConfig() {
    final plantId = (widget.plant as dynamic).id;
    final scheduleProvider = context.read<ScheduleProvider>();
    final config = scheduleProvider.getConfigForPlant(plantId);

    if (config != null) {
      setState(() {
        _waterIntervalDays = config.waterIntervalDays;

        _isFertilizingEnabled = config.isFertilizingEnabled;
        _fertilizeIntervalDays = config.fertilizeIntervalDays;

        _isRepottingEnabled = config.isRepottingEnabled;
        _repotIntervalDays = config.repotIntervalDays;

        _isRotatingEnabled = config.isRotatingEnabled;
        _rotateIntervalDays = config.rotateIntervalDays;

        _isPesticideEnabled = config.isPesticideEnabled;
        _pesticideIntervalDays = config.pesticideIntervalDays;
      });
    }
  }

  void _saveConfig() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      final userId = context.read<AuthProvider>().user?.uid ?? '';

      final config = ScheduleConfigModel(
        plantId: (widget.plant as dynamic).id,
        waterIntervalDays: _waterIntervalDays,
        isFertilizingEnabled: _isFertilizingEnabled,
        fertilizeIntervalDays: _fertilizeIntervalDays,
        isRepottingEnabled: _isRepottingEnabled,
        repotIntervalDays: _repotIntervalDays,
        isRotatingEnabled: _isRotatingEnabled,
        rotateIntervalDays: _rotateIntervalDays,
        isPesticideEnabled: _isPesticideEnabled,
        pesticideIntervalDays: _pesticideIntervalDays,
      );

      await context.read<ScheduleProvider>().saveScheduleConfig(config, userId);

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plantName = (widget.plant as dynamic).name ?? 'Plant';

    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule: $plantName'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildScheduleCard(
                context: context,
                title: 'Watering',
                icon: Icons.water_drop,
                iconColor: Colors.blue,
                isMandatory: true,
                isEnabled: true,
                onSwitchChanged: null,
                intervalValue: _waterIntervalDays,
                onIntervalChanged: (val) => setState(() => _waterIntervalDays = val),
              ),
              const SizedBox(height: 16),

              _buildScheduleCard(
                context: context,
                title: 'Fertilizing',
                icon: Icons.science,
                iconColor: Colors.purple,
                isMandatory: false,
                isEnabled: _isFertilizingEnabled,
                onSwitchChanged: (val) => setState(() => _isFertilizingEnabled = val),
                intervalValue: _fertilizeIntervalDays,
                onIntervalChanged: (val) => setState(() => _fertilizeIntervalDays = val),
              ),
              const SizedBox(height: 16),

              _buildScheduleCard(
                context: context,
                title: 'Repotting',
                icon: Icons.yard,
                iconColor: Colors.brown,
                isMandatory: false,
                isEnabled: _isRepottingEnabled,
                onSwitchChanged: (val) => setState(() => _isRepottingEnabled = val),
                intervalValue: _repotIntervalDays,
                onIntervalChanged: (val) => setState(() => _repotIntervalDays = val),
              ),
              const SizedBox(height: 16),

              _buildScheduleCard(
                context: context,
                title: 'Rotating to Sunlight',
                icon: Icons.rotate_right,
                iconColor: Colors.amber,
                isMandatory: false,
                isEnabled: _isRotatingEnabled,
                onSwitchChanged: (val) => setState(() => _isRotatingEnabled = val),
                intervalValue: _rotateIntervalDays,
                onIntervalChanged: (val) => setState(() => _rotateIntervalDays = val),
              ),
              const SizedBox(height: 16),

              _buildScheduleCard(
                context: context,
                title: 'Applying Pesticide',
                icon: Icons.bug_report,
                iconColor: Colors.red,
                isMandatory: false,
                isEnabled: _isPesticideEnabled,
                onSwitchChanged: (val) => setState(() => _isPesticideEnabled = val),
                intervalValue: _pesticideIntervalDays,
                onIntervalChanged: (val) => setState(() => _pesticideIntervalDays = val),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : _saveConfig,
                  child: const Text('Save Schedule'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isMandatory,
    required bool isEnabled,
    required Function(bool)? onSwitchChanged,
    required int intervalValue,
    required Function(int) onIntervalChanged,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: isEnabled ? iconColor : theme.disabledColor),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isEnabled ? theme.colorScheme.onSurface : theme.disabledColor,
                      ),
                    ),
                  ],
                ),
                if (!isMandatory)
                  Switch(
                    value: isEnabled,
                    onChanged: onSwitchChanged,
                    activeColor: theme.colorScheme.primary,
                  )
                else
                  Text(
                    'Mandatory',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
            if (isEnabled) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Every $intervalValue day${intervalValue > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Max 30',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: intervalValue.toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                activeColor: iconColor,
                inactiveColor: theme.dividerColor,
                label: intervalValue.toString(),
                onChanged: (double value) {
                  onIntervalChanged(value.toInt());
                },
              ),
            ]
          ],
        ),
      ),
    );
  }
}