import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_constants.dart';
import '../../controller/auth_controller.dart';
import '../home/home_view.dart';

class LegacyLoginView extends StatefulWidget {
  const LegacyLoginView({super.key});

  @override
  State<LegacyLoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LegacyLoginView> {
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  final AuthController authController = Get.put(AuthController());
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppConstants.appName,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Welcome back! Sign in to your account',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => obscurePassword = !obscurePassword,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Obx(() {
                          if (authController.errorMessage.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              authController.errorMessage.value,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }),
                        Obx(() {
                          return ElevatedButton(
                            onPressed: authController.isLoading.value
                                ? null
                                : () async {
                                    await authController.login(
                                      emailController.text.trim(),
                                      passwordController.text,
                                    );
                                    if (authController.currentUser.value !=
                                        null) {
                                      Get.offAll(() => const HomeView());
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: authController.isLoading.value
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text('Login'),
                          );
                        }),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () =>
                              Get.to(() => const LegacyRegisterView()),
                          child: const Text('Create an account'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LegacyRegisterView extends StatefulWidget {
  const LegacyRegisterView({super.key});

  @override
  State<LegacyRegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<LegacyRegisterView> {
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController passwordController;
  late final TextEditingController confirmPasswordController;
  final authController = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();
  bool obscurePassword = true;
  bool obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required IconData prefix,
    Widget? suffix,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(prefix),
      suffixIcon: suffix,
      filled: true,
      fillColor: theme.colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Create account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: _inputDecoration(
                            context,
                            label: 'Name',
                            prefix: Icons.person_outline,
                          ),
                          validator: (v) => (v == null || v.trim().length < 3)
                              ? 'Name must be at least 3 characters'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration(
                            context,
                            label: 'Email',
                            prefix: Icons.email_outlined,
                          ),
                          validator: (v) => (v == null || !v.contains('@'))
                              ? 'Enter a valid email'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: _inputDecoration(
                            context,
                            label: 'Phone',
                            prefix: Icons.phone_outlined,
                          ),
                          validator: (v) => (v == null || v.trim().length < 6)
                              ? 'Enter a valid phone number'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          decoration: _inputDecoration(
                            context,
                            label: 'Password',
                            prefix: Icons.lock_outline,
                            suffix: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => obscurePassword = !obscurePassword,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
                              return 'Include at least one lowercase letter';
                            }
                            if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
                              return 'Include at least one uppercase letter';
                            }
                            if (!RegExp(r'(?=.*\d)').hasMatch(value)) {
                              return 'Include at least one number';
                            }
                            if (!RegExp(r'(?=.*[@\$!%*?&])').hasMatch(value)) {
                              return 'Include at least one special character';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirm,
                          decoration: _inputDecoration(
                            context,
                            label: 'Confirm Password',
                            prefix: Icons.lock_clock_outlined,
                            suffix: IconButton(
                              icon: Icon(
                                obscureConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => obscureConfirm = !obscureConfirm,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v != passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Obx(() {
                          return ElevatedButton(
                            onPressed: authController.isLoading.value
                                ? null
                                : () async {
                                    if (!_formKey.currentState!.validate()) {
                                      return;
                                    }
                                    await authController.register({
                                      'name': nameController.text.trim(),
                                      'email': emailController.text.trim(),
                                      'phone': phoneController.text.trim(),
                                      'password': passwordController.text,
                                      'address': {
                                        'city': 'Kathmandu',
                                        'country': 'Nepal',
                                      },
                                    });
                                    if (authController.currentUser.value !=
                                        null) {
                                      Get.offAll(() => const HomeView());
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: authController.isLoading.value
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text('Register'),
                          );
                        }),
                        const SizedBox(height: 12),
                        Obx(() {
                          if (authController.errorMessage.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            authController.errorMessage.value,
                            style: const TextStyle(color: Colors.red),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

