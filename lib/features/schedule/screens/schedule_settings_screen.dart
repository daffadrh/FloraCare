import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule_config_model.dart';

const Color _accentGreen = Color(0xFF2d694f);

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
  int _repotIntervalMonths = 6;

  bool _isPesticideEnabled = false;
  int _pesticideIntervalDays = 30;

  bool _isLoading = false;
  ScheduleConfigModel? _existingConfig;

  @override
  void initState() {
    super.initState();
    _loadExistingConfig();
  }

  void _loadExistingConfig() {
    final plantId = (widget.plant as dynamic).id;
    final scheduleProvider = context.read<ScheduleProvider>();
    _existingConfig = scheduleProvider.getConfigForPlant(plantId);

    if (_existingConfig != null) {
      setState(() {
        _waterIntervalDays = _existingConfig!.waterIntervalDays;

        _isFertilizingEnabled = _existingConfig!.isFertilizingEnabled;
        _fertilizeIntervalDays = _existingConfig!.fertilizeIntervalDays;

        _isRepottingEnabled = _existingConfig!.isRepottingEnabled;
        _repotIntervalMonths = _existingConfig!.repotIntervalMonths;

        _isPesticideEnabled = _existingConfig!.isPesticideEnabled;
        _pesticideIntervalDays = _existingConfig!.pesticideIntervalDays;
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
        repotIntervalMonths: _repotIntervalMonths,
        isPesticideEnabled: _isPesticideEnabled,
        pesticideIntervalDays: _pesticideIntervalDays,
        lastWateredDate: _existingConfig?.lastWateredDate ?? DateTime.now(),
        lastFertilizedDate: _existingConfig?.lastFertilizedDate ?? DateTime.now(),
        lastRepottedDate: _existingConfig?.lastRepottedDate ?? DateTime.now(),
        lastPesticideDate: _existingConfig?.lastPesticideDate ?? DateTime.now(),
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
          ? const Center(child: CircularProgressIndicator(color: _accentGreen))
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
                isMandatory: true,
                isEnabled: true,
                onSwitchChanged: null,
                intervalValue: _waterIntervalDays,
                maxSliderValue: 30,
                unitName: 'Day',
                onIntervalChanged: (val) => setState(() => _waterIntervalDays = val),
              ),
              const SizedBox(height: 16),

              _buildScheduleCard(
                context: context,
                title: 'Fertilizing',
                icon: Icons.science,
                isMandatory: false,
                isEnabled: _isFertilizingEnabled,
                onSwitchChanged: (val) => setState(() => _isFertilizingEnabled = val),
                intervalValue: _fertilizeIntervalDays,
                maxSliderValue: 30,
                unitName: 'Day',
                onIntervalChanged: (val) => setState(() => _fertilizeIntervalDays = val),
              ),
              const SizedBox(height: 16),

              _buildScheduleCard(
                context: context,
                title: 'Repotting',
                icon: Icons.yard,
                isMandatory: false,
                isEnabled: _isRepottingEnabled,
                onSwitchChanged: (val) => setState(() => _isRepottingEnabled = val),
                intervalValue: _repotIntervalMonths,
                maxSliderValue: 12,
                unitName: 'Month',
                onIntervalChanged: (val) => setState(() => _repotIntervalMonths = val),
              ),
              const SizedBox(height: 16),

              _buildScheduleCard(
                context: context,
                title: 'Applying Pesticide',
                icon: Icons.bug_report,
                isMandatory: false,
                isEnabled: _isPesticideEnabled,
                onSwitchChanged: (val) => setState(() => _isPesticideEnabled = val),
                intervalValue: _pesticideIntervalDays,
                maxSliderValue: 30,
                unitName: 'Day',
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
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _accentGreen,
                    side: const BorderSide(color: _accentGreen, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : _saveConfig,
                  child: const Text('Save Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
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
    required bool isMandatory,
    required bool isEnabled,
    required Function(bool)? onSwitchChanged,
    required int intervalValue,
    required double maxSliderValue,
    required String unitName,
    required Function(int) onIntervalChanged,
  }) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.hardEdge,
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
                    Icon(icon, color: isEnabled ? _accentGreen : theme.disabledColor),
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
                    activeColor: _accentGreen,
                  )
                else
                  const Text(
                    'Mandatory',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _accentGreen,
                    ),
                  ),
              ],
            ),

            // Animasi expanding bar saat switch ditekan
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: isEnabled
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 24),
                    Text(
                      'Every $intervalValue $unitName${intervalValue > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '1 $unitName',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(150)),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: _accentGreen,
                              inactiveTrackColor: _accentGreen.withAlpha(50),
                              thumbColor: _accentGreen,
                              trackHeight: 6.0,
                              overlayColor: _accentGreen.withAlpha(30),
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
                            ),
                            child: Slider(
                              value: intervalValue.toDouble(),
                              min: 1,
                              max: maxSliderValue,
                              divisions: (maxSliderValue - 1).toInt(),
                              label: intervalValue.toString(),
                              onChanged: (double value) {
                                onIntervalChanged(value.toInt());
                              },
                            ),
                          ),
                        ),
                        Text(
                          '${maxSliderValue.toInt()} ${unitName}s',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(150)),
                        ),
                      ],
                    ),
                  ],
                )
                    : const SizedBox(width: double.infinity, height: 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}