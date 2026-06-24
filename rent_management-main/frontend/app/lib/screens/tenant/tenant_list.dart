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
        filteredTenants = List.from(tenants);
      }
    } catch (e) {
      debugPrint("Fetch tenants error: $e");
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void filterTenants(String query) {
    final q = query.toLowerCase();

    setState(() {
      filteredTenants = tenants.where((t) {
        final name = (t["name"] ?? "").toString().toLowerCase();
        final phone = (t["phone"] ?? "").toString();

        return name.contains(q) || phone.contains(query);
      }).toList();
    });
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

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tenant == null ? "Add Tenant" : "Edit Tenant"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Phone")),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
          ],
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: filterTenants,
                  decoration: const InputDecoration(
                    hintText: "Search tenants...",
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              if (widget.role == "owner" || widget.role == "manager")
                ElevatedButton(
                  onPressed: () => openTenantForm(),
                  child: const Text("Add Tenant"),
                )
            ],
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
                              title: Text((t["name"] ?? "").toString()),
                              subtitle: Text("${t["phone"] ?? ""} | ${t["email"] ?? ""}"),
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
                                      onPressed: () => deleteTenant(t["id"].toString()),
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