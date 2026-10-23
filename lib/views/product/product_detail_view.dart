import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:get/get.dart';
import '../../controller/cart_controller.dart';
import '../../controller/product_controller.dart';
import '../../models/product_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_network_image.dart';
import '../cart/cart_view.dart';

class ProductDetailView extends StatefulWidget {
  const ProductDetailView({super.key, required this.product});

  final ProductModel product;

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  int activeImageIndex = 0;
  final productController = Get.find<ProductController>();
  final cartController = Get.find<CartController>();
  final carouselController = CarouselSliderController();

  String _productKey(ProductModel product) =>
      product.id ?? product.name ?? product.hashCode.toString();

  List<ProductModel> _related(ProductModel product) {
    return productController.products
        .where(
          (item) =>
              _productKey(item) != _productKey(product) &&
              (product.category == null || item.category == product.category),
        )
        .take(8)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final product = productController.products.firstWhere(
        (p) => p.id == widget.product.id,
        orElse: () => widget.product,
      );
      final imageUrls = product.imageUrls.isNotEmpty ? product.imageUrls : [''];
      final inStock = (product.stock ?? 0) > 0;
      final related = _related(product);

      return Scaffold(
        appBar: AppBar(
          title: Text(
            product.name ?? 'Product',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: 'Cart',
                onPressed: () => Get.to(() => const CartView()),
                icon: Badge(
                  isLabelVisible: cartController.itemCount > 0,
                  backgroundColor: AppColors.accent,
                  label: Text('${cartController.itemCount}'),
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _CheckoutBar(
          product: product,
          inStock: inStock,
          onAdd: () {
            cartController.addToCart(product);
            AppTheme.snack(
              'Added to cart',
              '${product.name} has been added to your cart.',
            );
          },
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            _ImageGallery(
              product: product,
              imageUrls: imageUrls,
              activeIndex: activeImageIndex,
              controller: carouselController,
              onPageChanged: (index) =>
                  setState(() => activeImageIndex = index),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: _InfoCard(product: product, inStock: inStock),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _HighlightsRow(inStock: inStock, stock: product.stock ?? 0),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _AboutCard(
                description: product.description ?? 'No description available.',
              ),
            ),
            if (related.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 22, 20, 12),
                child: Text(
                  'You may also like',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              SizedBox(
                height: 214,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: related.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return _RelatedCard(product: related[index]);
                  },
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _ImageGallery extends StatelessWidget {
  const _ImageGallery({
    required this.product,
    required this.imageUrls,
    required this.activeIndex,
    required this.controller,
    required this.onPageChanged,
  });

  final ProductModel product;
  final List<String> imageUrls;
  final int activeIndex;
  final CarouselSliderController controller;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final inStock = (product.stock ?? 0) > 0;

    return Column(
      children: [
        Stack(
          children: [
            Hero(
              tag: 'product-image-${product.id}',
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
                child: CarouselSlider.builder(
                  carouselController: controller,
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index, realIndex) {
                    final imageUrl = imageUrls[index];
                    return imageUrl.isNotEmpty
                        ? AppNetworkImage(
                            url: imageUrl,
                            height: 360,
                            width: double.infinity,
                          )
                        : Container(
                            height: 360,
                            width: double.infinity,
                            color: AppColors.primarySoft,
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              size: 72,
                              color: AppColors.primary,
                            ),
                          );
                  },
                  options: CarouselOptions(
                    height: 360,
                    viewportFraction: 1,
                    enableInfiniteScroll: imageUrls.length > 1,
                    autoPlay: imageUrls.length > 1,
                    autoPlayInterval: const Duration(seconds: 5),
                    onPageChanged: (index, reason) => onPageChanged(index),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: inStock ? AppColors.primary : AppColors.danger,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  inStock ? 'In stock' : 'Out of stock',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (imageUrls.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(imageUrls.length, (index) {
                    final active = index == activeIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 7,
                      width: active ? 22 : 7,
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.white54,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 6),
                        ],
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
        if (imageUrls.length > 1)
          SizedBox(
            height: 78,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              scrollDirection: Axis.horizontal,
              itemCount: imageUrls.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final selected = index == activeIndex;
                return GestureDetector(
                  onTap: () => controller.animateToPage(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AppNetworkImage(url: imageUrls[index]),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.product, required this.inStock});

  final ProductModel product;
  final bool inStock;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product.brand != null || product.category != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (product.brand != null)
                  _Pill(
                    icon: Icons.storefront_outlined,
                    label: product.brand!,
                    color: AppColors.primary,
                    background: AppColors.primarySoft,
                  ),
                if (product.category != null)
                  _Pill(
                    icon: Icons.category_outlined,
                    label: product.category!,
                    color: AppColors.accent,
                    background: const Color(0xFFFFF3E0),
                  ),
              ],
            ),
          if (product.brand != null || product.category != null)
            const SizedBox(height: 14),
          Text(
            product.name ?? '',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Price',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs. ${product.price ?? 0}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: inStock ? AppColors.primarySoft : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Availability',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      inStock ? '${product.stock} in stock' : 'Unavailable',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: inStock ? AppColors.primaryDark : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightsRow extends StatelessWidget {
  const _HighlightsRow({required this.inStock, required this.stock});

  final bool inStock;
  final int stock;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _HighlightTile(
            icon: Icons.local_shipping_outlined,
            title: 'Delivery',
            subtitle: 'Free over Rs. 5,000',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HighlightTile(
            icon: Icons.verified_outlined,
            title: inStock ? 'Ready to ship' : 'Sold out',
            subtitle: inStock ? '$stock available' : 'Check back later',
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: _HighlightTile(
            icon: Icons.payments_outlined,
            title: 'Payment',
            subtitle: 'Cash or Khalti',
          ),
        ),
      ],
    );
  }
}

class _HighlightTile extends StatelessWidget {
  const _HighlightTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'About this product',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          MarkdownBody(
            data: description,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                fontSize: 15,
                height: 1.7,
                color: AppColors.text,
              ),
              h1: const TextStyle(
                fontSize: 22,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
              h2: const TextStyle(
                fontSize: 18,
                height: 1.45,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
              h3: const TextStyle(
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w700,
              ),
              strong: const TextStyle(fontWeight: FontWeight.w700),
              listBullet: const TextStyle(
                fontSize: 15,
                height: 1.7,
                color: AppColors.primary,
              ),
              blockSpacing: 12,
              listIndent: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _RelatedCard extends StatelessWidget {
  const _RelatedCard({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrls.isNotEmpty ? product.imageUrls.first : '';
    return GestureDetector(
      onTap: () => Get.to(() => ProductDetailView(product: product)),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppNetworkImage(url: imageUrl, width: 150, height: 118),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs. ${product.price ?? 0}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.product,
    required this.inStock,
    required this.onAdd,
  });

  final ProductModel product;
  final bool inStock;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  Text(
                    'Rs. ${product.price ?? 0}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: inStock ? onAdd : null,
                icon: Icon(
                  inStock
                      ? Icons.add_shopping_cart_rounded
                      : Icons.remove_shopping_cart_outlined,
                ),
                label: Text(inStock ? 'Add to cart' : 'Out of stock'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
