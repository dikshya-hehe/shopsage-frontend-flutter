import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controller/auth_controller.dart';
import '../../controller/cart_controller.dart';
import '../../controller/product_controller.dart';
import '../../models/product_model.dart';
import '../../services/api_service.dart';

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
    countryController = TextEditingController(text: user?.address?.country ?? 'Nepal');
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

  String _itemKey(ProductModel item) {
    return item.id ?? item.name ?? item.hashCode.toString();
  }

  void _syncCartState() {
    if (!mounted) return;

    final currentKeys = cartController.items.map(_itemKey).toSet();
    for (var item in cartController.items) {
      final key = _itemKey(item);
      selectedItems.putIfAbsent(key, () => true);
      quantities.putIfAbsent(key, () => 1);
    }
    selectedItems.removeWhere((key, _) => !currentKeys.contains(key));
    quantities.removeWhere((key, _) => !currentKeys.contains(key));
    setState(() {});
  }

  double get subtotal {
    return cartController.items.fold(0.0, (sum, item) {
      final key = _itemKey(item);
      if (selectedItems[key] != true) return sum;
      final qty = quantities[key] ?? 1;
      return sum + (item.price ?? 0) * qty;
    });
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
    return cartController.items.isNotEmpty && cartController.items.every((item) => selectedItems[_itemKey(item)] == true);
  }

  Future<void> _placeOrder() async {
    if (cartController.items.isEmpty) {
      Get.snackbar('Cart empty', 'Add some products before placing an order.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final selectedProducts = cartController.items.where((item) => selectedItems[_itemKey(item)] == true).toList();
    if (selectedProducts.isEmpty) {
      Get.snackbar('Select products', 'Please select items to checkout.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (authController.currentUser.value == null) {
      Get.snackbar('Login required', 'Please login to place an order.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final city = cityController.text.trim();
    final province = provinceController.text.trim();
    final country = countryController.text.trim();

    if (city.isEmpty || country.isEmpty) {
      Get.snackbar('Missing details', 'Please enter city and country for delivery.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => isPlacingOrder = true);

    try {
      final navigator = Navigator.of(context);
      final orderItems = selectedProducts.map((product) {
        final qty = quantities[_itemKey(product)] ?? 1;
        return {
          'product': product.id,
          'quantity': qty,
        };
      }).toList();

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
        Get.snackbar('Order placed', 'Your order is confirmed. Pay on delivery.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade700, colorText: Colors.white);
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
          final launched = await launchUrl(Uri.parse(paymentUrl), mode: LaunchMode.externalApplication);
          if (!launched) {
            Get.snackbar('Khalti payment', 'Could not open the Khalti payment page.', snackPosition: SnackPosition.BOTTOM);
          }
        } else {
          Get.snackbar('Khalti payment', 'Payment link was not returned. Please try cash or contact support.', snackPosition: SnackPosition.BOTTOM);
        }
        if (navigator.mounted) {
          navigator.pop();
        }
      }
    } catch (e) {
      if (!mounted) return;
      Get.snackbar('Checkout failed', e.toString().replaceFirst('Exception: ', ''), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      if (mounted) {
        setState(() => isPlacingOrder = false);
      }
    }
  }

  Future<void> _refreshProducts() async {
    try {
      await productController.fetchProducts();
    } catch (_) {
      // Ignore refresh failures, order flow should continue.
    }
  }

  Widget summaryRow(String title, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? Colors.black : Colors.black)),
        ],
      ),
    );
  }

  Widget buildCartItem(ProductModel item) {
    final key = _itemKey(item);
    final qty = quantities[key] ?? 1;
    final imageUrl = item.imageUrls.isNotEmpty ? item.imageUrls.first : 'https://via.placeholder.com/150';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Checkbox(
              value: selectedItems[key] ?? true,
              onChanged: (value) {
                setState(() {
                  selectedItems[key] = value ?? false;
                });
              },
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Variation: ${item.brand ?? item.category ?? 'Standard'}'),
                  const SizedBox(height: 4),
                  Text('Rs. ${item.price ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF070707))),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: qty > 1
                      ? () {
                          setState(() {
                            quantities[key] = qty - 1;
                          });
                        }
                      : null,
                ),
                Text('$qty'),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    setState(() {
                      quantities[key] = qty + 1;
                    });
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => cartController.removeFromCart(item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<ProductModel> get recommendedProducts {
    final cartKeys = cartController.items.map(_itemKey).toSet();
    return productController.products
        .where((product) => !cartKeys.contains(_itemKey(product)))
        .take(6)
        .toList();
  }

  Widget buildRecommendedItem(ProductModel product) {
    final imageUrl = product.imageUrls.isNotEmpty ? product.imageUrls.first : 'https://via.placeholder.com/150';
    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: 150,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 150,
                height: 150,
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(product.name ?? 'Recommended', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('Rs. ${product.price ?? 0}'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: const Text('My Cart', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Obx(() {
        if (cartController.items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  const Text('Your cart is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Add products from the home page to get started.', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  Checkbox(
                    value: allSelected,
                    onChanged: (value) {
                      setState(() {
                        for (var item in cartController.items) {
                          selectedItems[_itemKey(item)] = value ?? false;
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Select All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...cartController.items.map(buildCartItem),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.confirmation_number_outlined, color: Colors.orange),
                      SizedBox(width: 10),
                      Text('Have a promo code?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: promoController,
                          decoration: InputDecoration(
                            hintText: 'CODE10',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade400)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blue, width: 2)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('APPLY', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                leading: const Icon(Icons.local_shipping_outlined),
                title: const Text('Shipping'),
                subtitle: const Text('Standard Delivery'),
                trailing: Text(shipping == 0 ? 'FREE' : 'Rs. ${shipping.toStringAsFixed(0)}'),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Order Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    summaryRow('Subtotal', 'Rs. ${subtotal.toStringAsFixed(0)}'),
                    summaryRow('Shipping', shipping == 0 ? 'FREE' : 'Rs. ${shipping.toStringAsFixed(0)}'),
                    summaryRow('Discount', '-Rs. ${discount.toStringAsFixed(0)}'),
                    const Divider(),
                    summaryRow('Total', 'Rs. ${total.toStringAsFixed(0)}', isBold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delivery details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(controller: cityController, decoration: const InputDecoration(labelText: 'City')), 
                    const SizedBox(height: 10),
                    TextField(controller: provinceController, decoration: const InputDecoration(labelText: 'Province')), 
                    const SizedBox(height: 10),
                    TextField(controller: countryController, decoration: const InputDecoration(labelText: 'Country')), 
                    const SizedBox(height: 16),
                    Text('Payment method', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Cash'),
                          selected: selectedPayment == 'cash',
                          onSelected: (_) => setState(() => selectedPayment = 'cash'),
                          selectedColor: Colors.green.shade100,
                        ),
                        ChoiceChip(
                          label: const Text('Khalti'),
                          selected: selectedPayment == 'khalti',
                          onSelected: (_) => setState(() => selectedPayment = 'khalti'),
                          selectedColor: Colors.orange.shade100,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('You May Also Like', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            Obx(() {
              if (productController.isLoading.value && productController.products.isEmpty) {
                return const SizedBox(
                  height: 250,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final recommendations = recommendedProducts;
              if (recommendations.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('No recommendations available at the moment.'),
                );
              }

              return SizedBox(
                height: 250,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recommendations.length,
                  itemBuilder: (context, index) => buildRecommendedItem(recommendations[index]),
                ),
              );
            }),
            const SizedBox(height: 100),
          ],
        );
      }),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: cartController.items.isEmpty || isPlacingOrder ? null : _placeOrder,
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
          child: isPlacingOrder
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Checkout • Rs. ${total.toStringAsFixed(0)}'),
        ),
      ),
    );
  }
}
