import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'constants/app_constants.dart';
import 'controller/auth_controller.dart';
import 'controller/cart_controller.dart';
import 'controller/product_controller.dart';
import 'theme/app_theme.dart';
import 'views/auth/auth_design_views.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  Get.put(AuthController());
  Get.put(CartController());
  Get.put(ProductController());
  runApp(const ShopSageApp());
}

class ShopSageApp extends StatelessWidget {
  const ShopSageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: '/login',
      getPages: [GetPage(name: '/login', page: () => const LoginView())],
    );
  }
}
