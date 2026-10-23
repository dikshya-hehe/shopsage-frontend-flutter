import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/admin_controller.dart';
import '../../controller/auth_controller.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_network_image.dart';

const _assignableRoles = ['CUSTOMER', 'MERCHANT', 'ADMIN', 'SUPER_ADMIN'];

class UsersView extends StatefulWidget {
  const UsersView({super.key});

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  final AdminController controller = Get.find<AdminController>();
  final searchController = TextEditingController();
  String selectedStatus = 'All';
  String selectedRole = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.fetchAllUsers();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<UserModel> get filteredUsers {
    final query = searchController.text.trim().toLowerCase();
    return controller.users.where((user) {
      final roles = user.roles.map((role) => role.toUpperCase()).toList();
      final status = (user.isActive ?? false) ? 'Active' : 'Inactive';
      final roleMatch =
          selectedRole == 'All' || roles.contains(selectedRole);
      final statusMatch = selectedStatus == 'All' || status == selectedStatus;
      final searchMatch = query.isEmpty ||
          (user.name?.toLowerCase().contains(query) ?? false) ||
          (user.email?.toLowerCase().contains(query) ?? false) ||
          (user.phone?.toLowerCase().contains(query) ?? false) ||
          roles.any((role) => role.toLowerCase().contains(query));
      return roleMatch && statusMatch && searchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.users.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.fetchAllUsers,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 28),
          children: [
            const Text(
              'Users',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Search accounts and change roles. Admin and Super Admin can only be assigned by a Super Admin.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search by name, email, phone or role',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _FilterChip(
                  label: selectedRole == 'All' ? 'All roles' : selectedRole,
                  icon: Icons.badge_outlined,
                  onTap: _pickRoleFilter,
                ),
                _FilterChip(
                  label: selectedStatus == 'All'
                      ? 'All status'
                      : selectedStatus,
                  icon: Icons.toggle_on_outlined,
                  onTap: _pickStatusFilter,
                ),
              ],
            ),
            if (controller.error.value.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                controller.error.value,
                style: const TextStyle(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: 16),
            if (filteredUsers.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(
                  child: Text(
                    'No users match your filters.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              )
            else
              ...filteredUsers.map(
                (user) => _UserCard(
                  user: user,
                  onView: () => _showUserDetails(user),
                  onEdit: () => _editUser(user),
                  onRoles: () => _changeRoles(user),
                  onToggleActive: () => _toggleActive(user),
                  onDelete: () => _confirmDelete(user),
                ),
              ),
          ],
        ),
      );
    });
  }

  Future<void> _pickRoleFilter() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return _OptionSheet(
          title: 'Filter by role',
          options: const ['All', ..._assignableRoles],
          selected: selectedRole,
        );
      },
    );
    if (value != null) setState(() => selectedRole = value);
  }

  Future<void> _pickStatusFilter() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return _OptionSheet(
          title: 'Filter by status',
          options: const ['All', 'Active', 'Inactive'],
          selected: selectedStatus,
        );
      },
    );
    if (value != null) setState(() => selectedStatus = value);
  }

  void _showUserDetails(UserModel user) {
    final location = user.address == null
        ? '-'
        : '${user.address!.city ?? '-'}, ${user.address!.country ?? '-'}';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                user.name ?? 'User',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _DetailRow('Email', user.email ?? '-'),
              _DetailRow('Phone', user.phone ?? '-'),
              _DetailRow('Location', location),
              _DetailRow(
                'Roles',
                user.roles.isEmpty ? 'CUSTOMER' : user.roles.join(', '),
              ),
              _DetailRow(
                'Status',
                (user.isActive ?? false) ? 'Active' : 'Inactive',
              ),
              _DetailRow(
                'Joined',
                user.createdAt == null
                    ? '-'
                    : '${user.createdAt!.year}-${user.createdAt!.month.toString().padLeft(2, '0')}-${user.createdAt!.day.toString().padLeft(2, '0')}',
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _changeRoles(UserModel user) async {
    final currentUser = Get.find<AuthController>().currentUser.value;
    final selected = user.roles.map((role) => role.toUpperCase()).toSet();
    if (selected.isEmpty) selected.add('CUSTOMER');

    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Change roles'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name ?? user.email ?? 'User',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _assignableRoles.map((role) {
                      final locked = (role == 'ADMIN' || role == 'SUPER_ADMIN') &&
                          !controller.isSuperAdmin;
                      final checked = selected.contains(role);
                      return FilterChip(
                        label: Text(
                          role,
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        selected: checked,
                        selectedColor: AppColors.primarySoft,
                        checkmarkColor: AppColors.primaryDark,
                        labelStyle: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: locked
                            ? null
                            : (value) {
                                setDialogState(() {
                                  if (value) {
                                    selected.add(role);
                                  } else {
                                    selected.remove(role);
                                  }
                                });
                              },
                      );
                    }).toList(),
                  ),
                  if (!controller.isSuperAdmin) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Only a Super Admin can assign Admin or Super Admin.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final roles = selected.toList();
                    if (roles.isEmpty) roles.add('CUSTOMER');
                    Navigator.pop(context, roles);
                  },
                  child: const Text('Save roles'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || user.id == null) return;
    if (user.id == currentUser?.id &&
        controller.isAdmin &&
        !result.contains('ADMIN') &&
        !result.contains('SUPER_ADMIN')) {
      AppTheme.snack(
        'Roles',
        'You cannot remove your own admin access.',
        error: true,
      );
      return;
    }

    try {
      await controller.updateUserRoles(user.id!, result);
      AppTheme.snack('Roles updated', '${user.name ?? 'User'} is now ${result.join(', ')}.');
    } catch (error) {
      AppTheme.snack('Could not update roles', error.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  Future<void> _editUser(UserModel user) async {
    final nameController = TextEditingController(text: user.name ?? '');
    final phoneController = TextEditingController(text: user.phone ?? '');
    final cityController = TextEditingController(text: user.address?.city ?? '');
    final countryController = TextEditingController(
      text: user.address?.country ?? 'Nepal',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit user'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(labelText: 'City'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: countryController,
                  decoration: const InputDecoration(labelText: 'Country'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved != true || user.id == null) {
      nameController.dispose();
      phoneController.dispose();
      cityController.dispose();
      countryController.dispose();
      return;
    }

    try {
      await controller.updateUser(
        user.id!,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        address: {
          'city': cityController.text.trim(),
          'country': countryController.text.trim(),
        },
      );
      AppTheme.snack('User updated', '${user.name ?? 'User'} was saved.');
    } catch (error) {
      AppTheme.snack(
        'Could not update user',
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      nameController.dispose();
      phoneController.dispose();
      cityController.dispose();
      countryController.dispose();
    }
  }

  Future<void> _toggleActive(UserModel user) async {
    if (user.id == null) return;
    final next = !(user.isActive ?? false);
    try {
      await controller.updateUser(user.id!, isActive: next);
      AppTheme.snack(
        next ? 'User activated' : 'User deactivated',
        '${user.name ?? 'User'} is now ${next ? 'active' : 'inactive'}.',
      );
    } catch (error) {
      AppTheme.snack(
        'Could not update status',
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }

  Future<void> _confirmDelete(UserModel user) async {
    final currentId = Get.find<AuthController>().currentUser.value?.id;
    if (user.id == currentId) {
      AppTheme.snack('Delete blocked', 'You cannot delete your own account.', error: true);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete user'),
          content: Text('Delete ${user.name ?? user.email ?? 'this user'}? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || user.id == null) return;
    try {
      await controller.deleteUser(user.id!);
      AppTheme.snack('User deleted', '${user.name ?? 'User'} was removed.');
    } catch (error) {
      AppTheme.snack(
        'Could not delete user',
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onView,
    required this.onEdit,
    required this.onRoles,
    required this.onToggleActive,
    required this.onDelete,
  });

  final UserModel user;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onRoles;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final active = user.isActive ?? false;
    final hasImage =
        user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primarySoft,
                child: hasImage
                    ? ClipOval(
                        child: AppNetworkImage(
                          url: user.profileImageUrl!,
                          width: 48,
                          height: 48,
                        ),
                      )
                    : Text(
                        (user.name ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name ?? 'Unnamed user',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      user.email ?? '',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: active ? AppColors.primarySoft : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  active ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: active ? AppColors.primaryDark : AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (user.roles.isEmpty ? ['CUSTOMER'] : user.roles)
                .map(
                  (role) => Chip(
                    label: Text(
                      role.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.primarySoft,
                    side: BorderSide.none,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            children: [
              TextButton.icon(
                onPressed: onRoles,
                icon: const Icon(Icons.manage_accounts_outlined, size: 18),
                label: const Text('Roles'),
              ),
              IconButton(
                tooltip: 'View',
                onPressed: onView,
                icon: const Icon(Icons.visibility_outlined),
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: active ? 'Deactivate' : 'Activate',
                onPressed: onToggleActive,
                icon: Icon(
                  active ? Icons.toggle_on : Icons.toggle_off_outlined,
                  color: active ? AppColors.primary : AppColors.muted,
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            const Icon(Icons.expand_more_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _OptionSheet extends StatelessWidget {
  const _OptionSheet({
    required this.title,
    required this.options,
    required this.selected,
  });

  final String title;
  final List<String> options;
  final String selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...options.map(
              (option) => ListTile(
                title: Text(option),
                trailing: option == selected
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, option),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
