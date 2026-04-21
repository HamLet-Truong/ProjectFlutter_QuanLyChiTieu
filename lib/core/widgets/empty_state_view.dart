import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

class EmptyStateView extends StatelessWidget {
  final String title;
  final String subtitle;
  final String asset;

  const EmptyStateView({super.key, required this.title, required this.subtitle, this.asset = 'assets/illustrations/empty_state.svg'});

  @override
  Widget build(BuildContext context) {
      final theme = Theme.of(context);
    return Center(
         child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
               padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
               decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                     color: theme.dividerColor.withValues(alpha: 0.1),
                  ),
               ),
               child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     SvgPicture.asset(asset, height: 110, width: 110),
                     const SizedBox(height: 18),
                     Text(
                        title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                           fontWeight: FontWeight.w800,
                           color: AppColors.textPrimary,
                        ),
                     ),
                     const SizedBox(height: 8),
                     Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                           color: AppColors.textSecondary,
                           height: 1.4,
                           fontWeight: FontWeight.w500,
                        ),
                     ),
                  ],
               ),
            ),
         ),
    );
  }
}
