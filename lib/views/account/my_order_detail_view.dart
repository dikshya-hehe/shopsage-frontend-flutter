import 'package:flutter/material.dart';
import '../../models/my_order_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_network_image.dart';
import 'my_orders_view.dart';

class MyOrderDetailView extends StatefulWidget {
  const MyOrderDetailView({super.key, required this.order});

  final MyOrderModel order;

  @override
  State<MyOrderDetailView> createState() => _MyOrderDetailViewState();
}

class _MyOrderDetailViewState extends State<MyOrderDetailView> {
  late MyOrderModel order;
  bool cancelling = false;

  static const _flow = ['PENDING', 'CONFIRMED', 'SHIPPED', 'DELIVERED'];

  @override
  void initState() {
    super.initState();
    order = widget.order;
  }

  bool get canCancel {
    final status = (order.status ?? '').toUpperCase();
    return status == 'PENDING' || status == 'CONFIRMED';
  }

  Future<void> _cancel() async {
    if (order.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel order'),
          content: const Text('Cancel this order? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep order'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('Cancel order'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    setState(() => cancelling = true);
    try {
      await ApiService().cancelOrder(order.id!, 'CANCELLED');
      if (!mounted) return;
      setState(() {
        order = MyOrderModel(
          id: order.id,
          orderNumber: order.orderNumber,
          status: 'CANCELLED',
          totalPrice: order.totalPrice,
          paymentLabel: order.paymentLabel,
          city: order.city,
          province: order.province,
          country: order.country,
          createdDate: order.createdDate,
          items: order.items,
        );
      });
      AppTheme.snack('Order cancelled', 'This order is no longer being processed.');
    } catch (error) {
      AppTheme.snack(
        'Could not cancel',
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) setState(() => cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = orderStatusColor(order.status);
    final cancelled = (order.status ?? '').toUpperCase() == 'CANCELLED';

    return Scaffold(
      appBar: AppBar(title: const Text('Order details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.shortCode,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
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
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (order.createdDate != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Placed ${order.createdDate!.day}/${order.createdDate!.month}/${order.createdDate!.year}',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
                const SizedBox(height: 18),
                if (cancelled)
                  const Text(
                    'This order was cancelled.',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  _StatusTimeline(current: (order.status ?? 'PENDING').toUpperCase()),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Items',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                if (order.items.isEmpty)
                  const Text(
                    'Item details were not returned for this order.',
                    style: TextStyle(color: AppColors.muted),
                  )
                else
                  for (final item in order.items) _ItemRow(item: item),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _InfoCard(
            title: 'Delivery',
            rows: [
              ('City', order.city),
              ('Province', order.province),
              ('Country', order.country),
            ],
          ),
          const SizedBox(height: 14),
          _InfoCard(
            title: 'Payment',
            rows: [
              ('Method', order.paymentLabel),
              ('Total', 'Rs. ${order.totalPrice ?? 0}'),
            ],
          ),
          if (canCancel) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: cancelling ? null : _cancel,
                icon: cancelling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cancel_outlined),
                label: const Text('Cancel order'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.current});

  final String current;

  static const steps = ['PENDING', 'CONFIRMED', 'SHIPPED', 'DELIVERED'];

  @override
  Widget build(BuildContext context) {
    final index = steps.indexOf(current);
    final activeIndex = index < 0 ? 0 : index;

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: i <= activeIndex
                        ? AppColors.primary
                        : AppColors.border,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    i <= activeIndex ? Icons.check : Icons.circle,
                    size: i <= activeIndex ? 14 : 8,
                    color: i <= activeIndex ? Colors.white : AppColors.muted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  steps[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: i <= activeIndex
                        ? AppColors.primaryDark
                        : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (i < steps.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                color: i < activeIndex ? AppColors.primary : AppColors.border,
              ),
            ),
        ],
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final MyOrderItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AppNetworkImage(url: item.imageUrl, width: 58, height: 58),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  [
                    if (item.brand.isNotEmpty) item.brand,
                    'Qty ${item.quantity}',
                  ].join(' · '),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            'Rs. ${item.lineTotal}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(row.$1, style: const TextStyle(color: AppColors.muted)),
                  const Spacer(),
                  Text(
                    row.$2,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
