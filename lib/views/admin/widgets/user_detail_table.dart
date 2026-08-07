import 'package:flutter/material.dart';
import '../../../models/user_model.dart';

class UserDetailTable extends StatefulWidget {
  final List<UserModel> users;

  const UserDetailTable({super.key, required this.users});

  @override
  State<UserDetailTable> createState() => _UserDetailTableState();
}

class _UserDetailTableState extends State<UserDetailTable> {
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();
  String selectedStatus = "All Status";
  String selectedRole = "All Role";

  String canonicalRole(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'ADMIN';
      case 'MERCHANT':
        return 'MERCHANT';
      case 'CUSTOMER':
        return 'CUSTOMER';
      default:
        return role.toUpperCase();
    }
  }

  String displayRole(String role) {
    switch (role) {
      case 'ADMIN':
        return 'Admin';
      case 'MERCHANT':
        return 'Merchant';
      case 'CUSTOMER':
        return 'Customer';
      default:
        final lower = role.toLowerCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
    }
  }

  List<String> get availableRoles {
    final roles = widget.users
        .expand((user) => user.roles)
        .map(canonicalRole)
        .where((role) => role.isNotEmpty)
        .toSet()
        .toList();
    roles.sort();
    return ['All Role', ...roles];
  }

  List<UserModel> get filteredUsers {
    final query = searchQuery.toLowerCase().trim();
    return widget.users.where((user) {
      final role = user.roles.isNotEmpty ? canonicalRole(user.roles.first) : 'CUSTOMER';
      final status = (user.isActive ?? false) ? 'Active' : 'Inactive';
      final roleMatch = selectedRole == 'All Role' || role == selectedRole;
      final statusMatch = selectedStatus == 'All Status' || status == selectedStatus;
      final searchMatch = query.isEmpty ||
          user.name?.toLowerCase().contains(query) == true ||
          user.email?.toLowerCase().contains(query) == true ||
          displayRole(role).toLowerCase().contains(query) ||
          status.toLowerCase().contains(query);
      return roleMatch && statusMatch && searchMatch;
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final bool narrow = constraints.maxWidth < 280;
              return Align(
                alignment: Alignment.centerRight,
                child: narrow
                    ? IconButton(
                        icon: const Icon(Icons.add),
                        color: Colors.white,
                        tooltip: 'Add User',
                        onPressed: () {},
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          padding: const EdgeInsets.all(14),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add),
                        label: const Text("Add User"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
              );
            },
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool narrow = constraints.maxWidth < 640;
              return narrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: searchController,
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "Search users...",
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  value: selectedRole,
                                  items: availableRoles
                                      .map(
                                        (role) => DropdownMenuItem(
                                          value: role,
                                          child: Text(role == 'All Role' ? role : displayRole(role)),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedRole = value!;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  value: selectedStatus,
                                  items: ["All Status", "Active", "Inactive"]
                                      .map(
                                        (status) => DropdownMenuItem(
                                          value: status,
                                          child: Text(status),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedStatus = value!;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: "Search users...",
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButton<String>(
                            underline: const SizedBox(),
                            value: selectedRole,
                            items: availableRoles
                                .map(
                                  (role) => DropdownMenuItem(
                                    value: role,
                                    child: Text(role == 'All Role' ? role : displayRole(role)),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedRole = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 15),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButton<String>(
                            underline: const SizedBox(),
                            value: selectedStatus,
                            items: ["All Status", "Active", "Inactive"]
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedStatus = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    );
            },
          ),
          const SizedBox(height: 25),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
                columns: const [
                  DataColumn(
                    label: Text(
                      "User",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Email",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Role",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Join Date",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Status",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Actions",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: filteredUsers.map((user) {
                  final role = user.roles.isNotEmpty ? user.roles.first : 'Customer';
                  final status = (user.isActive ?? false) ? 'Active' : 'Inactive';
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          user.name ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(Text(user.email ?? '-')),
                      DataCell(Chip(label: Text(displayRole(role)))),
                      DataCell(Text(user.createdAt != null ? '${user.createdAt!.year}-${user.createdAt!.month.toString().padLeft(2, '0')}-${user.createdAt!.day.toString().padLeft(2, '0')}' : '-')),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: status == "Active" ? Colors.green.shade100 : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(status),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
