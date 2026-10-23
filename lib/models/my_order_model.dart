class MyOrderItem {
  const MyOrderItem({
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  final String name;
  final String brand;
  final String category;
  final int price;
  final int quantity;
  final String imageUrl;

  int get lineTotal => price * quantity;
}

class MyOrderModel {
  MyOrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalPrice,
    required this.paymentLabel,
    required this.city,
    required this.province,
    required this.country,
    required this.createdDate,
    required this.items,
  });

  final String? id;
  final String? orderNumber;
  final String? status;
  final int? totalPrice;
  final String paymentLabel;
  final String city;
  final String province;
  final String country;
  final DateTime? createdDate;
  final List<MyOrderItem> items;

  String get shortCode {
    final code = orderNumber ?? id ?? '';
    if (code.length <= 10) return code;
    return '${code.substring(0, 8)}…';
  }

  factory MyOrderModel.fromJson(Map<String, dynamic> json) {
    final items = <MyOrderItem>[];
    final orderItems = json['orderItems'];
    if (orderItems is List) {
      for (final item in orderItems) {
        if (item is! Map) continue;
        final product = item['product'];
        final quantity = item['quantity'] is int
            ? item['quantity'] as int
            : int.tryParse('${item['quantity'] ?? 1}') ?? 1;
        if (product is Map) {
          final images = product['imageUrls'];
          items.add(
            MyOrderItem(
              name: product['name']?.toString() ?? 'Item',
              brand: product['brand']?.toString() ?? '',
              category: product['category']?.toString() ?? '',
              price: product['price'] is int
                  ? product['price'] as int
                  : int.tryParse('${product['price'] ?? 0}') ?? 0,
              quantity: quantity,
              imageUrl: images is List && images.isNotEmpty
                  ? images.first.toString()
                  : '',
            ),
          );
        }
      }
    }

    final shipping = json['shippingAddress'];
    return MyOrderModel(
      id: json['_id']?.toString(),
      orderNumber: json['orderNumber']?.toString(),
      status: json['status']?.toString(),
      totalPrice: json['totalPrice'] is int
          ? json['totalPrice'] as int
          : int.tryParse('${json['totalPrice'] ?? ''}'),
      paymentLabel: _paymentLabel(json['payment']),
      city: shipping is Map ? shipping['city']?.toString() ?? '-' : '-',
      province: shipping is Map ? shipping['province']?.toString() ?? '-' : '-',
      country: shipping is Map ? shipping['country']?.toString() ?? '-' : '-',
      createdDate: DateTime.tryParse(
        json['createdDate']?.toString() ?? json['createdAt']?.toString() ?? '',
      ),
      items: items,
    );
  }

  static String _paymentLabel(dynamic payment) {
    if (payment == null || payment == '') return 'Unpaid';
    if (payment is Map) {
      final method = payment['method']?.toString();
      if (method != null && method.isNotEmpty) return method;
      return 'Paid';
    }
    return 'Paid';
  }
}
