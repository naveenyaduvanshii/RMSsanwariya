import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../layout/main_layout.dart';

class BuildingsPage extends StatefulWidget {
  final String role;
  final String userName;
  final String renterId;

  const BuildingsPage({
    super.key,
    required this.role,
    required this.userName,
    required this.renterId,
  });

  @override
  State<BuildingsPage> createState() => _BuildingsPageState();
}

class _BuildingsPageState extends State<BuildingsPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController floorsController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  List buildings = [];
  List filteredBuildings = [];

  bool isLoading = true;
  bool isSaving = false;
  bool isEdit = false;

  String editId = "";

  final String baseUrl = "http://127.0.0.1:8000";

  @override
  void initState() {
    super.initState();
    fetchBuildings();
  }

  ////////////////////////////////////////////////////////////
  /// FETCH
  ////////////////////////////////////////////////////////////
  Future<void> fetchBuildings() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/buildings/"),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        buildings = List<Map<String, dynamic>>.from(data["buildings"] ?? []);
        filteredBuildings = buildings;
      }
    } catch (e) {}

    setState(() => isLoading = false);
  }

  ////////////////////////////////////////////////////////////
  /// SEARCH
  ////////////////////////////////////////////////////////////
  void searchBuilding(String value) {
    setState(() {
      filteredBuildings = buildings.where((b) {
        final name = (b["name"] ?? "").toString().toLowerCase();
        return name.contains(value.toLowerCase());
      }).toList();
    });
  }

  ////////////////////////////////////////////////////////////
  /// ADD
  ////////////////////////////////////////////////////////////
  Future<void> addBuilding() async {
    setState(() => isSaving = true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/buildings/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": nameController.text,
          "address": addressController.text,
          "city": cityController.text,
          "total_floors": int.tryParse(floorsController.text) ?? 1,
        }),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        Navigator.pop(context);
        clearFields();
        fetchBuildings();
      }
    } catch (e) {}

    setState(() => isSaving = false);
  }

  ////////////////////////////////////////////////////////////
  /// UPDATE
  ////////////////////////////////////////////////////////////
  Future<void> updateBuilding() async {
    setState(() => isSaving = true);

    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/buildings/$editId/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": nameController.text,
          "address": addressController.text,
          "city": cityController.text,
          "total_floors": int.tryParse(floorsController.text) ?? 1,
        }),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        Navigator.pop(context);
        clearFields();
        fetchBuildings();
      }
    } catch (e) {}

    setState(() => isSaving = false);
  }

  ////////////////////////////////////////////////////////////
  /// DELETE
  ////////////////////////////////////////////////////////////
  Future<void> confirmDeleteBuilding(String id, String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Delete Building"),
          content: Text("Are you sure you want to delete building '$name'? All associated floors, flats, rooms, and assignments will be deleted."),
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
      await deleteBuilding(id);
    }
  }

  Future<void> deleteBuilding(String id) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/api/buildings/$id/"),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        fetchBuildings();
      }
    } catch (e) {}
  }

  void clearFields() {
    nameController.clear();
    addressController.clear();
    cityController.clear();
    floorsController.clear();
    isEdit = false;
    editId = "";
  }

  ////////////////////////////////////////////////////////////
  /// OPEN DIALOG
  ////////////////////////////////////////////////////////////
  void showDialogBox({Map? b}) {
    if (b != null) {
      isEdit = true;
      editId = b["id"];

      nameController.text = b["name"] ?? "";
      addressController.text = b["address"] ?? "";
      cityController.text = b["city"] ?? "";
      floorsController.text = (b["total_floors"] ?? "").toString();
    } else {
      clearFields();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? "Edit Building" : "Add Building"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildField("Building Name", nameController),
              buildField("Address", addressController),
              buildField("City", cityController),
              buildField("Floors", floorsController),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: isSaving
                ? null
                : (isEdit ? updateBuilding : addBuilding),
            child: isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isEdit ? "Update" : "Save"),
          )
        ],
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// LABEL FIELD (IMPORTANT)
  ////////////////////////////////////////////////////////////
  Widget buildField(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: c,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// UI
  ////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return MainLayout(
      role: widget.role,
      userName: widget.userName,
      renterId: widget.renterId,
      currentIndex: 3,

      child: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // SEARCH
                    TextField(
                      controller: searchController,
                      onChanged: searchBuilding,
                      decoration: InputDecoration(
                        hintText: "Search buildings...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // LIST
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredBuildings.length,
                        itemBuilder: (context, i) {
                          final b = filteredBuildings[i];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 10,
                                  color: Colors.black.withOpacity(0.05),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  child: Icon(Icons.apartment),
                                ),
                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        b["name"] ?? "",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "${b["address"] ?? ""} • ${b["city"] ?? ""}",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () =>
                                      showDialogBox(b: b),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      confirmDeleteBuilding(b["id"], b["name"] ?? "this building"),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

          // ✅ FLOATING ADD BUTTON (CUSTOM)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () => showDialogBox(),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}