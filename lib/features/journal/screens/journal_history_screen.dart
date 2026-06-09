import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/constants.dart';
import '../../inventory/models/plant_model.dart';
import '../providers/journal_provider.dart';
import 'add_edit_journal_screen.dart';

class JournalHistoryScreen extends StatefulWidget {
  final Plant plant;

  const JournalHistoryScreen({super.key, required this.plant});

  @override
  State<JournalHistoryScreen> createState() => _JournalHistoryScreenState();
}

class _JournalHistoryScreenState extends State<JournalHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalProvider>().init(widget.plant.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Health Logs: ${widget.plant.name}'),
        actions: [
          Consumer<JournalProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: Icon(
                  provider.filterActiveOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
                  color: provider.filterActiveOnly ? AppColors.warning : null,
                ),
                onPressed: () {
                  provider.setFilterActiveOnly(!provider.filterActiveOnly);
                },
                tooltip: 'Filter Active Issues',
              );
            },
          ),
        ],
      ),
      body: Consumer<JournalProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(child: Text('Error: ${provider.errorMessage}'));
          }

          if (provider.logs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.monitor_heart_outlined,
                      size: 80,
                      color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Text(
                      'Belum Ada Riwayat',
                      style: AppTextStyles.headingMedium(context),
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    Text(
                      'Catat gejala atau pantau kesehatan tanamanmu di sini.',
                      style: AppTextStyles.bodyMedium(context, color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.md),
            itemCount: provider.logs.length,
            itemBuilder: (context, index) {
              final log = provider.logs[index];
              
              return Dismissible(
                key: Key(log.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  margin: const EdgeInsets.only(bottom: AppDimensions.md),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white, size: 30),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
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
                },
                onDismissed: (direction) {
                  provider.deleteHealthLog(log.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Catatan kesehatan berhasil dihapus'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: AppDimensions.md),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(AppDimensions.md),
                    title: Text(
                      log.diagnosis.isNotEmpty ? log.diagnosis : 'Gejala: ${log.symptoms}',
                      style: AppTextStyles.headingSmall(context),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: AppDimensions.xs),
                      child: Text(
                        DateFormat('dd MMM yyyy').format(log.date),
                        style: AppTextStyles.caption(context, color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted),
                      ),
                    ),
                    trailing: log.isRecovered
                        ? const Icon(Icons.check_circle, color: AppColors.success, size: AppDimensions.iconLg)
                        : const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: AppDimensions.iconLg),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddEditJournalScreen(
                            plantId: widget.plant.id,
                            userId: widget.plant.userId,
                            log: log,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditJournalScreen(
                plantId: widget.plant.id,
                userId: widget.plant.userId,
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}