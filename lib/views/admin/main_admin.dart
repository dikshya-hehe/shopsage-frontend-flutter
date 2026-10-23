import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/admin_controller.dart';
import '../../controller/auth_controller.dart';
import '../../theme/app_theme.dart';
import 'orders_view.dart';
import 'businesses_view.dart';
import 'create_product_view.dart';
import 'users_view.dart';

class AdminMain extends StatefulWidget {
  const AdminMain({super.key});

  @override
  State<AdminMain> createState() => _AdminMainState();
}

class _AdminTab {
  const _AdminTab(this.title, this.icon, this.builder);
  final String title;
  final IconData icon;
  final Widget Function() builder;
}

class _AdminMainState extends State<AdminMain> {
  final AdminController controller = Get.put(AdminController());
  int _selectedIndex = 0;

  List<_AdminTab> get _tabs {
    final auth = Get.find<AuthController>().currentUser.value;
    final roles = auth?.roles.map((role) => role.toUpperCase()).toList() ?? [];
    final isAdmin =
        roles.contains('ADMIN') || roles.contains('SUPER_ADMIN');
    final isMerchant = roles.contains('MERCHANT');

    return [
      _AdminTab('Orders', Icons.receipt_long_rounded, () => const OrdersView()),
      if (isMerchant || isAdmin)
        const _AdminTab(
          'Create Product',
          Icons.add_box_outlined,
          CreateProductView.new,
        ),
      if (isAdmin)
        const _AdminTab('Users', Icons.people_alt_outlined, UsersView.new),
      if (isAdmin)
        const _AdminTab(
          'Businesses',
          Icons.storefront_outlined,
          BusinessesView.new,
        ),
    ];
  }

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    final safeIndex = _selectedIndex.clamp(0, tabs.length - 1);
    final current = tabs[safeIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Open admin menu',
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(current.title),
            const Text(
              'ShopSage admin',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.primarySoft,
              child: const Icon(
                Icons.admin_panel_settings_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        width: 292,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 20, 22),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.dashboard_customize_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'ShopSage',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Administration',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 22, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'WORKSPACE',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: tabs.length,
                  itemBuilder: (context, index) {
                    final selected = index == safeIndex;
                    final tab = tabs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        selected: selected,
                        selectedTileColor: AppColors.primarySoft,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: Icon(
                          tab.icon,
                          color: selected
                              ? AppColors.primaryDark
                              : AppColors.muted,
                        ),
                        title: Text(
                          tab.title,
                          style: TextStyle(
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? AppColors.primaryDark
                                : AppColors.text,
                          ),
                        ),
                        trailing: selected
                            ? const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.primary,
                              )
                            : null,
                        onTap: () => _selectTab(index),
                      ),
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, size: 17, color: AppColors.muted),
                    SizedBox(width: 8),
                    Text(
                      'Admin access',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey(safeIndex),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: current.builder(),
          ),
        ),
      ),
    );
  }
}
