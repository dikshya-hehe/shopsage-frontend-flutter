class OrderByMerchantModel {
    OrderByMerchantModel({
        required this.id,
        required this.status,
        required this.shippingAddress,
        required this.orderNumber,
        required this.totalPrice,
        required this.payment,
        required this.orderUser,
        required this.orderedProducts,
    });

    final String? id;
    final String? status;
    final ShippingAddress? shippingAddress;
    final String? orderNumber;
    final int? totalPrice;
    final String? payment;
    final OrderUser? orderUser;
    final List<OrderedProduct> orderedProducts;

    factory OrderByMerchantModel.fromJson(Map<String, dynamic> json){ 
        return OrderByMerchantModel(
            id: json["_id"],
            status: json["status"],
            shippingAddress: json["shippingAddress"] == null ? null : ShippingAddress.fromJson(json["shippingAddress"]),
            orderNumber: json["orderNumber"],
            totalPrice: json["totalPrice"],
            payment: json["payment"],
            orderUser: json["orderUser"] == null ? null : OrderUser.fromJson(json["orderUser"]),
            orderedProducts: json["orderedProducts"] == null ? [] : List<OrderedProduct>.from(json["orderedProducts"]!.map((x) => OrderedProduct.fromJson(x))),
        );
    }

}

class OrderUser {
    OrderUser({
        required this.id,
        required this.name,
        required this.phone,
    });

    final String? id;
    final String? name;
    final String? phone;

    factory OrderUser.fromJson(Map<String, dynamic> json){ 
        return OrderUser(
            id: json["_id"],
            name: json["name"],
            phone: json["phone"],
        );
    }

}

class OrderedProduct {
    OrderedProduct({
        required this.id,
        required this.name,
        required this.brand,
        required this.category,
        required this.price,
        required this.imageUrls,
    });

    final String? id;
    final String? name;
    final String? brand;
    final String? category;
    final int? price;
    final List<String> imageUrls;

    factory OrderedProduct.fromJson(Map<String, dynamic> json){ 
        return OrderedProduct(
            id: json["_id"],
            name: json["name"],
            brand: json["brand"],
            category: json["category"],
            price: json["price"],
            imageUrls: json["imageUrls"] == null ? [] : List<String>.from(json["imageUrls"]!.map((x) => x)),
        );
    }

}

class ShippingAddress {
    ShippingAddress({
        required this.city,
        required this.province,
        required this.country,
    });

    final String? city;
    final String? province;
    final String? country;

    factory ShippingAddress.fromJson(Map<String, dynamic> json){ 
        return ShippingAddress(
            city: json["city"],
            province: json["province"],
            country: json["country"],
        );
    }

}
