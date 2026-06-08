import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/constants.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../../inventory/models/plant_model.dart';
import '../services/plant_id_service.dart';
import '../services/journal_service.dart';
import '../models/journal_model.dart';
import 'journal_history_screen.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final ImagePicker _picker = ImagePicker();
  final PlantIdService _plantIdService = PlantIdService();
  final JournalService _journalService = JournalService();

  Future<void> _startQuickScan(BuildContext context) async {
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

      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(AppDimensions.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: AppDimensions.md),
                  Text('AI sedang menganalisa...'),
                ],
              ),
            ),
          ),
        ),
      );

      final File imageFile = File(pickedFile.path);
      final Map<String, String> diagnosisData = await _plantIdService.identifyDisease(imageFile);
      final String diagnosisResult = 'Diagnosis: ${diagnosisData['diagnosis']}\n\n${diagnosisData['notes']}';

      if (!context.mounted) return;
      Navigator.of(context).pop();

      _showScanResultDialog(context, diagnosisResult);
      
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses gambar: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _showScanResultDialog(BuildContext context, String result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.document_scanner, color: AppColors.primary),
            const SizedBox(width: AppDimensions.sm),
            const Text('Hasil Diagnosa AI'),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            result,
            style: AppTextStyles.bodyMedium(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Journal'),
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, inventory, _) {
          if (inventory.isLoading && inventory.plants.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (inventory.plants.isEmpty) {
            return _buildEmptyState(context, isDark);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.md),
            itemCount: inventory.plants.length,
            itemBuilder: (context, index) {
              final plant = inventory.plants[index];
              return _buildJournalCard(context, plant, isDark);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startQuickScan(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.document_scanner),
        label: const Text('Scan Disease'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.health_and_safety_outlined,
              size: 80,
              color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
            ),
            const SizedBox(height: AppDimensions.md),
            Text(
              'No Health Issues',
              style: AppTextStyles.headingMedium(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              'All your plants are healthy! Keep up the good work.',
              style: AppTextStyles.bodyMedium(context,
                  color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalCard(BuildContext context, Plant plant, bool isDark) {
    return StreamBuilder<List<HealthLog>>(
      stream: _journalService.streamPlantHealthLogs(plant.id),
      builder: (context, snapshot) {
        int activeIssuesCount = 0;
        
        if (snapshot.hasData) {
          activeIssuesCount = snapshot.data!.where((log) => !log.isRecovered).length;
        }

        final bool hasIssues = activeIssuesCount > 0;
        final Color indicatorColor = hasIssues ? AppColors.warning : AppColors.success;
        final String subtitleText = hasIssues 
            ? '$activeIssuesCount Active Issue${activeIssuesCount > 1 ? 's' : ''}' 
            : 'No active issues';

        return Card(
          margin: const EdgeInsets.only(bottom: AppDimensions.md),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JournalHistoryScreen(plant: plant),
                ),
              );
            },
            child: Column(
              children: [
                Container(
                  height: 4,
                  width: double.infinity,
                  color: indicatorColor,
                ),
                ListTile(
                  contentPadding: const EdgeInsets.all(AppDimensions.md),
                  leading: Container(
                    padding: const EdgeInsets.all(AppDimensions.sm),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.primaryDark : AppColors.secondary.withAlpha(50),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: const Icon(Icons.local_florist, color: AppColors.primary),
                  ),
                  title: Text(
                    plant.name,
                    style: AppTextStyles.headingSmall(context),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: AppDimensions.xs),
                    child: Text(
                      subtitleText,
                      style: TextStyle(
                        fontSize: 12,
                        color: hasIssues ? AppColors.warning : (isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
                      ),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}