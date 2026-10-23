import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/product_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/category_style.dart';

class CategoryTab extends StatelessWidget {
  const CategoryTab({
    super.key,
    required this.selectedCategory,
    required this.onSelectCategory,
  });

  final String selectedCategory;
  final ValueChanged<String> onSelectCategory;

  @override
  Widget build(BuildContext context) {
    final productController = Get.find<ProductController>();

    return Obx(() {
      final categories = ['All', ...productController.categories];
      final loading =
          productController.isLoading.value && productController.categories.isEmpty;

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Browse categories',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose a category to shop products on the home page.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 18),
            if (loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.35,
                  ),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final visual = categoryVisual(category);
                    final selected = category == selectedCategory;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onSelectCategory(category),
                        borderRadius: BorderRadius.circular(20),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: selected ? 1.6 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: visual.color.withValues(alpha: 0.12),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: visual.color.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    visual.icon,
                                    color: visual.color,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  category,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  selected ? 'Currently viewing' : 'Tap to explore',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      );
    });
  }
}
