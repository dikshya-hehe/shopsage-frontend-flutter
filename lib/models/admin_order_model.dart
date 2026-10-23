class AdminOrderModel {
  AdminOrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalPrice,
    required this.paymentLabel,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.itemNames,
    required this.city,
    required this.province,
    required this.country,
    required this.createdDate,
  });

  final String? id;
  final String? orderNumber;
  final String? status;
  final int? totalPrice;
  final String paymentLabel;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final List<String> itemNames;
  final String city;
  final String province;
  final String country;
  final DateTime? createdDate;

  factory AdminOrderModel.fromJson(Map<String, dynamic> json) {
    String customerName = '-';
    String customerPhone = '-';
    String customerEmail = '-';

    final user = json['user'];
    final orderUser = json['orderUser'];
    if (user is Map<String, dynamic>) {
      customerName = user['name']?.toString() ?? '-';
      customerPhone = user['phone']?.toString() ?? '-';
      customerEmail = user['email']?.toString() ?? '-';
    } else if (orderUser is Map<String, dynamic>) {
      customerName = orderUser['name']?.toString() ?? '-';
      customerPhone = orderUser['phone']?.toString() ?? '-';
      customerEmail = orderUser['email']?.toString() ?? '-';
    }

    final itemNames = <String>[];
    final orderItems = json['orderItems'];
    final orderedProducts = json['orderedProducts'];
    if (orderItems is List) {
      for (final item in orderItems) {
        if (item is! Map) continue;
        final product = item['product'];
        final qty = item['quantity'];
        if (product is Map) {
          final name = product['name']?.toString() ?? 'Item';
          itemNames.add(qty == null ? name : '$name × $qty');
        }
      }
    } else if (orderedProducts is List) {
      for (final product in orderedProducts) {
        if (product is Map) {
          itemNames.add(product['name']?.toString() ?? 'Item');
        }
      }
    }

    final shipping = json['shippingAddress'];
    String city = '-';
    String province = '-';
    String country = '-';
    if (shipping is Map<String, dynamic>) {
      city = shipping['city']?.toString() ?? '-';
      province = shipping['province']?.toString() ?? '-';
      country = shipping['country']?.toString() ?? '-';
    }

    return AdminOrderModel(
      id: json['_id']?.toString(),
      orderNumber: json['orderNumber']?.toString(),
      status: json['status']?.toString(),
      totalPrice: json['totalPrice'] is int
          ? json['totalPrice'] as int
          : int.tryParse('${json['totalPrice'] ?? ''}'),
      paymentLabel: _paymentLabel(json['payment']),
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      itemNames: itemNames,
      city: city,
      province: province,
      country: country,
      createdDate: DateTime.tryParse(
        json['createdDate']?.toString() ?? json['createdAt']?.toString() ?? '',
      ),
    );
  }

  static String _paymentLabel(dynamic payment) {
    if (payment == null || payment == '') return 'Unpaid';
    if (payment is Map<String, dynamic>) {
      final method = payment['method']?.toString();
      final status = payment['status']?.toString();
      if (method != null && method.isNotEmpty) {
        return status == null || status.isEmpty ? method : '$method · $status';
      }
      return 'Paid';
    }
    return 'Paid';
  }
}
