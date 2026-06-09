import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/plant_model.dart';
import '../providers/inventory_provider.dart';
import '../services/cloudinary_service.dart';

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

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  bool _isUploading = false;
  
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
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

      setState(() => _isUploading = true);
      String? uploadedImageUrl = widget.plant?.imageUrl;

      try {
        // Handle Cloudinary upload if a new photo was chosen
        if (_imageFile != null) {
          final resultUrl = await _cloudinaryService.uploadImage(_imageFile!.path);
          if (resultUrl != null) {
            uploadedImageUrl = resultUrl;
          }
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
          imageUrl: uploadedImageUrl,
          notes: _notesController.text.trim(),
        );

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
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.plant != null;
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                // Image Selector Card
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _isUploading ? null : _showImageSourceSheet,
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : Colors.grey[100],
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_imageFile != null)
                            Image.file(_imageFile!, fit: BoxFit.cover)
                          else if (widget.plant?.imageUrl != null && widget.plant!.imageUrl!.isNotEmpty)
                            Image.network(
                              widget.plant!.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              },
                            )
                          else
                            _buildPlaceholder(),
                          Positioned(
                            bottom: AppDimensions.sm,
                            right: AppDimensions.sm,
                            child: Container(
                              padding: const EdgeInsets.all(AppDimensions.xs),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(200),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.md),

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
                          enabled: !_isUploading,
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
                          enabled: !_isUploading,
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
                          onChanged: _isUploading ? null : (val) {
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
                          onTap: _isUploading ? null : () => _selectLastWateredDate(context),
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
                          onChanged: _isUploading ? null : (val) {
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
                                onPressed: _isUploading ? null : () => setState(() => _lastFertilized = null),
                              )
                            : const Icon(Icons.chevron_right),
                          onTap: _isUploading ? null : () => _selectLastFertilizedDate(context),
                        ),
                        const Divider(),

                        // Fertilizing Frequency Slider
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
                          onChanged: _isUploading ? null : (val) {
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
                          enabled: !_isUploading,
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
                  onPressed: _isUploading ? null : _submitForm,
                  child: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(isEditing ? 'Save Changes' : 'Add to My Garden'),
                ),
                const SizedBox(height: AppDimensions.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 40,
          color: AppColors.primary.withAlpha(150),
        ),
        const SizedBox(height: AppDimensions.sm),
        const Text(
          'Add Plant Photo',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        Text(
          'Camera or Gallery',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}
