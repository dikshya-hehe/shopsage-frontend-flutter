import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategoryVisual {
  const CategoryVisual(this.icon, this.color);

  final IconData icon;
  final Color color;
}

CategoryVisual categoryVisual(String name) {
  final n = name.toLowerCase();
  if (n == 'all') {
    return const CategoryVisual(Icons.apps_rounded, AppColors.primary);
  }
  if (n.contains('electron') || n.contains('gadget') || n.contains('phone')) {
    return const CategoryVisual(Icons.devices_other_rounded, Color(0xFF1565C0));
  }
  if (n.contains('fashion') || n.contains('cloth') || n.contains('apparel')) {
    return const CategoryVisual(Icons.checkroom_rounded, Color(0xFFC2185B));
  }
  if (n.contains('beauty') || n.contains('cosmetic')) {
    return const CategoryVisual(Icons.spa_rounded, Color(0xFF7B1FA2));
  }
  if (n.contains('home') || n.contains('kitchen') || n.contains('furn')) {
    return const CategoryVisual(Icons.chair_rounded, Color(0xFFEF6C00));
  }
  if (n.contains('sport') || n.contains('fitness')) {
    return const CategoryVisual(Icons.sports_basketball_rounded, Color(0xFF00838F));
  }
  if (n.contains('book') || n.contains('edu')) {
    return const CategoryVisual(Icons.menu_book_rounded, Color(0xFF5D4037));
  }
  if (n.contains('food') || n.contains('grocery') || n.contains('grocery')) {
    return const CategoryVisual(Icons.restaurant_rounded, Color(0xFF2E7D32));
  }
  if (n.contains('toy') || n.contains('kid') || n.contains('baby')) {
    return const CategoryVisual(Icons.toys_rounded, Color(0xFFF9A825));
  }
  if (n.contains('health') || n.contains('medic')) {
    return const CategoryVisual(Icons.health_and_safety_rounded, Color(0xFF00695C));
  }
  if (n.contains('auto') || n.contains('car')) {
    return const CategoryVisual(Icons.directions_car_rounded, Color(0xFF37474F));
  }
  return CategoryVisual(
    Icons.category_rounded,
    Colors.primaries[name.hashCode.abs() % Colors.primaries.length],
  );
}
