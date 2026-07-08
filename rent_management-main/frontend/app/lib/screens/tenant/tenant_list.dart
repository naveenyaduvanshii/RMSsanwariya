import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../layout/main_layout.dart';
import '../../services/api_service.dart';

class TenantsPage extends StatefulWidget {
  final String role;
  final String userName;
  final String renterId;

  const TenantsPage({
    super.key,
    required this.role,
    required this.userName,
    required this.renterId,
  });

  @override
  State<TenantsPage> createState() => _TenantsPageState();
}

class _TenantsPageState extends State<TenantsPage> {

  List tenants = [];
  List filteredTenants = [];
  bool isLoading = false;
  String selectedStatusFilter = "all";

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTenants();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchTenants() async {
    setState(() => isLoading = true);

    try {
      final res = await http.get(
        Uri.parse("${ApiService.baseUrl}/api/tenants/"),
      );

      final data = jsonDecode(res.body);

      if (data["success"] == true) {
        tenants = data["data"] ?? [];
        filterTenants();
      }
    } catch (e) {
      debugPrint("Fetch tenants error: $e");
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void filterTenants() {
    final query = searchController.text.trim().toLowerCase();

    setState(() {
      filteredTenants = tenants.where((t) {
        final name = (t["name"] ?? "").toString().toLowerCase();
        final phone = (t["phone"] ?? "").toString();
        final status = (t["status"] ?? "active").toString().toLowerCase();

        final matchesQuery = query.isEmpty || name.contains(query) || phone.contains(query);
        final matchesStatus = selectedStatusFilter == "all" || status == selectedStatusFilter;

        return matchesQuery && matchesStatus;
      }).toList();
    });
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    switch (status.toLowerCase()) {
      case "active":
        bgColor = Colors.green[50]!;
        textColor = Colors.green[700]!;
        break;
      case "inactive":
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
        break;
      case "blocked":
        bgColor = Colors.red[50]!;
        textColor = Colors.red[700]!;
        break;
      default:
        bgColor = Colors.grey[50]!;
        textColor = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> confirmDeleteTenant(String id, String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Delete Tenant"),
          content: Text("Are you sure you want to delete tenant '$name'? This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await deleteTenant(id);
    }
  }

  Future<void> deleteTenant(String id) async {
    await http.delete(
      Uri.parse("${ApiService.baseUrl}/api/delete-tenant/$id/"),
    );

    fetchTenants();
  }

  void openTenantForm({Map? tenant}) {
    final nameController = TextEditingController(text: tenant?["name"] ?? "");
    final phoneController = TextEditingController(text: tenant?["phone"] ?? "");
    final emailController = TextEditingController(text: tenant?["email"] ?? "");
    String selectedStatus = tenant?["status"] ?? "active";

    showDialog(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(tenant == null ? "Add Tenant" : "Edit Tenant"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Phone")),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
                if (tenant != null) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(labelText: "Status"),
                    items: const [
                      DropdownMenuItem(value: "active", child: Text("Active")),
                      DropdownMenuItem(value: "inactive", child: Text("Inactive")),
                      DropdownMenuItem(value: "blocked", child: Text("Blocked")),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedStatus = val;
                        });
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final body = {
                  "name": nameController.text,
                  "phone": phoneController.text,
                  "email": emailController.text,
                  if (tenant != null) "status": selectedStatus,
                };

                if (tenant == null) {
                  await http.post(
                    Uri.parse("${ApiService.baseUrl}/api/create-tenant/"),
                    headers: {"Content-Type": "application/json"},
                    body: jsonEncode(body),
                  );
                } else {
                  await http.put(
                    Uri.parse("${ApiService.baseUrl}/api/update-tenant/${tenant["id"]}/"),
                    headers: {"Content-Type": "application/json"},
                    body: jsonEncode(body),
                  );
                }

                Navigator.pop(context);
                fetchTenants();
              },
              child: const Text("Save"),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      role: widget.role,
      userName: widget.userName,
      renterId: widget.renterId,
      currentIndex: 7, // ✅ FIXED (TENANTS index in your sidebar)
      child: Column(
        children: [

          const SizedBox(height: 10),

          // SEARCH + ADD
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              final searchField = TextField(
                controller: searchController,
                onChanged: (_) => filterTenants(),
                decoration: const InputDecoration(
                  hintText: "Search tenants...",
                  prefixIcon: Icon(Icons.search),
                ),
              );

              final statusDropdown = DropdownButtonFormField<String>(
                value: selectedStatusFilter,
                decoration: const InputDecoration(
                  labelText: "Filter Status",
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: "all", child: Text("All Statuses")),
                  DropdownMenuItem(value: "active", child: Text("Active")),
                  DropdownMenuItem(value: "inactive", child: Text("Inactive")),
                  DropdownMenuItem(value: "blocked", child: Text("Blocked")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      selectedStatusFilter = val;
                    });
                    filterTenants();
                  }
                },
              );

              final addButton = ElevatedButton.icon(
                onPressed: () => openTenantForm(),
                icon: const Icon(Icons.add),
                label: const Text("Add Tenant"),
              );

              if (isMobile) {
                return Column(
                  children: [
                    searchField,
                    const SizedBox(height: 10),
                    statusDropdown,
                    if (widget.role == "owner" || widget.role == "manager") ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: addButton,
                      ),
                    ],
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(flex: 3, child: searchField),
                    const SizedBox(width: 10),
                    Expanded(flex: 2, child: statusDropdown),
                    if (widget.role == "owner" || widget.role == "manager") ...[
                      const SizedBox(width: 10),
                      addButton,
                    ],
                  ],
                );
              }
            }
          ),

          const SizedBox(height: 10),

          // LIST
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTenants.isEmpty
                    ? const Center(child: Text("No tenants found"))
                    : ListView.builder(
                        itemCount: filteredTenants.length,
                        itemBuilder: (context, index) {
                          final t = filteredTenants[index];

                           return Card(
                             child: ListTile(
                               title: Row(
                                 children: [
                                   Expanded(
                                     child: Text(
                                       (t["name"] ?? "").toString(),
                                       overflow: TextOverflow.ellipsis,
                                       style: const TextStyle(fontWeight: FontWeight.bold),
                                     ),
                                   ),
                                   const SizedBox(width: 8),
                                   _buildStatusBadge(t["status"] ?? "active"),
                                 ],
                               ),
                               subtitle: Text(
                                 "${t["phone"] ?? ""} | ${t["email"] ?? ""}",
                                 overflow: TextOverflow.ellipsis,
                               ),
                               trailing: Row(
                                 mainAxisSize: MainAxisSize.min,
                                 children: [

                                   if (widget.role != "tenant")
                                     IconButton(
                                       icon: const Icon(Icons.edit),
                                       onPressed: () => openTenantForm(tenant: t),
                                     ),

                                   if (widget.role == "owner")
                                     IconButton(
                                       icon: const Icon(Icons.delete, color: Colors.red),
                                       onPressed: () => confirmDeleteTenant(t["id"].toString(), t["name"] ?? "this tenant"),
                                     ),
                                 ],
                               ),
                             ),
                           );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}