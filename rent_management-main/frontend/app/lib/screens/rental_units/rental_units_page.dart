import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../layout/main_layout.dart';

class RentalUnitsPage extends StatefulWidget {
  final String role;
  final String userName;
  final String renterId;

  const RentalUnitsPage({
    super.key,
    required this.role,
    required this.userName,
    required this.renterId,
  });

  @override
  State<RentalUnitsPage> createState() => _RentalUnitsPageState();
}

class _RentalUnitsPageState extends State<RentalUnitsPage> {
  final String baseUrl = "http://127.0.0.1:8000";

  bool isLoading = true;
  bool isSaving = false;

  List units = [];

  bool isEdit = false;
  String editId = "";

  // Dropdown/Form parameters explicitly matching your backend entity structure
  String selectedUnitType = "room";
  bool allowSharing = false;

  final TextEditingController rentController = TextEditingController();
  final TextEditingController capacityController = TextEditingController();
  final TextEditingController buildingIdController = TextEditingController();
  final TextEditingController floorIdController = TextEditingController();
  final TextEditingController flatIdController = TextEditingController();
  final TextEditingController roomIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUnits();
  }

  ////////////////////////////////////////////////////////////
  /// FETCH UNITS
  ////////////////////////////////////////////////////////////
  Future<void> fetchUnits() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/rental-units/"),
      );

      if (res.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(res.body);
        if (decodedData["success"] == true) {
          setState(() {
            units = decodedData["data"] ?? [];
            isLoading = false;
          });
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint(e.toString());
      setState(() => isLoading = false);
    }
  }

  ////////////////////////////////////////////////////////////
  /// ADD / UPDATE UNIT
  ////////////////////////////////////////////////////////////
  Future<void> saveUnit() async {
    if (rentController.text.isEmpty) return;

    setState(() => isSaving = true);

    try {
      // Corrected url routing structures matching your Django patterns
      final url = isEdit
          ? "$baseUrl/api/rental-units/$editId/update/"
          : "$baseUrl/api/rental-units/create/";

      final responseFuture = isEdit
          ? http.put(
              Uri.parse(url),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(_buildRequestBody()),
            )
          : http.post(
              Uri.parse(url),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(_buildRequestBody()),
            );

      final res = await responseFuture;

      if (res.statusCode == 200 || res.statusCode == 201) {
        Navigator.pop(context);
        clearFields();
        fetchUnits();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              isEdit ? "Unit Updated Successfully" : "Unit Created Successfully",
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() => isSaving = false);
  }

  Map<String, dynamic> _buildRequestBody() {
    return {
      "unit_type": selectedUnitType,
      "rent": double.tryParse(rentController.text) ?? 0.0,
      "capacity": int.tryParse(capacityController.text) ?? 1,
      "allow_sharing": allowSharing,
      "building_id": buildingIdController.text.trim().isEmpty ? null : buildingIdController.text.trim(),
      "floor_id": floorIdController.text.trim().isEmpty ? null : floorIdController.text.trim(),
      "flat_id": flatIdController.text.trim().isEmpty ? null : flatIdController.text.trim(),
      "room_id": roomIdController.text.trim().isEmpty ? null : roomIdController.text.trim(),
    };
  }

  ////////////////////////////////////////////////////////////
  /// DELETE UNIT
  ////////////////////////////////////////////////////////////
  Future<void> deleteUnit(String id) async {
    try {
      // Corrected endpoint mapping structure
      final res = await http.delete(
        Uri.parse("$baseUrl/api/rental-units/$id/delete/"),
      );

      if (res.statusCode == 200) {
        fetchUnits();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("Unit Permanently Purged"),
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  ////////////////////////////////////////////////////////////
  /// CLEAR
  ////////////////////////////////////////////////////////////
  void clearFields() {
    rentController.clear();
    capacityController.clear();
    buildingIdController.clear();
    floorIdController.clear();
    flatIdController.clear();
    roomIdController.clear();
    selectedUnitType = "room";
    allowSharing = false;
    isEdit = false;
    editId = "";
  }

  ////////////////////////////////////////////////////////////
  /// OPEN FORM DIALOG
  ////////////////////////////////////////////////////////////
  void openDialog({Map? unit}) {
    if (unit != null) {
      isEdit = true;
      editId = unit["id"];
      selectedUnitType = unit["unit_type"] ?? "room";
      rentController.text = (unit["rent"] ?? 0).toString();
      capacityController.text = (unit["capacity"] ?? 1).toString();
      allowSharing = unit["allow_sharing"] == true;
      buildingIdController.text = unit["building_id"] ?? "";
      floorIdController.text = unit["floor_id"] ?? "";
      flatIdController.text = unit["flat_id"] ?? "";
      roomIdController.text = unit["room_id"] ?? "";
    } else {
      clearFields();
    }

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(isEdit ? "Modify Rental Unit" : "Add Rental Unit"),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedUnitType,
                        decoration: const InputDecoration(labelText: "Unit Type", border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: "building", child: Text("Building")),
                          DropdownMenuItem(value: "floor", child: Text("Floor")),
                          DropdownMenuItem(value: "flat", child: Text("Flat")),
                          DropdownMenuItem(value: "room", child: Text("Room")),
                        ],
                        onChanged: (val) => setDialogState(() => selectedUnitType = val!),
                      ),
                      const SizedBox(height: 12),
                      _field("Monthly Rent (₹)", rentController, isNumeric: true),
                      const SizedBox(height: 12),
                      _field("Capacity (Max Occupants)", capacityController, isNumeric: true),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text("Allow Unit Sharing"),
                        value: allowSharing,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setDialogState(() => allowSharing = val),
                      ),
                      const Divider(height: 24),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Structural Hierarchies (Optional UUIDs)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                      const SizedBox(height: 8),
                      _field("Building UUID", buildingIdController),
                      const SizedBox(height: 10),
                      _field("Floor UUID", floorIdController),
                      const SizedBox(height: 10),
                      _field("Flat UUID", flatIdController),
                      const SizedBox(height: 10),
                      _field("Room UUID", roomIdController),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : saveUnit,
                  child: Text(isEdit ? "Update" : "Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  ////////////////////////////////////////////////////////////
  /// UI ROOT BUILDER
  ////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return MainLayout(
      role: widget.role,
      userName: widget.userName,
      renterId: widget.renterId,
      currentIndex: 6,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _header(),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => openDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text("Add Rental Unit"),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: units.isEmpty
                        ? const Center(child: Text("No rental units mapped yet.", style: TextStyle(color: Colors.grey, fontSize: 16)))
                        : GridView.builder(
                            itemCount: units.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 15,
                              crossAxisSpacing: 15,
                              childAspectRatio: 1.4,
                            ),
                            itemBuilder: (context, index) {
                              final unit = units[index];

                              // Resolving dynamic composite names based on the nested models returned by backend select_related query
                              String designation = "Unit Block";
                              if (unit["room_number"].toString().isNotEmpty) {
                                if (unit["flat_number"].toString().isNotEmpty) {
                                  designation = "Room ${unit["room_number"]} (Flat ${unit["flat_number"]})";
                                } else {
                                  designation = "Room ${unit["room_number"]} (Floor ${unit["floor_number"]})";
                                }
                              } else if (unit["flat_number"].toString().isNotEmpty) {
                                designation = "Flat ${unit["flat_number"]}";
                              } else if (unit["building_name"].toString().isNotEmpty) {
                                designation = "${unit["building_name"]} Building";
                              }

                              return Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                    )
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      designation,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text("Type: ${unit["unit_type"].toString().toUpperCase()}", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600)),
                                    Text("Rent: ₹${unit["rent"]}"),
                                    Text("Occupancy: ${unit["occupied_count"]} / ${unit["capacity"]}"),
                                    Text("Status: ${unit["status"].toString().toUpperCase()}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: unit["status"] == "vacant" ? Colors.green : Colors.orange
                                      )
                                    ),
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          onPressed: () => openDialog(unit: unit),
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                        ),
                                        IconButton(
                                          onPressed: () => deleteUnit(unit["id"]),
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
        ),
      ),
      child: const Text(
        "Rental Asset Inventory",
        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {bool isNumeric = false}) {
    return TextField(
      controller: c,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}