// managers_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import '../../layout/main_layout.dart';

class ManagersPage extends StatefulWidget {
  final String role;
  final String userName;
  final String renterId;

  const ManagersPage({
    super.key,
    required this.role,
    required this.userName,
    required this.renterId,
  });

  @override
  State<ManagersPage> createState() => _ManagersPageState();
}

class _ManagersPageState extends State<ManagersPage> {
  // CONTROLLERS
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // VARIABLES
  List managers = [];
  bool isLoading = true;
  bool isAdding = false;
  bool isUpdating = false;

  // BASE URL
  final String baseUrl = ApiService.baseUrl;

  @override
  void initState() {
    super.initState();
    fetchManagers();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  /// ========================================================
  /// FETCH MANAGERS
  /// ========================================================
  Future<void> fetchManagers() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/api/managers/"));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(response.body);
        setState(() {
          managers = decodedData["data"] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Fetch Exception: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// ========================================================
  /// ADD MANAGER
  /// ========================================================
  Future<void> addManager() async {
    final String name = nameController.text.withSpacesRemoved();
    final String email = emailController.text.withSpacesRemoved();
    final String phone = phoneController.text.withSpacesRemoved();

    if (name.isEmpty || phone.isEmpty) {
      showMessage("Name and Phone Number are required", Colors.red);
      return;
    }

    setState(() => isAdding = true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/managers/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email.isEmpty ? null : email,
          "phone": phone,
        }),
      );

      if (!mounted) return;

      final result = jsonDecode(response.body);

      if ((response.statusCode == 201 || response.statusCode == 200) && result["success"] == true) {
        Navigator.pop(context);
        clearFields();
        fetchManagers();
        showMessage("Manager Added Successfully", Colors.green);
      } else {
        showMessage(result["error"] ?? "Failed to create manager", Colors.red);
      }
    } catch (e) {
      debugPrint("Add Exception: $e");
      showMessage("Network connectivity error occurred", Colors.red);
    } finally {
      if (mounted) setState(() => isAdding = false);
    }
  }

  /// ========================================================
  /// UPDATE MANAGER
  /// ========================================================
  Future<void> updateManager(dynamic id) async {
    final String name = nameController.text.withSpacesRemoved();
    final String phone = phoneController.text.withSpacesRemoved();

    if (name.isEmpty || phone.isEmpty) {
      showMessage("Fields cannot be empty", Colors.red);
      return;
    }

    setState(() => isUpdating = true);

    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/managers/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": id,
          "name": name,
          "phone": phone,
        }),
      );

      if (!mounted) return;

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result["success"] == true) {
        Navigator.pop(context);
        fetchManagers();
        showMessage("Manager Updated", Colors.green);
      } else {
        showMessage(result["error"] ?? "Failed to update manager", Colors.red);
      }
    } catch (e) {
      debugPrint("Update Exception: $e");
      showMessage("Network connectivity error occurred", Colors.red);
    } finally {
      if (mounted) setState(() => isUpdating = false);
    }
  }

  /// ========================================================
  /// DELETE MANAGER
  /// ========================================================
  Future<void> confirmDeleteManager(dynamic id, String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Delete Manager"),
          content: Text("Are you sure you want to delete manager '$name'? This action cannot be undone."),
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
      await deleteManager(id);
    }
  }

  Future<void> deleteManager(dynamic id) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/api/managers/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": id}),
      );

      if (!mounted) return;

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result["success"] == true) {
        fetchManagers();
        Navigator.pop(context);
        showMessage("Manager Deleted", Colors.green);
      } else {
        showMessage(result["error"] ?? "Failed to delete manager", Colors.red);
      }
    } catch (e) {
      debugPrint("Delete Exception: $e");
    }
  }

  void showMessage(String text, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: color, content: Text(text), duration: const Duration(seconds: 3)),
    );
  }

  void clearFields() {
    nameController.clear();
    emailController.clear();
    phoneController.clear();
  }

  void showAddManagerDialog() {
    clearFields();
    showDialog(
      context: context,
      builder: (context) => buildManagerDialog(
        title: "Add Manager",
        buttonText: "Add Manager",
        onPressed: addManager,
        isEdit: false,
      ),
    );
  }

  void showManagerDetails(Map manager) {
    nameController.text = manager["name"] ?? "";
    emailController.text = manager["email"] ?? "";
    phoneController.text = manager["phone"] ?? "";

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: const Icon(Icons.manage_accounts, size: 50, color: Colors.blue),
                  ),
                  const SizedBox(height: 20),
                  Text(manager["name"] ?? "", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(manager["email"] ?? "No Email Registered", style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 5),
                  Text(manager["phone"] ?? "", style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            showEditDialog(manager);
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text("Edit"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => confirmDeleteManager(manager["id"], manager["name"] ?? "this manager"),
                          icon: const Icon(Icons.delete),
                          label: const Text("Delete"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showEditDialog(Map manager) {
    showDialog(
      context: context,
      builder: (context) => buildManagerDialog(
        title: "Edit Manager",
        buttonText: "Update Manager",
        onPressed: () => updateManager(manager["id"]),
        isEdit: true,
      ),
    );
  }

  Widget buildManagerDialog({
    required String title,
    required String buttonText,
    required VoidCallback onPressed,
    required bool isEdit,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1E3A8A)]),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 25),
              buildField(controller: nameController, label: "Full Name", icon: Icons.person),
              const SizedBox(height: 18),
              buildField(controller: emailController, label: "Email (Optional)", icon: Icons.email, readOnly: isEdit),
              const SizedBox(height: 18),
              buildField(controller: phoneController, label: "Phone Number", icon: Icons.phone),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: isAdding || isUpdating ? null : onPressed,
                  icon: (isAdding || isUpdating)
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue))
                      : Icon(isEdit ? Icons.edit : Icons.save),
                  label: Text(buttonText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
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
      currentIndex: 2,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                bool isMobile = constraints.maxWidth < 700;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1E3A8A)]),
                        ),
                        child: Flex(
                          direction: isMobile ? Axis.vertical : Axis.horizontal,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                              children: const [
                                Text("Managers", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                                SizedBox(height: 10),
                                Text("Manage active property managers", style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                            SizedBox(height: isMobile ? 20 : 0),
                            ElevatedButton.icon(
                              onPressed: showAddManagerDialog,
                              icon: const Icon(Icons.add),
                              label: const Text("Add Manager"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      managers.isEmpty
                          ? const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text("No property managers assigned yet.")))
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: managers.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isMobile ? 1 : 2,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                childAspectRatio: isMobile ? 1.4 : 1.8,
                              ),
                              itemBuilder: (context, index) {
                                final manager = managers[index];

                                return InkWell(
                                  borderRadius: BorderRadius.circular(25),
                                  onTap: () => showManagerDetails(manager),
                                  child: Container(
                                    padding: const EdgeInsets.all(22),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                                          child: const Icon(Icons.manage_accounts, color: Colors.blue, size: 30),
                                        ),
                                        const Spacer(),
                                        Text(manager["name"] ?? "", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 10),
                                        Text(manager["email"] ?? "No Email", style: const TextStyle(color: Colors.grey)),
                                        const SizedBox(height: 5),
                                        Text(manager["phone"] ?? "", style: const TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      readOnly: readOnly,
      style: TextStyle(color: readOnly ? Colors.white38 : Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      ),
    );
  }
}

/// Helper extension to cleanly handle text input formatting rules
extension on String {
  String withSpacesRemoved() => trim();
}