import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.gavel,
              size: 80,
              color: AppColors.gold,
            ),
            const SizedBox(height: 24),
            Text(
              'Your legal companion app',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isDark ? AppColors.white : AppColors.deepNavy,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
