import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, Gardener! 👋',
                        style: AppTextStyles.headingMedium(context),
                      ),
                      const SizedBox(height: AppDimensions.xs),
                      Text(
                        'How are your green friends doing today?',
                        style: AppTextStyles.bodyMedium(context, 
                          color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted
                        ),
                      ),
                    ],
                  ),
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.lg),

              // Weather widget placeholder (External API Goal)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  child: Row(
                    children: [
                      Icon(Icons.wb_sunny_rounded, color: AppColors.accent, size: AppDimensions.iconLg * 1.5),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sunny, 28°C',
                              style: AppTextStyles.headingSmall(context),
                            ),
                            const SizedBox(height: AppDimensions.xs),
                            Text(
                              'Perfect day for your outdoor plants! Watering needs might increase today.',
                              style: AppTextStyles.caption(context,
                                color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.lg),

              // Quick Stats
              Text(
                'Today\'s Summary',
                style: AppTextStyles.headingSmall(context),
              ),
              const SizedBox(height: AppDimensions.md),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: AppDimensions.md,
                mainAxisSpacing: AppDimensions.md,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    context,
                    title: 'Total Plants',
                    value: '12',
                    icon: Icons.local_florist,
                    color: AppColors.primary,
                  ),
                  _buildStatCard(
                    context,
                    title: 'Needs Water',
                    value: '3',
                    icon: Icons.water_drop,
                    color: Colors.blue,
                  ),
                  _buildStatCard(
                    context,
                    title: 'Pending Tasks',
                    value: '5',
                    icon: Icons.assignment_turned_in,
                    color: AppColors.accent,
                  ),
                  _buildStatCard(
                    context,
                    title: 'Health Log',
                    value: 'Excellent',
                    icon: Icons.favorite,
                    color: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.lg),

              // Care Tip Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.yellow, size: AppDimensions.iconMd),
                        SizedBox(width: AppDimensions.sm),
                        Text(
                          'Daily Eco-Tip',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    Text(
                      'SDG 12: Responsible Consumption. Use collected rainwater for watering your indoor plants. It contains beneficial minerals and saves tap water!',
                      style: TextStyle(
                        color: Colors.white.withAlpha(220),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption(context,
                    color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted
                  ),
                ),
                Icon(icon, color: color, size: AppDimensions.iconSm),
              ],
            ),
            Text(
              value,
              style: AppTextStyles.headingMedium(context),
            ),
          ],
        ),
      ),
    );
  }
}
