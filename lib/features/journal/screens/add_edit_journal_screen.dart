import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/constants.dart';
import '../models/journal_model.dart';
import '../providers/journal_provider.dart';
import '../services/plant_id_service.dart';

class AddEditJournalScreen extends StatefulWidget {
  final String plantId;
  final String userId;
  final HealthLog? log;

  const AddEditJournalScreen({
    super.key,
    required this.plantId,
    required this.userId,
    this.log,
  });

  @override
  State<AddEditJournalScreen> createState() => _AddEditJournalScreenState();
}

class _AddEditJournalScreenState extends State<AddEditJournalScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _symptomsController;
  late TextEditingController _diagnosisController;
  late TextEditingController _notesController;
  bool _isRecovered = false;
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();
  final PlantIdService _plantIdService = PlantIdService();
  File? _imageFile;

  bool get _isEditMode => widget.log != null;

  @override
  void initState() {
    super.initState();
    _symptomsController = TextEditingController(text: widget.log?.symptoms ?? '');
    _diagnosisController = TextEditingController(text: widget.log?.diagnosis ?? '');
    _notesController = TextEditingController(text: widget.log?.notes ?? '');
    _isRecovered = widget.log?.isRecovered ?? false;
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    _diagnosisController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _scanPlantForAutoFill() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(AppDimensions.md),
                child: Text('Pilih Foto Tanaman', style: AppTextStyles.headingSmall(context)),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: AppColors.primary),
                title: const Text('Ambil dari Kamera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Pilih dari Galeri'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              const SizedBox(height: AppDimensions.xl),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return;

      setState(() {
        _imageFile = File(pickedFile.path);
        _isSaving = true;
      });

      final resultData = await _plantIdService.identifyDisease(_imageFile!);
      
      if (!mounted) return; 

      setState(() {
        _diagnosisController.text = resultData['diagnosis'] ?? '';
        _notesController.text = resultData['notes'] ?? '';
        _isSaving = false;
      });

      if (!mounted) return; 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI berhasil mengisi diagnosis!'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() { _isSaving = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memproses gambar: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final journalProvider = context.read<JournalProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (_isEditMode) {
        final updatedLog = widget.log!.copyWith(
          symptoms: _symptomsController.text.trim(),
          diagnosis: _diagnosisController.text.trim(),
          notes: _notesController.text.trim(),
          isRecovered: _isRecovered,
          date: DateTime.now(),
        );
        await journalProvider.updateHealthLog(updatedLog);
      } else {
        final newLog = HealthLog(
          id: '',
          plantId: widget.plantId,
          userId: widget.userId,
          date: DateTime.now(),
          symptoms: _symptomsController.text.trim(),
          diagnosis: _diagnosisController.text.trim(),
          notes: _notesController.text.trim(),
          isRecovered: _isRecovered,
          photoUrl: null,
        );
        await journalProvider.addHealthLog(newLog);
      }

      if (!mounted) return; 
      messenger.showSnackBar(
        const SnackBar(content: Text('Data berhasil disimpan!'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteLog() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Jurnal?'),
          content: const Text('Apakah kamu yakin ingin menghapus catatan ini? Data tidak bisa dikembalikan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    setState(() => _isSaving = true);
    
    final journalProvider = context.read<JournalProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      await journalProvider.deleteHealthLog(widget.log!.id);
      
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Catatan kesehatan berhasil dihapus'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context); 
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: AppColors.danger),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Health Log' : 'Add Health Log'),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _deleteLog,
              tooltip: 'Hapus Jurnal',
            ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _scanPlantForAutoFill,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.grey.withAlpha(30),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                                child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_a_photo_outlined, size: 48, color: AppColors.primary),
                                  const SizedBox(height: AppDimensions.sm),
                                  Text('Ambil Foto Gejala', style: AppTextStyles.bodyMedium(context)),
                                  Text('(AI Diagnosis)', style: AppTextStyles.caption(context, color: AppColors.primaryLight)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    Text('Symptom / Gejala', style: AppTextStyles.headingSmall(context)),
                    TextFormField(
                      controller: _symptomsController,
                      maxLines: 3,
                      decoration: const InputDecoration(hintText: 'Misal: Daun bercak hitam...'),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Mohon isi gejala' : null,
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Text('Diagnosis / Nama Penyakit', style: AppTextStyles.headingSmall(context)),
                    TextFormField(
                      controller: _diagnosisController,
                      decoration: const InputDecoration(hintText: 'Misal: Black Spot Disease'),
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Text('Notes / Catatan Perawatan', style: AppTextStyles.headingSmall(context)),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 6,
                      decoration: const InputDecoration(hintText: 'Tambahkan info penanganan...'),
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Card(
                      child: SwitchListTile(
                        title: const Text('Tanaman Sudah Sembuh?'),
                        value: _isRecovered,
                        activeTrackColor: AppColors.success,
                        onChanged: (bool value) => setState(() => _isRecovered = value),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.xl),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveForm,
                        child: Text(_isEditMode ? 'Update Log' : 'Save Log'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}