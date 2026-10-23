import 'package:get/get.dart';
import '../models/admin_order_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'auth_controller.dart';

class AdminController extends GetxController {
  final ApiService api = ApiService();
  final orders = <AdminOrderModel>[].obs;
  final users = <UserModel>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final error = ''.obs;

  List<String> get currentRoles {
    final user = Get.find<AuthController>().currentUser.value;
    return user?.roles.map((role) => role.toUpperCase()).toList() ?? [];
  }

  bool get isAdmin {
    return currentRoles.contains('ADMIN') ||
        currentRoles.contains('SUPER_ADMIN');
  }

  bool get isSuperAdmin => currentRoles.contains('SUPER_ADMIN');

  bool get isMerchant => currentRoles.contains('MERCHANT');

  Future<void> fetchOrders({bool showLoader = true}) async {
    try {
      if (showLoader) isLoading.value = true;
      error.value = '';
      final res = isAdmin
          ? await api.getAllOrders()
          : await api.getMerchantOrders();
      orders.assignAll(res);
    } catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (showLoader) isLoading.value = false;
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      isSaving.value = true;
      error.value = '';
      await api.updateOrderStatus(orderId, status);
      await fetchOrders(showLoader: false);
    } catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      isSaving.value = true;
      error.value = '';
      await api.deleteOrder(orderId);
      orders.removeWhere((order) => order.id == orderId);
    } catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> fetchAllUsers({String? query}) async {
    try {
      isLoading.value = true;
      error.value = '';
      final res = await api.getAllUsers(query: query);
      users.assignAll(res);
    } catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateUserRoles(String userId, List<String> roles) async {
    try {
      isSaving.value = true;
      error.value = '';
      final updated = await api.updateUserRoles(userId, roles);
      _replaceUser(updated);
    } catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> updateUser(
    String userId, {
    String? name,
    String? phone,
    bool? isActive,
    Map<String, dynamic>? address,
  }) async {
    try {
      isSaving.value = true;
      error.value = '';
      final updated = await api.updateUser(
        userId,
        name: name,
        phone: phone,
        isActive: isActive,
        address: address,
      );
      _replaceUser(updated);
    } catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      isSaving.value = true;
      error.value = '';
      await api.deleteUser(userId);
      users.removeWhere((user) => user.id == userId);
    } catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      isSaving.value = false;
    }
  }

  void _replaceUser(UserModel updated) {
    final index = users.indexWhere((user) => user.id == updated.id);
    if (index != -1) {
      users[index] = updated;
    }
  }
}
