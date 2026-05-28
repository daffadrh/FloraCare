import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Journal'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.book,
                size: 80,
                color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
              ),
              const SizedBox(height: AppDimensions.md),
              Text(
                'Plant Health Logs & API',
                style: AppTextStyles.headingMedium(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.sm),
              Text(
                'This feature is owned by Member 3.\nIt will handle plant disease scanning, symptom logging, and Plant.id/OpenWeather API integration.',
                style: AppTextStyles.bodyMedium(context,
                  color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.xl),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('AI Plant diagnosis scanner under development.')),
                  );
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Scan with Plant.id'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
