import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/admin_controller.dart';
import '../../models/order_by_merchant_model.dart';

class OrdersView extends StatefulWidget {
  OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  final AdminController controller = Get.find<AdminController>();

  @override
  void initState() {
    super.initState();
    controller.fetchMerchantOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
      if (controller.error.isNotEmpty) return Center(child: Text(controller.error.value));
      final orders = controller.merchantOrders;
      if (orders.isEmpty) return const Center(child: Text('No orders yet'));
      return RefreshIndicator(
        onRefresh: controller.fetchMerchantOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
                columns: const [
                  DataColumn(label: Text('Order')),
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('Items')),
                  DataColumn(label: Text('Total')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Payment')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: orders.map((order) {
                  return DataRow(cells: [
                    DataCell(Text(order.orderNumber ?? order.id ?? '-')),
                    DataCell(Text(order.orderUser?.name ?? '-')),
                    DataCell(Text('${order.orderedProducts.length}')),
                    DataCell(Text('Rs. ${order.totalPrice ?? 0}')),
                    DataCell(Text(order.status ?? '-')),
                    DataCell(Text(order.payment ?? '-')),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => _showStatusDialog(context, order),
                          child: const Text('Update'),
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showStatusDialog(BuildContext context, OrderByMerchantModel order) {
    showDialog(
      context: context,
      builder: (context) {
        final statuses = [
          'PENDING',
          'PROCESSING',
          'SHIPPED',
          'DELIVERED',
          'CONFIRMED',
          'CANCELLED',
        ];
        String selected = statuses.contains(order.status) ? order.status! : 'PENDING';
        return AlertDialog(
          title: const Text('Update Status'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButtonFormField<String>(
                value: selected,
                items: statuses
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    selected = v ?? selected;
                  });
                },
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await controller.updateMerchantOrderStatus(order.id ?? '', selected);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}
