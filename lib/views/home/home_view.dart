import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_constants.dart';
import '../../controller/cart_controller.dart';
import '../../controller/product_controller.dart';
import '../../theme/app_theme.dart';
import '../account/account_view.dart';
import '../cart/cart_view.dart';
import 'category_tab.dart';
import 'home_tab.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ProductController productController = Get.find<ProductController>();
  final CartController cartController = Get.find<CartController>();
  final TextEditingController searchController = TextEditingController();
  int _selectedIndex = 0;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _searchVisible = false;

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
    await productController.fetchProducts(
      category: category == 'All' ? null : category,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeTab(
        searchVisible: _searchVisible,
        searchController: searchController,
        searchQuery: _searchQuery,
        onSearchChanged: (value) => setState(() => _searchQuery = value),
        selectedCategory: _selectedCategory,
        onSelectCategory: _selectCategory,
      ),
      CategoryTab(
        selectedCategory: _selectedCategory,
        onSelectCategory: _selectCategory,
      ),
      const AccountView(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.shopping_bag_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(AppConstants.appName),
          ],
        ),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              tooltip: _searchVisible ? 'Close search' : 'Search',
              onPressed: () => setState(() {
                _searchVisible = !_searchVisible;
                if (!_searchVisible) {
                  _searchQuery = '';
                  searchController.clear();
                }
              }),
              icon: Icon(
                _searchVisible ? Icons.close_rounded : Icons.search_rounded,
              ),
            ),
          Obx(() {
            final count = cartController.itemCount;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: 'Cart',
                onPressed: () => Get.to(() => const CartView()),
                icon: Badge(
                  isLabelVisible: count > 0,
                  backgroundColor: AppColors.accent,
                  label: Text('$count'),
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
              ),
            );
          }),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
