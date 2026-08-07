import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_constants.dart';
import '../../controller/auth_controller.dart';
import '../../controller/cart_controller.dart';
import '../../controller/product_controller.dart';
import '../../models/product_model.dart';
import '../account/account_view.dart';
import '../cart/cart_view.dart';
import '../product/product_detail_view.dart';

class LoginView extends StatefulWidget {
  LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  final AuthController authController = Get.put(AuthController());
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shopping_bag_outlined, size: 48, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text(AppConstants.appName, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Welcome back! Sign in to your account', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 28),

                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => obscurePassword = !obscurePassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Obx(() {
                          if (authController.errorMessage.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(authController.errorMessage.value, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                          );
                        }),
                        Obx(() {
                          return ElevatedButton(
                            onPressed: authController.isLoading.value
                                ? null
                                : () async {
                                    await authController.login(emailController.text.trim(), passwordController.text);
                                    if (authController.currentUser.value != null) {
                                      Get.offAll(() => const HomeView());
                                    }
                                  },
                            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                            child: authController.isLoading.value ? const CircularProgressIndicator(color: Colors.white) : const Text('Login'),
                          );
                        }),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Get.to(() => const RegisterView()),
                          child: const Text('Create an account'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController passwordController;
  late final TextEditingController confirmPasswordController;
  final authController = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();
  bool obscurePassword = true;
  bool obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(BuildContext context, {required String label, required IconData prefix, Widget? suffix}) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(prefix),
      suffixIcon: suffix,
      filled: true,
      fillColor: theme.colorScheme.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(title: const Text('Create account'), backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(controller: nameController, decoration: _inputDecoration(context, label: 'Name', prefix: Icons.person_outline), validator: (v) => (v == null || v.trim().length < 3) ? 'Name must be at least 3 characters' : null),
                        const SizedBox(height: 12),
                        TextFormField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: _inputDecoration(context, label: 'Email', prefix: Icons.email_outlined), validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null),
                        const SizedBox(height: 12),
                        TextFormField(controller: phoneController, keyboardType: TextInputType.phone, decoration: _inputDecoration(context, label: 'Phone', prefix: Icons.phone_outlined), validator: (v) => (v == null || v.trim().length < 6) ? 'Enter a valid phone number' : null),
                        const SizedBox(height: 12),
                        TextFormField(controller: passwordController, obscureText: obscurePassword, decoration: _inputDecoration(context, label: 'Password', prefix: Icons.lock_outline, suffix: IconButton(icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => obscurePassword = !obscurePassword))), validator: (value) {
                          if (value == null || value.isEmpty) return 'Password is required';
                          if (value.length < 6) return 'Password must be at least 6 characters';
                          if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) return 'Include at least one lowercase letter';
                          if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) return 'Include at least one uppercase letter';
                          if (!RegExp(r'(?=.*\d)').hasMatch(value)) return 'Include at least one number';
                          if (!RegExp(r'(?=.*[@\$!%*?&])').hasMatch(value)) return 'Include at least one special character';
                          return null;
                        }),
                        const SizedBox(height: 12),
                        TextFormField(controller: confirmPasswordController, obscureText: obscureConfirm, decoration: _inputDecoration(context, label: 'Confirm Password', prefix: Icons.lock_clock_outlined, suffix: IconButton(icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => obscureConfirm = !obscureConfirm))), validator: (v) { if (v != passwordController.text) return 'Passwords do not match'; return null; }),
                        const SizedBox(height: 16),
                        Obx(() {
                          return ElevatedButton(
                            onPressed: authController.isLoading.value
                                ? null
                                : () async {
                                    if (!_formKey.currentState!.validate()) return;
                                    await authController.register({
                                      'name': nameController.text.trim(),
                                      'email': emailController.text.trim(),
                                      'phone': phoneController.text.trim(),
                                      'password': passwordController.text,
                                      'address': {'city': 'Kathmandu', 'country': 'Nepal'},
                                    });
                                    if (authController.currentUser.value != null) Get.offAll(() => const HomeView());
                                  },
                            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                            child: authController.isLoading.value ? const CircularProgressIndicator(color: Colors.white) : const Text('Register'),
                          );
                        }),
                        const SizedBox(height: 12),
                        Obx(() { if (authController.errorMessage.isEmpty) return const SizedBox.shrink(); return Text(authController.errorMessage.value, style: const TextStyle(color: Colors.red)); }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ProductController productController = Get.find<ProductController>();
  final CartController cartController = Get.find<CartController>();
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController searchController = TextEditingController();
  int _selectedIndex = 0;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _searchVisible = false;

  List<ProductModel> get filteredProducts {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return productController.products;
    }
    return productController.products.where((product) {
      final name = product.name?.toLowerCase() ?? '';
      final brand = product.brand?.toLowerCase() ?? '';
      final category = product.category?.toLowerCase() ?? '';
      final description = product.description?.toLowerCase() ?? '';
      return name.contains(query) || brand.contains(query) || category.contains(query) || description.contains(query);
    }).toList();
  }

  List<ProductModel> get carouselProducts {
    final productsWithImages = productController.products.where((p) => p.imageUrls.isNotEmpty).toList();
    if (productsWithImages.length >= 3) {
      return productsWithImages.take(5).toList();
    }
    return productController.products.take(3).toList();
  }

  @override
  void initState() {
    super.initState();
    productController.fetchProducts();
    productController.fetchCategories();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _selectCategory(String category) async {
    setState(() {
      _selectedCategory = category;
      _selectedIndex = 0;
    });
    await productController.fetchProducts(category: category == 'All' ? null : category);
  }

  Widget _buildHomePage() {
    return Obx(() {
      final carouselItems = carouselProducts;
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
        if (_searchVisible)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search products, brands, categories',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
        if (carouselItems.isNotEmpty)
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CarouselSlider.builder(
                  itemCount: carouselItems.length,
                  itemBuilder: (context, index, realIndex) {
                    final product = carouselItems[index];
                    final imageUrl = product.imageUrls.first;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300])),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            bottom: 16,
                            right: 16,
                            child: Text(
                              product.name ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  options: CarouselOptions(
                    height: 180,
                    viewportFraction: 0.88,
                    enlargeCenterPage: true,
                    enableInfiniteScroll: carouselItems.length > 1,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
          Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            final categories = productController.categories;
            final items = ['All', ...categories];
            return Wrap(
              spacing: 8,
              children: items.map((category) {
                final selected = category == _selectedCategory;
                return ChoiceChip(
                  label: Text(category),
                  selected: selected,
                  onSelected: (_) => _selectCategory(category),
                  selectedColor: Colors.green.shade100,
                );
              }).toList(),
            );
          }),
        ),
        Obx(() {
          if (productController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (filteredProducts.isEmpty) {
            return const Center(child: Text('No products available yet'));
          }
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      GestureDetector(
                        onTap: () => Get.to(() => ProductDetailView(product: product)),
                        child: SizedBox(
                          height: 120,
                          width: double.infinity,
                          child: Stack(
                            children: [
                              product.imageUrls.isNotEmpty
                                  ? Image.network(
                                      product.imageUrls.first,
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(height: 120, width: double.infinity, color: Colors.grey[200], child: const Center(child: Text('No image'))),
                              if ((product.stock ?? 0) == 0)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Out of stock',
                                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Flexible(
                        fit: FlexFit.loose,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.name ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(product.category ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text('Rs. ${product.price}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                                  ),
                                  Builder(builder: (context) {
                                    final outOfStock = (product.stock ?? 0) == 0;
                                    return Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: outOfStock ? Colors.grey[400] : Colors.green.shade700,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        padding: const EdgeInsets.all(6),
                                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                        onPressed: outOfStock
                                            ? null
                                            : () {
                                                cartController.addToCart(product);
                                                Get.snackbar(
                                                  'Added to cart',
                                                  '${product.name ?? 'Product'} has been added.',
                                                  snackPosition: SnackPosition.BOTTOM,
                                                  backgroundColor: Colors.green.shade700,
                                                  colorText: Colors.white,
                                                );
                                              },
                                        icon: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 18),
                                        tooltip: outOfStock ? 'Out of stock' : 'Add to cart',
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  });
  }

  Widget _buildCategoryPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Browse categories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Tap a category to filter products on the home page.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          Obx(() {
            final categories = productController.categories;
            if (productController.isLoading.value && categories.isEmpty) {
              return const Expanded(child: Center(child: CircularProgressIndicator()));
            }
            final items = ['All', ...categories];
            return Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final category = items[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      title: Text(category),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _selectCategory(category),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomePage(),
      _buildCategoryPage(),
      const AccountView(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            onPressed: () => setState(() {
              _searchVisible = !_searchVisible;
              if (!_searchVisible) {
                _searchQuery = '';
                searchController.clear();
              }
            }),
            icon: Icon(_searchVisible ? Icons.close : Icons.search),
          ),
          Obx(
            () {
              final count = cartController.itemCount;
              return Stack(
                alignment: Alignment.topRight,
                clipBehavior: Clip.none,
                children: [
                  IconButton(onPressed: () => Get.to(() => const CartView()), icon: const Icon(Icons.shopping_cart_outlined)),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        child: Text(
                          '$count',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}
