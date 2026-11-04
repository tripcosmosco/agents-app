import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../widgets/b2b_partners_view.dart';

class B2bNetworkScreen extends StatelessWidget {
  const B2bNetworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getSurface(context),
      body: const SafeArea(
        child: B2bPartnersView(embedded: false),
      ),
    );
  }
}
