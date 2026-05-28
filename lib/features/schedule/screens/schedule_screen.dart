import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Care Schedule'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_month,
                size: 80,
                color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
              ),
              const SizedBox(height: AppDimensions.md),
              Text(
                'Care Tasks & Reminders',
                style: AppTextStyles.headingMedium(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.sm),
              Text(
                'This feature is owned by Member 2.\nIt will manage watering schedules, fertilizing notifications, and calendar views.',
                style: AppTextStyles.bodyMedium(context,
                  color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.xl),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Care schedule feature is under development.')),
                  );
                },
                icon: const Icon(Icons.notifications_active),
                label: const Text('Simulate Notification'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
