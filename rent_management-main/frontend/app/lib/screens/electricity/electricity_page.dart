import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../layout/main_layout.dart';

class ElectricityPage extends StatefulWidget {
  final String role;
  final String userName;
  final String renterId;

  const ElectricityPage({
    super.key,
    required this.role,
    required this.userName,
    required this.renterId,
  });

  @override
  State<ElectricityPage> createState() => _ElectricityPageState();
}

class _ElectricityPageState extends State<ElectricityPage> {
  final String baseUrl = "http://127.0.0.1:8000";

  List readings = [];
  List rooms = [];

  String? selectedRoomId;

  bool isLoading = true;
  bool isSaving = false;
  bool isEdit = false;

  String editId = "";

  final TextEditingController previousController = TextEditingController();
  final TextEditingController currentController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController monthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchReadings();
    fetchRooms();
  }

  // ---------------- FETCH ROOMS ----------------
  Future<void> fetchRooms() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/rooms/"));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          rooms = (data is Map && data.containsKey("data")) ? data["data"] : data;
        });
      }
    } catch (e) {
      debugPrint("Rooms fetch failed: ${e.toString()}");
    }
  }

  // ---------------- FETCH READINGS ----------------
  Future<void> fetchReadings() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final res = await http.get(Uri.parse("$baseUrl/api/electricity-readings/"));
      final data = jsonDecode(res.body);

      if (data["success"] == true) {
        setState(() {
          readings = data["data"];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Readings fetch failed: ${e.toString()}");
      setState(() => isLoading = false);
    }
  }

  // ---------------- ADD ----------------
  Future<void> addReading() async {
    if (selectedRoomId == null ||
        previousController.text.isEmpty ||
        currentController.text.isEmpty ||
        rateController.text.isEmpty ||
        monthController.text.isEmpty) {
      return;
    }

    setState(() => isSaving = true);

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/create-electricity-reading/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "room_id": selectedRoomId,
          "previous_reading": double.parse(previousController.text),
          "current_reading": double.parse(currentController.text),
          "unit_rate": double.parse(rateController.text),
          "reading_month": monthController.text,
        }),
      );

      final data = jsonDecode(res.body);

      if (data["success"] == true) {
        Navigator.pop(context);
        fetchReadings();
        clear();
      }
    } catch (e) {
      debugPrint("Add transaction error: ${e.toString()}");
    }

    setState(() => isSaving = false);
  }

  // ---------------- UPDATE ----------------
  Future<void> updateReading() async {
    if (editId.isEmpty) return;
    setState(() => isSaving = true);

    try {
      // ✅ Matches path configuration layout pattern: api/electricity/<uuid>/update/
      final res = await http.put(
        Uri.parse("$baseUrl/api/electricity/$editId/update/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "room_id": selectedRoomId,
          "previous_reading": double.parse(previousController.text),
          "current_reading": double.parse(currentController.text),
          "unit_rate": double.parse(rateController.text),
          "reading_month": monthController.text,
        }),
      );

      final data = jsonDecode(res.body);

      if (data["success"] == true) {
        Navigator.pop(context);
        fetchReadings();
        clear();
      }
    } catch (e) {
      debugPrint("Update transaction error: ${e.toString()}");
    }

    setState(() => isSaving = false);
  }

  // ---------------- DELETE ----------------
  Future<void> deleteReading(String id) async {
    try {
      // ✅ Matches path configuration layout pattern: api/electricity/<uuid>/delete/
      final res = await http.delete(
        Uri.parse("$baseUrl/api/electricity/$id/delete/"),
      );

      final data = jsonDecode(res.body);
      if (data["success"] == true) {
        fetchReadings();
      }
    } catch (e) {
      debugPrint("Delete routing error: ${e.toString()}");
    }
  }

  // ---------------- CLEAR ----------------
  void clear() {
    previousController.clear();
    currentController.clear();
    rateController.clear();
    monthController.clear();
    selectedRoomId = null;
    isEdit = false;
    editId = "";
  }

  // ---------------- OPEN FORM ----------------
  void openForm({Map? item}) {
    if (item != null) {
      isEdit = true;
      editId = item["id"];
      selectedRoomId = item["room_id"] ?? item["room"];
      previousController.text = item["previous_reading"].toString();
      currentController.text = item["current_reading"].toString();
      rateController.text = item["unit_rate"].toString();
      monthController.text = item["reading_month"].toString();
    } else {
      clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        // ✅ Isolated state overlay engine context scope boundary fixes freezing dropdowns
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter dialogState) {
            return AlertDialog(
              title: Text(isEdit ? "Update Reading" : "Add New Reading"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ROOM DROPDOWN
                    DropdownButtonFormField<String>(
                      value: selectedRoomId,
                      items: rooms.map<DropdownMenuItem<String>>((r) {
                        return DropdownMenuItem<String>(
                          value: r["id"].toString(),
                          child: Text("Room ${r["room_number"] ?? 'N/A'}"),
                        );
                      }).toList(),
                      onChanged: (v) {
                        // Synced mutation alters current layout trees concurrently
                        dialogState(() => selectedRoomId = v);
                        setState(() => selectedRoomId = v);
                      },
                      decoration: const InputDecoration(
                        labelText: "Select Room Target",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: previousController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Previous Reading (kWh)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: currentController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Current Reading (kWh)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: rateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Unit Cost Rate (₹)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: monthController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Billing Cycle Month",
                        suffixIcon: Icon(Icons.calendar_month),
                        border: OutlineInputBorder(),
                      ),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (pickedDate != null) {
                          String standardStringDate =
                              "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                          dialogState(() => monthController.text = standardStringDate);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    clear();
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          dialogState(() => isSaving = true);
                          if (isEdit) {
                            await updateReading();
                          } else {
                            await addReading();
                          }
                          dialogState(() => isSaving = false);
                        },
                  child: Text(isSaving ? "Saving..." : "Save Log"),
                )
              ],
            );
          },
        );
      },
    );
  }

  // ---------------- UI VIEW BUILDER ----------------
  @override
  Widget build(BuildContext context) {
    return MainLayout(
      role: widget.role,
      userName: widget.userName,
      renterId: widget.renterId,
      currentIndex: 11,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // HEADER CARD
                  Card(
                    color: Colors.blue.shade700,
                    elevation: 4,
                    child: const ListTile(
                      title: Text(
                        "Electricity Consumption Master Ledger",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "Track dynamic meter changes and sub-unit consumption rates",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // CONTROL ACTION SUB-BAR
                  if (widget.role != "tenant")
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text("Log Fresh Meter Entry"),
                        onPressed: () => openForm(),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ),
                  const SizedBox(height: 15),

                  // SCROLLABLE LEDGER DATA OVERVIEW
                  Expanded(
                    child: readings.isEmpty
                        ? const Center(child: Text("No electricity history logged for this account."))
                        : ListView.builder(
                            itemCount: readings.length,
                            itemBuilder: (context, index) {
                              final r = readings[index];

                              double prev = (r["previous_reading"] ?? 0.0).toDouble();
                              double curr = (r["current_reading"] ?? 0.0).toDouble();
                              double rate = (r["unit_rate"] ?? 0.0).toDouble();
                              double netUnits = curr - prev;
                              double calculatedInvoiceBill = netUnits * rate;

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                elevation: 2,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.amber.shade100,
                                    child: Icon(Icons.flash_on, color: Colors.amber.shade800),
                                  ),
                                  title: Text(
                                    "Room ${r["room_number"] ?? 'N/A'}",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0), // ✅ Fixed constructor name bug here
                                    child: Text(
                                      "Cycle Month: ${r["reading_month"] ?? 'N/A'}\n"
                                      "Units Consumed: ${netUnits.toStringAsFixed(1)} kWh (${prev.toStringAsFixed(0)} ➔ ${curr.toStringAsFixed(0)})\n"
                                      "Total Due: ₹${calculatedInvoiceBill.toStringAsFixed(2)} (@ ₹$rate/unit)",
                                      style: const TextStyle(height: 1.4),
                                    ),
                                  ),
                                  isThreeLine: true,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (widget.role != "tenant")
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => openForm(item: r),
                                        ),
                                      if (widget.role == "owner")
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => deleteReading(r["id"]),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  )
                ],
              ),
            ),
    );
  }
}