import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controller/auth_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_network_image.dart';
import '../admin/main_admin.dart';
import 'my_orders_view.dart';

class AccountView extends StatelessWidget {
  const AccountView({super.key});

  String _formatJoinedDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _pickImage(AuthController authController) async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      await authController.updateProfileImage(image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    return Obx(() {
      final user = authController.currentUser.value;
      if (user == null) {
        return const Center(child: Text('No user information available.'));
      }

      final location = user.address != null
          ? '${user.address!.city ?? '-'}, ${user.address!.country ?? '-'}'
          : '-';
      final roles = user.roles.isNotEmpty ? user.roles.join(', ') : 'Customer';
      final rolesUpper = user.roles.map((r) => r.toUpperCase()).toList();
      final hasImage =
          user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty;

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.white,
                      child: ClipOval(
                        child: hasImage
                            ? AppNetworkImage(
                                url: user.profileImageUrl!,
                                width: 96,
                                height: 96,
                              )
                            : CircleAvatar(
                                radius: 46,
                                backgroundColor: AppColors.primarySoft,
                                child: Text(
                                  user.name?.substring(0, 1).toUpperCase() ??
                                      'U',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _pickImage(authController),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  user.name ?? 'Guest User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    roles,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (authController.errorMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              authController.errorMessage.value,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: 18),
          _InfoCard(
            title: 'Profile details',
            rows: [
              _InfoRowData(Icons.phone_outlined, 'Phone', user.phone ?? '-'),
              _InfoRowData(Icons.place_outlined, 'Location', location),
              _InfoRowData(
                Icons.calendar_month_outlined,
                'Joined',
                _formatJoinedDate(user.createdAt),
              ),
              _InfoRowData(
                Icons.verified_outlined,
                'Status',
                user.isActive == true ? 'Active' : 'Inactive',
              ),
              _InfoRowData(Icons.badge_outlined, 'Role', roles),
            ],
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.receipt_long_rounded,
            title: 'My orders',
            subtitle: 'View status and details of orders you placed',
            color: AppColors.primary,
            onTap: () => Get.to(() => const MyOrdersView()),
          ),
          const SizedBox(height: 10),
          if (rolesUpper.contains('ADMIN') ||
              rolesUpper.contains('MERCHANT')) ...[
            _ActionTile(
              icon: Icons.admin_panel_settings_rounded,
              title: 'Admin panel',
              subtitle: 'Manage products, users and orders',
              color: const Color(0xFF455A64),
              onTap: () => Get.to(() => const AdminMain()),
            ),
            const SizedBox(height: 10),
          ],
          _ActionTile(
            icon: Icons.photo_camera_outlined,
            title: 'Change profile picture',
            subtitle: 'Update the photo on your account',
            color: AppColors.primary,
            onTap: () => _pickImage(authController),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.logout_rounded,
            title: 'Logout',
            subtitle: 'Sign out of ShopSage',
            color: AppColors.danger,
            onTap: () async {
              await authController.logout();
              Get.offAllNamed('/login');
            },
          ),
        ],
      );
    });
  }
}

class _InfoRowData {
  const _InfoRowData(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});

  final String title;
  final List<_InfoRowData> rows;

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
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(row.icon, size: 20, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    row.label,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      row.value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
