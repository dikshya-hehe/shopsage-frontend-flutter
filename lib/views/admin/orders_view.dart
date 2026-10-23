import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/admin_controller.dart';
import '../../models/admin_order_model.dart';
import '../../theme/app_theme.dart';

const _orderStatuses = [
  'PENDING',
  'CONFIRMED',
  'SHIPPED',
  'DELIVERED',
  'CANCELLED',
];

class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  final AdminController controller = Get.find<AdminController>();
  final searchController = TextEditingController();
  String selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.fetchOrders();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<AdminOrderModel> get filteredOrders {
    final query = searchController.text.trim().toLowerCase();
    return controller.orders.where((order) {
      final statusMatch =
          selectedStatus == 'All' ||
          (order.status ?? '').toUpperCase() == selectedStatus;
      final searchMatch = query.isEmpty ||
          (order.orderNumber ?? '').toLowerCase().contains(query) ||
          order.customerName.toLowerCase().contains(query) ||
          order.customerPhone.toLowerCase().contains(query) ||
          order.itemNames.any((name) => name.toLowerCase().contains(query));
      return statusMatch && searchMatch;
    }).toList();
  }

  Color _statusColor(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'CONFIRMED':
        return AppColors.primary;
      case 'SHIPPED':
        return const Color(0xFF1565C0);
      case 'DELIVERED':
        return const Color(0xFF00695C);
      case 'CANCELLED':
        return AppColors.danger;
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.orders.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.fetchOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 28),
          children: [
            Text(
              controller.isAdmin ? 'All orders' : 'Merchant orders',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              controller.isAdmin
                  ? 'Update fulfillment status for every shop order.'
                  : 'Orders that include products you created. Status can be changed by an admin.',
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search order code, customer or product',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final status in ['All', ..._orderStatuses])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(status),
                        selected: selectedStatus == status,
                        onSelected: (_) =>
                            setState(() => selectedStatus = status),
                        showCheckmark: false,
                        selectedColor: AppColors.primarySoft,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: selectedStatus == status
                              ? AppColors.primaryDark
                              : AppColors.text,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (controller.error.value.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                controller.error.value,
                style: const TextStyle(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: 12),
            if (filteredOrders.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(
                  child: Text(
                    'No orders yet',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              )
            else
              ...filteredOrders.map(_orderCard),
          ],
        ),
      );
    });
  }

  Widget _orderCard(AdminOrderModel order) {
    final color = _statusColor(order.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderNumber ?? order.id ?? 'Order',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status ?? 'PENDING',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            order.itemNames.isEmpty ? 'No items listed' : order.itemNames.join(', '),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: AppColors.muted),
              const SizedBox(width: 6),
              Expanded(child: Text(order.customerName)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 16, color: AppColors.muted),
              const SizedBox(width: 6),
              Text(order.customerPhone),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 16, color: AppColors.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text('${order.city}, ${order.country}'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Rs. ${order.totalPrice ?? 0}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                order.paymentLabel,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (controller.isAdmin)
                TextButton.icon(
                  onPressed: () => _updateStatus(order),
                  icon: const Icon(Icons.sync_alt_rounded, size: 18),
                  label: const Text('Update status'),
                ),
              const Spacer(),
              IconButton(
                tooltip: 'Details',
                onPressed: () => _showDetails(order),
                icon: const Icon(Icons.visibility_outlined),
              ),
              if (controller.isAdmin)
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => _deleteOrder(order),
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDetails(AdminOrderModel order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.orderNumber ?? 'Order',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(order.itemNames.join('\n')),
              const SizedBox(height: 12),
              Text('Customer: ${order.customerName}'),
              Text('Phone: ${order.customerPhone}'),
              if (order.customerEmail != '-') Text('Email: ${order.customerEmail}'),
              Text('Ship to: ${order.city}, ${order.province}, ${order.country}'),
              Text('Payment: ${order.paymentLabel}'),
              Text('Total: Rs. ${order.totalPrice ?? 0}'),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateStatus(AdminOrderModel order) async {
    if (order.id == null) return;
    String selected = _orderStatuses.contains(order.status)
        ? order.status!
        : 'PENDING';
    final next = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update status'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return DropdownButtonFormField<String>(
                initialValue: selected,
                items: _orderStatuses
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setDialogState(() => selected = value ?? selected);
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
    if (next == null) return;
    try {
      await controller.updateOrderStatus(order.id!, next);
      AppTheme.snack('Order updated', 'Status is now $next.');
    } catch (error) {
      AppTheme.snack(
        'Could not update order',
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }

  Future<void> _deleteOrder(AdminOrderModel order) async {
    if (order.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete order'),
          content: const Text('Delete this order permanently?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    try {
      await controller.deleteOrder(order.id!);
      AppTheme.snack('Order deleted', 'The order was removed.');
    } catch (error) {
      AppTheme.snack(
        'Could not delete order',
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }
}
