import 'package:get/get.dart';
import '../models/order_by_merchant_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AdminController extends GetxController {
  final ApiService api = ApiService();
  final orders = <OrderModel>[].obs;
  final merchantOrders = <OrderByMerchantModel>[].obs;
  final users = <UserModel>[].obs;
  final isLoading = false.obs;
  final error = ''.obs;

  Future<void> fetchAllOrders() async {
    try {
      isLoading.value = true;
      error.value = '';
      final res = await api.getAllOrders();
      orders.assignAll(res);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMerchantOrders() async {
    try {
      isLoading.value = true;
      error.value = '';
      final res = await api.getMerchantOrders();
      merchantOrders.assignAll(res);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateMerchantOrderStatus(String orderId, String status) async {
    try {
      isLoading.value = true;
      error.value = '';
      final updated = await api.updateMerchantOrderStatus(orderId, status);
      final idx = merchantOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) merchantOrders[idx] = updated;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchAllUsers() async {
    try {
      isLoading.value = true;
      error.value = '';
      final res = await api.getAllUsers();
      users.assignAll(res);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateStatus(String orderId, String status) async {
    try {
      isLoading.value = true;
      error.value = '';
      final updated = await api.updateOrderStatus(orderId, status);
      final idx = orders.indexWhere((o) => o.id == orderId);
      if (idx != -1) orders[idx] = updated;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> payOrderViaCash(String orderId) async {
    try {
      isLoading.value = true;
      error.value = '';
      final updated = await api.payMerchantOrderViaCash(orderId);
      final idx = merchantOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) merchantOrders[idx] = updated;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> payOrderViaKhalti(String orderId) async {
    try {
      isLoading.value = true;
      error.value = '';
      final updated = await api.payMerchantOrderViaKhalti(orderId);
      final idx = merchantOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) merchantOrders[idx] = updated;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      isLoading.value = true;
      error.value = '';
      final updated = await api.cancelOrder(orderId, 'CANCELLED');
      final idx = orders.indexWhere((o) => o.id == orderId);
      if (idx != -1) orders[idx] = updated;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
