import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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

  // Filters State
  String? filterBuilding;
  String? filterFloor;
  String? filterFlat;
  String? filterRoom;
  String? filterMonth;

  final TextEditingController previousController = TextEditingController();
  final TextEditingController currentController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController monthController = TextEditingController();

  String? activeRoomId;

  Future<void> fetchActiveAssignment() async {
    if (widget.role != "tenant") return;
    try {
      final response = await http.get(Uri.parse("$baseUrl/api/tenant-assignments/"));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body["data"] ?? [];
        for (var item in list) {
          if (item["tenant_id"].toString() == widget.renterId && item["status"] == "active") {
            setState(() {
              activeRoomId = item["room_id"]?.toString();
            });
            break;
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching active assignment: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchActiveAssignment().then((_) {
      fetchReadings();
    });
    fetchRooms();
  }

  List getFilteredReadings() {
    return readings.where((r) {
      if (widget.role == "tenant" && r["room_id"]?.toString() != activeRoomId) {
        return false;
      }

      if (filterBuilding != null && r["building_name"] != filterBuilding) {
        return false;
      }
      if (filterFloor != null && r["floor_number"]?.toString() != filterFloor) {
        return false;
      }
      if (filterFlat != null && r["flat_number"]?.toString() != filterFlat) {
        return false;
      }
      if (filterRoom != null && r["room_number"]?.toString() != filterRoom) {
        return false;
      }
      if (filterMonth != null) {
        final mStr = r["reading_month"].toString().substring(0, 7);
        if (mStr != filterMonth) return false;
      }
      return true;
    }).toList();
  }

  void downloadPdfReport() {
    final String url = "$baseUrl/api/electricity/report/pdf/?"
        "building=${filterBuilding ?? ''}&"
        "floor=${filterFloor ?? ''}&"
        "flat=${filterFlat ?? ''}&"
        "room=${filterRoom ?? ''}&"
        "month=${filterMonth ?? ''}";
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Widget _buildReportOptionsButton(BuildContext context, {required bool isFullWidth}) {
    return PopupMenuButton<String>(
      tooltip: "Report Options",
      onSelected: (value) {
        if (value == 'download') {
          downloadPdfReport();
        } else if (value == 'print') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Opening print preview...")),
          );
          downloadPdfReport();
        } else if (value == 'whatsapp') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("WhatsApp integration will be added later.")),
          );
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'download',
          child: Row(
            children: [
              Icon(Icons.download, color: Colors.blue),
              SizedBox(width: 10),
              Text("Download PDF", style: TextStyle(color: Color(0xFF1E293B))),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'print',
          child: Row(
            children: [
              Icon(Icons.print, color: Colors.indigo),
              SizedBox(width: 10),
              Text("Print", style: TextStyle(color: Color(0xFF1E293B))),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'whatsapp',
          child: Row(
            children: [
              Icon(Icons.chat, color: Colors.green),
              SizedBox(width: 10),
              Text("WhatsApp", style: TextStyle(color: Color(0xFF1E293B))),
            ],
          ),
        ),
      ],
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: isFullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  "Report Options",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
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
    // Dynamic list extraction for filters
    final Set<String> buildingsSet = {};
    final Set<String> floorsSet = {};
    final Set<String> flatsSet = {};
    final Set<String> roomsSet = {};
    final Set<String> monthsSet = {};
    for (var r in readings) {
      if (r["building_name"] != null && r["building_name"].toString().isNotEmpty) {
        buildingsSet.add(r["building_name"]);
      }
      if (r["floor_number"] != null) {
        floorsSet.add(r["floor_number"].toString());
      }
      if (r["flat_number"] != null && r["flat_number"].toString().isNotEmpty) {
        flatsSet.add(r["flat_number"].toString());
      }
      if (r["room_number"] != null && r["room_number"].toString().isNotEmpty) {
        roomsSet.add(r["room_number"].toString());
      }
      if (r["reading_month"] != null && r["reading_month"].toString().isNotEmpty) {
        monthsSet.add(r["reading_month"].toString().substring(0, 7));
      }
    }

    final filteredReadings = getFilteredReadings();

    return MainLayout(
      role: widget.role,
      userName: widget.userName,
      renterId: widget.renterId,
      currentIndex: 11,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // HEADER CARD & ACTIONS
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      if (isMobile) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Electricity Meter Ledger",
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Track meter changes and consumption rates",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            Column(
                              children: [
                                _buildReportOptionsButton(context, isFullWidth: true),
                                if (widget.role != "tenant") ...[
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.add),
                                      label: const Text("Log Meter Entry"),
                                      onPressed: () => openForm(),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Electricity Meter Ledger",
                                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Track meter changes and consumption rates",
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _buildReportOptionsButton(context, isFullWidth: false),
                                if (widget.role != "tenant") ...[
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.add),
                                    label: const Text("Log Meter Entry"),
                                    onPressed: () => openForm(),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        );
                      }
                    }
                  ),
                  const SizedBox(height: 15),

                  // FILTERS CONTROLLER ACCORDION / BOX
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;

                        final clearFiltersButton = (filterBuilding != null || filterFloor != null || filterFlat != null || filterRoom != null || filterMonth != null)
                            ? TextButton.icon(
                                icon: const Icon(Icons.clear_all, size: 16),
                                label: const Text("Reset Filters"),
                                onPressed: () {
                                  setState(() {
                                    filterBuilding = null;
                                    filterFloor = null;
                                    filterFlat = null;
                                    filterRoom = null;
                                    filterMonth = null;
                                  });
                                },
                              )
                            : const SizedBox();

                        final buildingDropdown = SizedBox(
                          width: 150,
                          child: DropdownButtonFormField<String>(
                            value: filterBuilding,
                            decoration: const InputDecoration(labelText: "Building", border: OutlineInputBorder()),
                            items: [
                              const DropdownMenuItem(value: null, child: Text("All Buildings")),
                              ...buildingsSet.map((b) => DropdownMenuItem(value: b, child: Text(b))),
                            ],
                            onChanged: (v) => setState(() => filterBuilding = v),
                          ),
                        );

                        final floorDropdown = SizedBox(
                          width: 150,
                          child: DropdownButtonFormField<String>(
                            value: filterFloor,
                            decoration: const InputDecoration(labelText: "Floor", border: OutlineInputBorder()),
                            items: [
                              const DropdownMenuItem(value: null, child: Text("All Floors")),
                              ...floorsSet.map((f) => DropdownMenuItem(value: f, child: Text("Floor $f"))),
                            ],
                            onChanged: (v) => setState(() => filterFloor = v),
                          ),
                        );

                        final flatDropdown = SizedBox(
                          width: 150,
                          child: DropdownButtonFormField<String>(
                            value: filterFlat,
                            decoration: const InputDecoration(labelText: "Flat", border: OutlineInputBorder()),
                            items: [
                              const DropdownMenuItem(value: null, child: Text("All Flats")),
                              ...flatsSet.map((fl) => DropdownMenuItem(value: fl, child: Text("Flat $fl"))),
                            ],
                            onChanged: (v) => setState(() => filterFlat = v),
                          ),
                        );

                        final roomDropdown = SizedBox(
                          width: 150,
                          child: DropdownButtonFormField<String>(
                            value: filterRoom,
                            decoration: const InputDecoration(labelText: "Room", border: OutlineInputBorder()),
                            items: [
                              const DropdownMenuItem(value: null, child: Text("All Rooms")),
                              ...roomsSet.map((r) => DropdownMenuItem(value: r, child: Text("Room $r"))),
                            ],
                            onChanged: (v) => setState(() => filterRoom = v),
                          ),
                        );

                        final monthDropdown = SizedBox(
                          width: 150,
                          child: DropdownButtonFormField<String>(
                            value: filterMonth,
                            decoration: const InputDecoration(labelText: "Month", border: OutlineInputBorder()),
                            items: [
                              const DropdownMenuItem(value: null, child: Text("All Months")),
                              ...monthsSet.map((m) {
                                final year = m.substring(0, 4);
                                final monthNum = int.parse(m.substring(5, 7));
                                final monthNames = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                                final name = "${monthNames[monthNum]} $year";
                                return DropdownMenuItem(value: m, child: Text(name));
                              }),
                            ],
                            onChanged: (v) => setState(() => filterMonth = v),
                          ),
                        );

                        if (isMobile) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                monthDropdown,
                                const SizedBox(width: 10),
                                buildingDropdown,
                                const SizedBox(width: 10),
                                floorDropdown,
                                const SizedBox(width: 10),
                                flatDropdown,
                                const SizedBox(width: 10),
                                roomDropdown,
                                if (filterBuilding != null || filterFloor != null || filterFlat != null || filterRoom != null || filterMonth != null) ...[
                                  const SizedBox(width: 10),
                                  clearFiltersButton,
                                ],
                              ],
                            ),
                          );
                        } else {
                          return Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              DropdownButton<String>(
                                hint: const Text("Month"),
                                value: filterMonth,
                                underline: const SizedBox(),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text("All Months")),
                                  ...monthsSet.map((m) {
                                    final year = m.substring(0, 4);
                                    final monthNum = int.parse(m.substring(5, 7));
                                    final monthNames = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                                    final name = "${monthNames[monthNum]} $year";
                                    return DropdownMenuItem(value: m, child: Text(name));
                                  }),
                                ],
                                onChanged: (v) => setState(() => filterMonth = v),
                              ),
                              DropdownButton<String>(
                                hint: const Text("Building"),
                                value: filterBuilding,
                                underline: const SizedBox(),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text("All Buildings")),
                                  ...buildingsSet.map((b) => DropdownMenuItem(value: b, child: Text(b))),
                                ],
                                onChanged: (v) => setState(() => filterBuilding = v),
                              ),
                              DropdownButton<String>(
                                hint: const Text("Floor"),
                                value: filterFloor,
                                underline: const SizedBox(),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text("All Floors")),
                                  ...floorsSet.map((f) => DropdownMenuItem(value: f, child: Text("Floor $f"))),
                                ],
                                onChanged: (v) => setState(() => filterFloor = v),
                              ),
                              DropdownButton<String>(
                                hint: const Text("Flat"),
                                value: filterFlat,
                                underline: const SizedBox(),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text("All Flats")),
                                  ...flatsSet.map((fl) => DropdownMenuItem(value: fl, child: Text("Flat $fl"))),
                                ],
                                onChanged: (v) => setState(() => filterFlat = v),
                              ),
                              DropdownButton<String>(
                                hint: const Text("Room"),
                                value: filterRoom,
                                underline: const SizedBox(),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text("All Rooms")),
                                  ...roomsSet.map((r) => DropdownMenuItem(value: r, child: Text("Room $r"))),
                                ],
                                onChanged: (v) => setState(() => filterRoom = v),
                              ),
                              if (filterBuilding != null || filterFloor != null || filterFlat != null || filterRoom != null || filterMonth != null)
                                clearFiltersButton,
                            ],
                          );
                        }
                      }
                    ),
                  ),
                  const SizedBox(height: 15),

                  // SCROLLABLE LEDGER DATA OVERVIEW
                  filteredReadings.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text("No electricity history matches selected filters.")))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredReadings.length,
                          itemBuilder: (context, index) {
                            final r = filteredReadings[index];

                              double prev = (r["previous_reading"] ?? 0.0).toDouble();
                              double curr = (r["current_reading"] ?? 0.0).toDouble();
                              double rate = (r["unit_rate"] ?? 0.0).toDouble();
                              double netUnits = curr - prev;
                              double calculatedInvoiceBill = netUnits * rate;

                              String buildingDetail = "";
                              if (r["building_name"] != null && r["building_name"].toString().isNotEmpty) {
                                buildingDetail += r["building_name"];
                              }
                              if (r["floor_number"] != null) {
                                buildingDetail += ", Floor ${r["floor_number"]}";
                              }
                              if (r["flat_number"] != null && r["flat_number"].toString().isNotEmpty) {
                                buildingDetail += ", Flat ${r["flat_number"]}";
                              }

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                elevation: 2,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.amber.shade100,
                                    child: Icon(Icons.flash_on, color: Colors.amber.shade800),
                                  ),
                                  title: Text(
                                    "Room ${r["room_number"] ?? 'N/A'}${buildingDetail.isNotEmpty ? ' ($buildingDetail)' : ''}",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
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
                ],
              ),
            ),
    );
  }
}