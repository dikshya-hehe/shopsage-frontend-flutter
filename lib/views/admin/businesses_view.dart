import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class BusinessesView extends StatelessWidget {
  const BusinessesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 28),
      children: [
        const Text(
          'Businesses',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Merchant access is controlled from the Users tab. Promote a customer to Merchant to let them add products and see their orders.',
          style: TextStyle(color: AppColors.muted, height: 1.45),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.storefront_rounded, color: AppColors.primary, size: 36),
              SizedBox(height: 12),
              Text(
                'How merchant accounts work',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 8),
              Text(
                '1. Open Users and find the account.\n'
                '2. Tap Roles and assign MERCHANT.\n'
                '3. That user can create products and view orders for those products.',
                style: TextStyle(height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
