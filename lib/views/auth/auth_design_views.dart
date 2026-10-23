import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_constants.dart';
import '../../controller/auth_controller.dart';
import '../home/home_view.dart';

const double _maxAuthWidth = 480;

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > _maxAuthWidth;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: Container(
          width: wide ? _maxAuthWidth : double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background2.png'),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.height,
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final double height;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned(
            left: 24,
            top: 0,
            width: 78,
            height: 190,
            child: FadeInUp(
              duration: const Duration(milliseconds: 800),
              child: const Image(
                image: AssetImage('assets/images/light-1.png'),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            left: 132,
            top: 0,
            width: 76,
            height: 145,
            child: FadeInUp(
              duration: const Duration(milliseconds: 1000),
              child: const Image(
                image: AssetImage('assets/images/light-2.png'),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            right: 30,
            top: 30,
            width: 78,
            height: 145,
            child: FadeInUp(
              duration: const Duration(milliseconds: 1100),
              child: const Image(
                image: AssetImage('assets/images/clock.png'),
                fit: BoxFit.contain,
              ),
            ),
          ),
          if (showBack)
            Positioned(
              top: 42,
              left: 10,
              child: FadeInLeft(
                duration: const Duration(milliseconds: 800),
                child: IconButton(
                  onPressed: Get.back,
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: FadeInUp(
              duration: const Duration(milliseconds: 1300),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 38),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: 54),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 31,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final authController = Get.find<AuthController>();
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || !RegExp(r'^[\w.\-]+@[\w.\-]+\.\w+$').hasMatch(email)) {
      _showError('Please enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      _showError('Please enter your password.');
      return;
    }
    if (authController.isLoading.value) return;
    await authController.login(email, password);
    if (mounted && authController.currentUser.value != null) {
      Get.offAll(() => const HomeView());
    }
  }

  void _showError(String message) => Get.snackbar(
    'Login',
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: Colors.red.shade600,
    colorText: Colors.white,
    margin: const EdgeInsets.all(16),
    borderRadius: 12,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: false,
        bottom: false,
        child: _AuthBackdrop(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              children: [
                _AuthHeader(
                  title: AppConstants.appName.isEmpty
                      ? 'Welcome'
                      : AppConstants.appName,
                  subtitle: 'Welcome back!',
                  icon: Icons.shopping_bag_outlined,
                  height: MediaQuery.sizeOf(context).width > _maxAuthWidth
                      ? 340
                      : 370,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 18,
                  ),
                  child: Column(
                    children: [
                      FadeInUp(
                        duration: const Duration(milliseconds: 1500),
                        child: _buildForm(),
                      ),
                      const SizedBox(height: 18),
                      _buildError(),
                      const SizedBox(height: 8),
                      _buildButton(),
                      const SizedBox(height: 22),
                      FadeInUp(
                        duration: const Duration(milliseconds: 1800),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account?",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Get.to(() => const RegisterView()),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .93),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E7D32)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(46, 125, 50, .2),
            blurRadius: 25,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          _field(
            emailController,
            'Email Address',
            Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            action: TextInputAction.next,
          ),
          const Divider(height: 1, color: Color(0xFF2E7D32)),
          _field(
            passwordController,
            'Password',
            Icons.lock_outline,
            obscure: obscurePassword,
            action: TextInputAction.done,
            onSubmitted: (_) => _login(),
            suffix: IconButton(
              onPressed: () =>
                  setState(() => obscurePassword = !obscurePassword),
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool obscure = false,
    TextInputType? keyboardType,
    TextInputAction? action,
    ValueChanged<String>? onSubmitted,
    Widget? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        textInputAction: action,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
          suffixIcon: suffix,
        ),
      ),
    );
  }

  Widget _buildError() => Obx(
    () => authController.errorMessage.isEmpty
        ? const SizedBox.shrink()
        : Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              authController.errorMessage.value,
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
  );

  Widget _buildButton() => Obx(
    () => SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: authController.isLoading.value ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: authController.isLoading.value
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Sign In',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    ),
  );
}

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final authController = Get.find<AuthController>();
  bool obscurePassword = true;
  bool obscureConfirm = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) =>
      value == null || value.trim().length < 3
      ? 'Name must be at least 3 characters'
      : null;
  String? _validateEmail(String? value) =>
      value == null ||
          !RegExp(r'^[\w.\-]+@[\w.\-]+\.\w+$').hasMatch(value.trim())
      ? 'Enter a valid email address'
      : null;
  String? _validatePhone(String? value) =>
      value == null || value.trim().length < 6
      ? 'Enter a valid phone number'
      : null;
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Include a lowercase letter';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Include an uppercase letter';
    if (!RegExp(r'\d').hasMatch(value)) return 'Include a number';
    if (!RegExp(r'[@\$!%*?&]').hasMatch(value)) {
      return 'Include a special character';
    }
    return null;
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!formKey.currentState!.validate() || authController.isLoading.value) {
      return;
    }
    await authController.register({
      'name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'phone': phoneController.text.trim(),
      'password': passwordController.text,
      'address': {'city': 'Kathmandu', 'country': 'Nepal'},
    });
    if (mounted && authController.currentUser.value != null) {
      Get.offAll(() => const HomeView());
    }
  }

  @override
  Widget build(BuildContext context) {
    final fields = [
      _input(
        nameController,
        'Full Name',
        Icons.person_outline,
        _validateName,
        keyboard: TextInputType.name,
      ),
      _input(
        emailController,
        'Email Address',
        Icons.email_outlined,
        _validateEmail,
        keyboard: TextInputType.emailAddress,
      ),
      _input(
        phoneController,
        'Phone Number',
        Icons.phone_outlined,
        _validatePhone,
        keyboard: TextInputType.phone,
      ),
      _input(
        passwordController,
        'Password',
        Icons.lock_outline,
        _validatePassword,
        obscure: obscurePassword,
        suffix: IconButton(
          onPressed: () => setState(() => obscurePassword = !obscurePassword),
          icon: Icon(
            obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
      ),
      _input(
        confirmPasswordController,
        'Confirm Password',
        Icons.lock_clock_outlined,
        (value) =>
            value != passwordController.text ? 'Passwords do not match' : null,
        obscure: obscureConfirm,
        onSubmitted: (_) => _register(),
        suffix: IconButton(
          onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
          icon: Icon(
            obscureConfirm
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
      ),
    ];
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: false,
        bottom: false,
        child: _AuthBackdrop(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              children: [
                _AuthHeader(
                  title: 'Create Account',
                  subtitle: 'Join us and get started',
                  icon: Icons.person_add_alt_1_outlined,
                  height: MediaQuery.sizeOf(context).width > _maxAuthWidth
                      ? 300
                      : 330,
                  showBack: true,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 18,
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        FadeInUp(
                          duration: const Duration(milliseconds: 1300),
                          child: _buildRegisterCard(fields),
                        ),
                        const SizedBox(height: 18),
                        _buildError(),
                        const SizedBox(height: 8),
                        _buildRegisterButton(),
                        const SizedBox(height: 18),
                        TextButton(
                          onPressed: Get.back,
                          child: const Text(
                            'Already have an account? Sign In',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
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

  Widget _input(
    TextEditingController controller,
    String hint,
    IconData icon,
    String? Function(String?) validator, {
    bool obscure = false,
    TextInputType? keyboard,
    Widget? suffix,
    ValueChanged<String>? onSubmitted,
  }) => TextFormField(
    controller: controller,
    obscureText: obscure,
    keyboardType: keyboard,
    onFieldSubmitted: onSubmitted,
    validator: validator,
    style: const TextStyle(color: Colors.black87),
    decoration: InputDecoration(
      border: InputBorder.none,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade600),
      prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
      suffixIcon: suffix,
    ),
  );

  Widget _buildRegisterCard(List<Widget> fields) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .93),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF2E7D32)),
      boxShadow: const [
        BoxShadow(
          color: Color.fromRGBO(46, 125, 50, .2),
          blurRadius: 25,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: Column(
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          fields[i],
          if (i < fields.length - 1)
            const Divider(height: 1, color: Color(0xFF2E7D32)),
        ],
      ],
    ),
  );

  Widget _buildError() {
    return Obx(() {
      if (authController.errorMessage.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          authController.errorMessage.value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    });
  }

  Widget _buildRegisterButton() {
    return Obx(() {
      final loading = authController.isLoading.value;
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: loading ? null : _register,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: loading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add_alt_1_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Create Account',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
        ),
      );
    });
  }
}
