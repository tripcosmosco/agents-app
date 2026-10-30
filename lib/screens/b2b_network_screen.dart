import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../widgets/b2b_partners_view.dart';

class B2bNetworkScreen extends StatelessWidget {
  const B2bNetworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getSurface(context),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surface : Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.hub_rounded,
                    color: AppColors.accentGold,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'B2B Agency Network',
                  style: TextStyle(
                    color: AppColors.getTextPrimary(context),
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Text(
                'Pan-India DMC & Wholesale Ground Tariffs',
                style: TextStyle(
                  color: AppColors.getTextSecondary(context),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      body: const SafeArea(
        child: B2bPartnersView(),
      ),
    );
  }
}
