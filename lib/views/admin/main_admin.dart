import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/admin_controller.dart';
import 'orders_view.dart';
import 'businesses_view.dart';
import 'reports_view.dart';
import 'users_view.dart';

class AdminMain extends StatefulWidget {
  const AdminMain({super.key});

  @override
  State<AdminMain> createState() => _AdminMainState();
}

class _AdminMainState extends State<AdminMain> {
  final AdminController controller = Get.put(AdminController());
  int _selectedIndex = 0;
  bool _collapsed = false;

  static const _menuItems = [
    'Orders',
    'Businesses',
    'Reports',
    'Users',
  ];

  Widget _contentForIndex(int idx) {
    switch (idx) {
      case 0:
        return OrdersView();
      case 1:
        return const BusinessesView();
      case 2:
        return const ReportsView();
      case 3:
        return const UsersView();
      default:
        return OrdersView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: Row(
        children: [
          // Sidebar (collapsible)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: _collapsed ? 80 : 220,
            color: Theme.of(context).colorScheme.surfaceVariant,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with toggle
                if (_collapsed)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'Expand',
                      onPressed: () => setState(() => _collapsed = !_collapsed),
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'Admin',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        tooltip: 'Collapse',
                        onPressed: () => setState(() => _collapsed = !_collapsed),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                // Menu
                ...List.generate(_menuItems.length, (i) {
                  final selected = i == _selectedIndex;
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: _collapsed ? 6 : 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedIndex = i),
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        decoration: BoxDecoration(
                          color: selected ? Theme.of(context).colorScheme.primary.withOpacity(0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: _collapsed ? 2 : 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Active indicator
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: 4,
                              height: 36,
                              decoration: BoxDecoration(
                                color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Tooltip(
                              message: _menuItems[i],
                              child: Icon(
                                i == 0
                                    ? Icons.list_alt
                                    : i == 1
                                        ? Icons.storefront
                                        : i == 2
                                            ? Icons.insert_chart_outlined
                                            : Icons.people,
                                color: selected ? Theme.of(context).colorScheme.primary : Colors.black54,
                                size: 20,
                              ),
                            ),
                            if (!_collapsed) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _menuItems[i],
                                  style: TextStyle(
                                    color: selected ? Theme.of(context).colorScheme.primary : Colors.black87,
                                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                if (!_collapsed)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('v1.0', style: TextStyle(color: Colors.grey[600])),
                  ),
              ],
            ),
          ),

          // Divider
          const VerticalDivider(width: 1, thickness: 1),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _contentForIndex(_selectedIndex),
            ),
          ),
        ],
      ),
    );
  }
}
