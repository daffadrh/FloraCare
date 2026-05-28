import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/plant_model.dart';
import '../providers/inventory_provider.dart';

class AddEditPlantScreen extends StatefulWidget {
  final Plant? plant; // If provided, we are editing. If null, we are adding.

  const AddEditPlantScreen({super.key, this.plant});

  @override
  State<AddEditPlantScreen> createState() => _AddEditPlantScreenState();
}

class _AddEditPlantScreenState extends State<AddEditPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _speciesController;
  late TextEditingController _notesController;
  
  late DateTime _lastWatered;
  late int _wateringFrequencyDays;
  late String _sunlightRequirement;
  
  DateTime? _lastFertilized;
  int? _fertilizingFrequencyDays;
  
  final List<String> _sunlightOptions = [
    'Low',
    'Medium',
    'Bright Indirect',
    'Direct',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.plant;
    _nameController = TextEditingController(text: p?.name ?? '');
    _speciesController = TextEditingController(text: p?.species ?? '');
    _notesController = TextEditingController(text: p?.notes ?? '');
    _lastWatered = p?.lastWatered ?? DateTime.now();
    _wateringFrequencyDays = p?.wateringFrequencyDays ?? 7;
    _sunlightRequirement = p?.sunlightRequirement ?? 'Medium';
    _lastFertilized = p?.lastFertilized;
    _fertilizingFrequencyDays = p?.fertilizingFrequencyDays;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectLastWateredDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastWatered,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _lastWatered = picked;
      });
    }
  }

  Future<void> _selectLastFertilizedDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastFertilized ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _lastFertilized = picked;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
      
      if (authProvider.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No active user session.')),
        );
        return;
      }

      final p = widget.plant;
      final plantData = Plant(
        id: p?.id ?? '', // Service will assign an ID if blank
        userId: authProvider.user!.uid,
        name: _nameController.text.trim(),
        species: _speciesController.text.trim(),
        lastWatered: _lastWatered,
        wateringFrequencyDays: _wateringFrequencyDays,
        lastFertilized: _lastFertilized,
        fertilizingFrequencyDays: _fertilizingFrequencyDays,
        sunlightRequirement: _sunlightRequirement,
        imageUrl: p?.imageUrl, // Keep current URL if editing
        notes: _notesController.text.trim(),
      );

      try {
        if (p == null) {
          // Creating new plant
          await inventoryProvider.addPlant(plantData);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('New plant added successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else {
          // Editing existing plant
          await inventoryProvider.updatePlant(plantData);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Plant updated successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Operation failed: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.plant != null;
    final dateFormat = DateFormat('MMMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Plant' : 'Add New Plant'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section 1: Basic Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Basic Details', style: AppTextStyles.headingSmall(context)),
                        const SizedBox(height: AppDimensions.md),
                        
                        // Plant Name
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Plant Nickname *',
                            prefixIcon: Icon(Icons.label_outline),
                            hintText: 'e.g. Monty, Slyther',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a nickname for your plant.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppDimensions.md),
                        
                        // Plant Species
                        TextFormField(
                          controller: _speciesController,
                          decoration: const InputDecoration(
                            labelText: 'Species / Variety *',
                            prefixIcon: Icon(Icons.psychology_outlined),
                            hintText: 'e.g. Monstera Deliciosa, Snake Plant',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the plant species.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppDimensions.md),

                        // Sunlight Requirement Dropdown
                        DropdownButtonFormField<String>(
                          initialValue: _sunlightRequirement,
                          decoration: const InputDecoration(
                            labelText: 'Sunlight Requirements *',
                            prefixIcon: Icon(Icons.wb_sunny_outlined),
                          ),
                          items: _sunlightOptions.map((opt) {
                            return DropdownMenuItem(
                              value: opt,
                              child: Text(opt),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _sunlightRequirement = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.md),

                // Section 2: Care Schedule
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Watering Routine', style: AppTextStyles.headingSmall(context)),
                        const SizedBox(height: AppDimensions.md),

                        // Last Watered Date Picker
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                          title: const Text('Last Watered Date *'),
                          subtitle: Text(dateFormat.format(_lastWatered)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _selectLastWateredDate(context),
                        ),
                        const Divider(),

                        // Watering frequency slider
                        const SizedBox(height: AppDimensions.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Watering Frequency'),
                            Text(
                              'Every $_wateringFrequencyDays ${_wateringFrequencyDays == 1 ? "day" : "days"}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Slider(
                          value: _wateringFrequencyDays.toDouble(),
                          min: 1,
                          max: 30,
                          divisions: 29,
                          activeColor: AppColors.primary,
                          label: '$_wateringFrequencyDays days',
                          onChanged: (val) {
                            setState(() {
                              _wateringFrequencyDays = val.round();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.md),

                // Section 3: Optional Care (Fertilizing)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fertilizing Routine (Optional)', style: AppTextStyles.headingSmall(context)),
                        const SizedBox(height: AppDimensions.md),

                        // Last Fertilized Date
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.calendar_month, color: AppColors.primary),
                          title: const Text('Last Fertilized Date'),
                          subtitle: Text(_lastFertilized == null 
                            ? 'Not fertilized yet / Unknown'
                            : dateFormat.format(_lastFertilized!)),
                          trailing: _lastFertilized != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _lastFertilized = null),
                              )
                            : const Icon(Icons.chevron_right),
                          onTap: () => _selectLastFertilizedDate(context),
                        ),
                        const Divider(),

                        // Fertilizing Frequency Slider/Switch
                        const SizedBox(height: AppDimensions.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Fertilizing Frequency'),
                            Text(
                              _fertilizingFrequencyDays == null
                                  ? 'None (Disabled)'
                                  : 'Every $_fertilizingFrequencyDays days',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Slider(
                          value: (_fertilizingFrequencyDays ?? 0).toDouble(),
                          min: 0,
                          max: 90,
                          divisions: 18,
                          activeColor: AppColors.primary,
                          label: _fertilizingFrequencyDays == null || _fertilizingFrequencyDays == 0
                              ? 'Disabled'
                              : '$_fertilizingFrequencyDays days',
                          onChanged: (val) {
                            setState(() {
                              final intVal = val.round();
                              _fertilizingFrequencyDays = intVal == 0 ? null : intVal;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.md),

                // Section 4: Notes
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Additional Notes', style: AppTextStyles.headingSmall(context)),
                        const SizedBox(height: AppDimensions.md),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Enter care tips, warnings, or special instructions here...',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.lg),

                // Submit Button
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text(isEditing ? 'Save Changes' : 'Add to My Garden'),
                ),
                const SizedBox(height: AppDimensions.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
