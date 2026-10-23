import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/my_order_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_network_image.dart';
import 'my_order_detail_view.dart';

class MyOrdersView extends StatefulWidget {
  const MyOrdersView({super.key});

  @override
  State<MyOrdersView> createState() => _MyOrdersViewState();
}

class _MyOrdersViewState extends State<MyOrdersView> {
  final _api = ApiService();
  final orders = <MyOrderModel>[];
  bool loading = true;
  String error = '';
  String selectedStatus = 'All';

  static const statuses = [
    'All',
    'PENDING',
    'CONFIRMED',
    'SHIPPED',
    'DELIVERED',
    'CANCELLED',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = '';
    });
    try {
      final result = await _api.getMyOrders();
      if (!mounted) return;
      setState(() {
        orders
          ..clear()
          ..addAll(result);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<MyOrderModel> get filtered {
    if (selectedStatus == 'All') return orders;
    return orders
        .where((order) => (order.status ?? '').toUpperCase() == selectedStatus)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: loading && orders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  const Text(
                    'Track every order you have placed.',
                    style: TextStyle(color: AppColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final status in statuses)
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
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(error, style: const TextStyle(color: AppColors.danger)),
                  ],
                  const SizedBox(height: 12),
                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 64),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 56,
                            color: AppColors.muted,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No orders yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'When you checkout, your orders will show up here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filtered.map(_orderCard),
                ],
              ),
            ),
    );
  }

  Widget _orderCard(MyOrderModel order) {
    final color = orderStatusColor(order.status);
    final first = order.items.isNotEmpty ? order.items.first : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () async {
            await Get.to(() => MyOrderDetailView(order: order));
            _load();
          },
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AppNetworkImage(
                        url: first?.imageUrl ?? '',
                        width: 72,
                        height: 72,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            first?.name ?? 'Order',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.items.length > 1
                                ? '${order.items.length} items'
                                : '${first?.quantity ?? 1} item',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Rs. ${order.totalPrice ?? 0}',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.tag_rounded,
                      size: 16,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.shortCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (order.createdDate != null)
                      Text(
                        _formatDate(order.createdDate!),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

Color orderStatusColor(String? status) {
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
