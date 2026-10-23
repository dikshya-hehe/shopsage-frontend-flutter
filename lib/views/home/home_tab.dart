import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../controller/cart_controller.dart';
import '../../controller/product_controller.dart';
import '../../models/product_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/category_style.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/product_card.dart';
import '../product/product_detail_view.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({
    super.key,
    required this.searchVisible,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.selectedCategory,
    required this.onSelectCategory,
  });

  final bool searchVisible;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String selectedCategory;
  final ValueChanged<String> onSelectCategory;

  List<ProductModel> _filtered(ProductController controller) {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return controller.products;
    return controller.products.where((product) {
      final name = product.name?.toLowerCase() ?? '';
      final brand = product.brand?.toLowerCase() ?? '';
      final category = product.category?.toLowerCase() ?? '';
      final description = product.description?.toLowerCase() ?? '';
      return name.contains(query) ||
          brand.contains(query) ||
          category.contains(query) ||
          description.contains(query);
    }).toList();
  }

  List<ProductModel> _carousel(ProductController controller) {
    final productsWithImages =
        controller.products.where((p) => p.imageUrls.isNotEmpty).toList();
    if (productsWithImages.length >= 3) {
      return productsWithImages.take(5).toList();
    }
    return controller.products.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final productController = Get.find<ProductController>();
    final cartController = Get.find<CartController>();

    return Obx(() {
      final loading = productController.isLoading.value;
      final filteredProducts = _filtered(productController);
      final carouselProducts = _carousel(productController);
      return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          if (searchVisible)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search products, brands, categories',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: searchQuery.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              searchController.clear();
                              onSearchChanged('');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(
            child: _HeroCarousel(products: carouselProducts),
          ),
          SliverToBoxAdapter(
            child: _CategoryChips(
              categories: ['All', ...productController.categories],
              selected: selectedCategory,
              onSelected: onSelectCategory,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  const Text(
                    'Featured products',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${filteredProducts.length} items',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (loading && productController.products.isEmpty)
            SliverToBoxAdapter(
              child: Shimmer.fromColors(
                baseColor: const Color(0xFFE8EEE9),
                highlightColor: Colors.white,
                child: ProductGridShimmer(
                  crossAxisCount: _crossAxisCount(context),
                ),
              ),
            )
          else if (filteredProducts.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyProducts(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _crossAxisCount(context),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: MediaQuery.of(context).orientation ==
                          Orientation.landscape
                      ? 0.9
                      : 0.66,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = filteredProducts[index];
                  return ProductCard(
                    product: product,
                    onTap: () =>
                        Get.to(() => ProductDetailView(product: product)),
                    onAddToCart: () {
                      cartController.addToCart(product);
                      AppTheme.snack(
                        'Added to cart',
                        '${product.name ?? 'Product'} has been added.',
                      );
                    },
                  );
                }, childCount: filteredProducts.length),
              ),
            ),
        ],
      );
    });
  }

  int _crossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    if (landscape) return width > 1000 ? 4 : 3;
    if (width > 700) return 3;
    return 2;
  }
}

class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel({required this.products});

  final List<ProductModel> products;

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          height: 188,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
          ),
          padding: const EdgeInsets.all(22),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Welcome to ShopSage',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Discover quality products at great prices.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: widget.products.length,
          itemBuilder: (context, i, _) {
            final product = widget.products[i];
            return GestureDetector(
              onTap: () => Get.to(() => ProductDetailView(product: product)),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppNetworkImage(
                        url: product.imageUrls.isNotEmpty
                            ? product.imageUrls.first
                            : '',
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.05),
                              Colors.black.withValues(alpha: 0.72),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        right: 18,
                        bottom: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (product.brand != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  product.brand!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              product.name ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Rs. ${product.price ?? 0}',
                              style: const TextStyle(
                                color: Color(0xFFFFCC80),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
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
          },
          options: CarouselOptions(
            height: 210,
            viewportFraction: 0.88,
            enlargeCenterPage: true,
            enlargeFactor: 0.18,
            enableInfiniteScroll: widget.products.length > 1,
            autoPlay: widget.products.length > 1,
            autoPlayInterval: const Duration(seconds: 4),
            onPageChanged: (i, _) => setState(() => index = i),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.products.length, (i) {
            final active = i == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 7,
              width: active ? 22 : 7,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final category = categories[i];
          final active = category == selected;
          final visual = categoryVisual(category);
          return ChoiceChip(
            avatar: Icon(
              visual.icon,
              size: 16,
              color: active ? AppColors.primaryDark : visual.color,
            ),
            label: Text(category),
            selected: active,
            onSelected: (_) => onSelected(category),
            showCheckmark: false,
            selectedColor: AppColors.primarySoft,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: active ? AppColors.primary : AppColors.border,
            ),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: active ? AppColors.primaryDark : AppColors.text,
            ),
          );
        },
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 56, color: AppColors.muted),
          SizedBox(height: 12),
          Text(
            'No products found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Try another category or search term.',
            style: TextStyle(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
