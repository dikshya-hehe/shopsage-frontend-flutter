import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controller/auth_controller.dart';
import '../../controller/cart_controller.dart';
import '../../controller/product_controller.dart';
import '../../models/product_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_network_image.dart';
import '../product/product_detail_view.dart';

class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  final cartController = Get.find<CartController>();
  final authController = Get.find<AuthController>();
  final productController = Get.find<ProductController>();
  final ApiService _apiService = ApiService();

  late final TextEditingController cityController;
  late final TextEditingController provinceController;
  late final TextEditingController countryController;
  late final TextEditingController promoController;

  final Map<String, bool> selectedItems = {};
  final Map<String, int> quantities = {};
  late Worker _cartItemsWorker;

  String selectedPayment = 'cash';
  bool isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    final user = authController.currentUser.value;
    cityController = TextEditingController(text: user?.address?.city ?? '');
    provinceController = TextEditingController(text: '');
    countryController = TextEditingController(
      text: user?.address?.country ?? 'Nepal',
    );
    promoController = TextEditingController();

    if (productController.products.isEmpty) {
      productController.fetchProducts();
    }

    _syncCartState();
    _cartItemsWorker = ever(cartController.items, (_) => _syncCartState());
  }

  @override
  void dispose() {
    _cartItemsWorker.dispose();
    cityController.dispose();
    provinceController.dispose();
    countryController.dispose();
    promoController.dispose();
    super.dispose();
  }

  String _productIdKey(ProductModel item) =>
      item.id ?? item.name ?? item.hashCode.toString();

  String _entryKey(int index, ProductModel item) =>
      '${_productIdKey(item)}::$index';

  void _syncCartState() {
    if (!mounted) return;

    final currentKeys = <String>{};
    for (var i = 0; i < cartController.items.length; i++) {
      final item = cartController.items[i];
      final key = _entryKey(i, item);
      currentKeys.add(key);
      selectedItems.putIfAbsent(key, () => true);
      quantities.putIfAbsent(key, () => 1);
    }
    selectedItems.removeWhere((key, _) => !currentKeys.contains(key));
    quantities.removeWhere((key, _) => !currentKeys.contains(key));
    setState(() {});
  }

  double get subtotal {
    var sum = 0.0;
    for (var i = 0; i < cartController.items.length; i++) {
      final item = cartController.items[i];
      final key = _entryKey(i, item);
      if (selectedItems[key] != true) continue;
      final qty = quantities[key] ?? 1;
      sum += (item.price ?? 0) * qty;
    }
    return sum;
  }

  double get shipping {
    if (subtotal == 0) return 0;
    return subtotal >= 5000 ? 0 : 100;
  }

  double get discount {
    return subtotal >= 50000 ? 500 : 0;
  }

  double get total {
    return subtotal + shipping - discount;
  }

  bool get allSelected {
    if (cartController.items.isEmpty) return false;
    for (var i = 0; i < cartController.items.length; i++) {
      final key = _entryKey(i, cartController.items[i]);
      if (selectedItems[key] != true) return false;
    }
    return true;
  }

  Future<void> _placeOrder() async {
    if (cartController.items.isEmpty) {
      AppTheme.snack(
        'Cart empty',
        'Add some products before placing an order.',
        error: true,
      );
      return;
    }

    final selectedProducts = <ProductModel>[];
    for (var i = 0; i < cartController.items.length; i++) {
      final item = cartController.items[i];
      final key = _entryKey(i, item);
      if (selectedItems[key] == true) selectedProducts.add(item);
    }
    if (selectedProducts.isEmpty) {
      AppTheme.snack(
        'Select products',
        'Please select items to checkout.',
        error: true,
      );
      return;
    }

    if (authController.currentUser.value == null) {
      AppTheme.snack(
        'Login required',
        'Please login to place an order.',
        error: true,
      );
      return;
    }

    final city = cityController.text.trim();
    final province = provinceController.text.trim();
    final country = countryController.text.trim();

    if (city.isEmpty || country.isEmpty) {
      AppTheme.snack(
        'Missing details',
        'Please enter city and country for delivery.',
        error: true,
      );
      return;
    }

    setState(() => isPlacingOrder = true);

    try {
      final navigator = Navigator.of(context);
      final orderItems = <Map<String, dynamic>>[];
      for (var i = 0; i < cartController.items.length; i++) {
        final item = cartController.items[i];
        final key = _entryKey(i, item);
        if (selectedItems[key] == true) {
          final qty = quantities[key] ?? 1;
          orderItems.add({'product': item.id, 'quantity': qty});
        }
      }

      final order = await _apiService.createOrder(
        orderItems: orderItems.cast<Map<String, dynamic>>(),
        shippingAddress: {
          'city': city,
          'province': province,
          'country': country,
        },
        totalPrice: total.toInt(),
      );

      if (selectedPayment == 'cash') {
        await _apiService.payOrderViaCash(order.id ?? '');
        await _refreshProducts();
        cartController.clearCart();
        if (!mounted) return;
        AppTheme.snack(
          'Order placed',
          'Your order is confirmed. Pay on delivery.',
        );
        if (navigator.mounted) {
          navigator.pop();
        }
      } else {
        final paymentData = await _apiService.payOrderViaKhalti(order.id ?? '');
        final paymentUrl = paymentData['payment_url']?.toString() ?? '';
        await _refreshProducts();
        cartController.clearCart();
        if (!mounted) return;
        if (paymentUrl.isNotEmpty) {
          final launched = await launchUrl(
            Uri.parse(paymentUrl),
            mode: LaunchMode.externalApplication,
          );
          if (!launched) {
            AppTheme.snack(
              'Khalti payment',
              'Could not open the Khalti payment page.',
              error: true,
            );
          }
        } else {
          AppTheme.snack(
            'Khalti payment',
            'Payment link was not returned. Please try cash or contact support.',
            error: true,
          );
        }
        if (navigator.mounted) {
          navigator.pop();
        }
      }
    } catch (e) {
      if (!mounted) return;
      AppTheme.snack(
        'Checkout failed',
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => isPlacingOrder = false);
      }
    }
  }

  Future<void> _refreshProducts() async {
    try {
      await productController.fetchProducts();
    } catch (_) {}
  }

  Widget summaryRow(String title, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              color: isBold ? AppColors.text : AppColors.muted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isBold ? AppColors.accent : AppColors.text,
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCartItem(ProductModel item, int index) {
    final key = _entryKey(index, item);
    final qty = quantities[key] ?? 1;
    final imageUrl = item.imageUrls.isNotEmpty ? item.imageUrls.first : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: selectedItems[key] ?? true,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            onChanged: (value) {
              setState(() {
                selectedItems[key] = value ?? false;
              });
            },
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AppNetworkImage(url: imageUrl, width: 82, height: 82),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  item.brand ?? item.category ?? 'Standard',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rs. ${item.price ?? 0}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _QtyButton(
                      icon: Icons.remove_rounded,
                      onTap: qty > 1
                          ? () => setState(() => quantities[key] = qty - 1)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '$qty',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    _QtyButton(
                      icon: Icons.add_rounded,
                      onTap: () => setState(() => quantities[key] = qty + 1),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.danger,
                      ),
                      onPressed: () => cartController.removeFromCart(item),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<ProductModel> get recommendedProducts {
    final cartProductIds = cartController.items.map(_productIdKey).toSet();
    return productController.products
        .where((product) => !cartProductIds.contains(_productIdKey(product)))
        .take(6)
        .toList();
  }

  Widget buildRecommendedItem(ProductModel product) {
    final imageUrl = product.imageUrls.isNotEmpty
        ? product.imageUrls.first
        : '';
    return GestureDetector(
      onTap: () => Get.to(() => ProductDetailView(product: product)),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
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
                    product.name ?? 'Recommended',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

  Widget _sectionCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
      ),
      body: Obx(() {
        if (cartController.items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 42,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Browse products and add them here to checkout.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton.icon(
                    onPressed: Get.back,
                    icon: const Icon(Icons.storefront_rounded),
                    label: const Text('Continue shopping'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          children: [
            _sectionCard(
              child: Row(
                children: [
                  Checkbox(
                    value: allSelected,
                    activeColor: AppColors.primary,
                    onChanged: (value) {
                      setState(() {
                        for (var i = 0; i < cartController.items.length; i++) {
                          selectedItems[_entryKey(
                                i,
                                cartController.items[i],
                              )] =
                              value ?? false;
                        }
                      });
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'Select all items',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    '${cartController.items.length} items',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            ...List.generate(
              cartController.items.length,
              (i) => buildCartItem(cartController.items[i], i),
            ),
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.confirmation_number_outlined,
                        color: AppColors.accent,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Have a promo code?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: promoController,
                          decoration: const InputDecoration(
                            hintText: 'CODE10',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('APPLY'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _sectionCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_shipping_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Standard delivery',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Free shipping over Rs. 5,000',
                          style: TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    shipping == 0 ? 'FREE' : 'Rs. ${shipping.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: shipping == 0 ? AppColors.primary : AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
            _sectionCard(
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Order summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  summaryRow(
                    'Subtotal',
                    'Rs. ${subtotal.toStringAsFixed(0)}',
                  ),
                  summaryRow(
                    'Shipping',
                    shipping == 0 ? 'FREE' : 'Rs. ${shipping.toStringAsFixed(0)}',
                  ),
                  summaryRow(
                    'Discount',
                    '-Rs. ${discount.toStringAsFixed(0)}',
                  ),
                  const Divider(height: 24),
                  summaryRow(
                    'Total',
                    'Rs. ${total.toStringAsFixed(0)}',
                    isBold: true,
                  ),
                ],
              ),
            ),
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delivery details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: provinceController,
                    decoration: const InputDecoration(
                      labelText: 'Province',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: countryController,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      prefixIcon: Icon(Icons.public_outlined),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Payment method',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _PaymentTile(
                          title: 'Cash',
                          subtitle: 'Pay on delivery',
                          icon: Icons.payments_outlined,
                          selected: selectedPayment == 'cash',
                          onTap: () =>
                              setState(() => selectedPayment = 'cash'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PaymentTile(
                          title: 'Khalti',
                          subtitle: 'Digital wallet',
                          icon: Icons.account_balance_wallet_outlined,
                          selected: selectedPayment == 'khalti',
                          onTap: () =>
                              setState(() => selectedPayment = 'khalti'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Text(
                'You may also like',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            Obx(() {
              if (productController.isLoading.value &&
                  productController.products.isEmpty) {
                return const SizedBox(
                  height: 210,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final recommendations = recommendedProducts;
              if (recommendations.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'No recommendations available at the moment.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                );
              }
              return SizedBox(
                height: 210,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: recommendations.length,
                  itemBuilder: (context, index) =>
                      buildRecommendedItem(recommendations[index]),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        );
      }),
      bottomNavigationBar: Obx(() {
        if (cartController.items.isEmpty) return const SizedBox.shrink();
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
                        'Rs. ${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isPlacingOrder ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                    ),
                    child: isPlacingOrder
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Checkout'),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 18,
            color: onTap == null ? AppColors.muted : AppColors.primaryDark,
          ),
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.muted),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
