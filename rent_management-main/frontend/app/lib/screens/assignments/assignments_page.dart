import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../layout/main_layout.dart';
import '../../services/api_service.dart';

class TenantAssignmentsPage extends StatefulWidget {
  final String role;
  final String userName;
  final String renterId;

  const TenantAssignmentsPage({
    super.key,
    required this.role,
    required this.userName,
    required this.renterId,
  });

  @override
  State<TenantAssignmentsPage> createState() => _TenantAssignmentsPageState();
}

class _TenantAssignmentsPageState extends State<TenantAssignmentsPage> {
  List assignments = [];
  List filteredAssignments = [];
  List tenants = [];
  List rentalUnits = [];

  bool isLoading = true;
  bool isSaving = false;
  bool isEdit = false;
  String editId = "";

  final searchController = TextEditingController();
  final securityDepositController = TextEditingController();
  final discountController = TextEditingController();
  final finalRentController = TextEditingController();
  final startDateController = TextEditingController();

  final minRentController = TextEditingController();
  final maxRentController = TextEditingController();

  String? filterStatus;
  String? filterBuilding;
  String? filterFloor;
  String? filterRoom;
  String? filterSort = "newest";
  bool showFilters = false;

  String? selectedTenant;
  String? selectedRentalUnit;
  bool exclusiveOccupancy = false;

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  @override
  void dispose() {
    searchController.dispose();
    securityDepositController.dispose();
    discountController.dispose();
    finalRentController.dispose();
    startDateController.dispose();
    minRentController.dispose();
    maxRentController.dispose();
    super.dispose();
  }

  Future<void> loadInitialData() async {
    setState(() => isLoading = true);
    await Future.wait([
      loadAssignments(),
      loadTenants(),
      loadRentalUnits(),
    ]);
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void clearForm() {
    selectedTenant = null;
    selectedRentalUnit = null;
    exclusiveOccupancy = false;
    securityDepositController.clear();
    discountController.clear();
    finalRentController.clear();
    startDateController.clear();
    editId = "";
    isEdit = false;
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> loadAssignments() async {
    try {
      final response = await ApiService.get("api/tenant-assignments/");
      assignments = response["data"] ?? [];
      applyFilters();
    } catch (e) {
      debugPrint("Assignment Load Error: $e");
    }
  }

  Future<void> loadTenants() async {
    try {
      final response = await ApiService.get("api/tenants-dropdown/");
      tenants = response["data"] ?? [];
    } catch (e) {
      debugPrint("Tenant Load Error: $e");
    }
  }

  Future<void> loadRentalUnits() async {
    try {
      final response = await ApiService.get("api/rental-units-dropdown/");
      rentalUnits = response["data"] ?? [];
    } catch (e) {
      debugPrint("Rental Unit Load Error: $e");
    }
  }

  List<String> getUniqueBuildings() {
    final Set<String> bNames = {};
    for (var a in assignments) {
      final name = a["building_name"]?.toString();
      if (name != null && name.isNotEmpty) bNames.add(name);
    }
    return bNames.toList()..sort();
  }

  List<String> getUniqueFloors() {
    final Set<String> fNums = {};
    for (var a in assignments) {
      if (filterBuilding != null && a["building_name"] != filterBuilding) continue;
      final fName = a["floor_name"]?.toString();
      if (fName != null && fName.isNotEmpty) fNums.add(fName);
    }
    return fNums.toList()..sort();
  }

  List<String> getUniqueRooms() {
    final Set<String> rNums = {};
    for (var a in assignments) {
      if (filterBuilding != null && a["building_name"] != filterBuilding) continue;
      if (filterFloor != null && a["floor_name"] != filterFloor) continue;
      final rNum = a["room_number"]?.toString();
      if (rNum != null && rNum.isNotEmpty) rNums.add(rNum);
    }
    return rNums.toList()..sort();
  }

  void applyFilters() {
    final query = searchController.text.trim().toLowerCase();
    final minRent = double.tryParse(minRentController.text) ?? 0.0;
    final maxRent = double.tryParse(maxRentController.text) ?? double.infinity;

    filteredAssignments = assignments.where((item) {
      final tenantName = (item["tenant_name"] ?? "").toString().toLowerCase();
      final phone = (item["tenant_phone"] ?? "").toString().toLowerCase();
      final room = (item["room_number"] ?? "").toString().toLowerCase();
      final flat = (item["flat_number"] ?? "").toString().toLowerCase();

      final searchMatch = query.isEmpty ||
          tenantName.contains(query) ||
          phone.contains(query) ||
          room.contains(query) ||
          flat.contains(query);

      final statusMatch = filterStatus == null || item["status"]?.toString() == filterStatus;
      final buildingMatch = filterBuilding == null || item["building_name"]?.toString() == filterBuilding;
      final floorMatch = filterFloor == null || item["floor_name"]?.toString() == filterFloor;
      final roomMatch = filterRoom == null || item["room_number"]?.toString() == filterRoom;
      
      final rentVal = double.tryParse(item["final_rent"]?.toString() ?? "") ?? 0.0;
      final rentMatch = rentVal >= minRent && rentVal <= maxRent;

      return searchMatch && statusMatch && buildingMatch && floorMatch && roomMatch && rentMatch;
    }).toList();

    if (filterSort == "oldest") {
      filteredAssignments.sort((a, b) {
        final dateA = DateTime.tryParse(a["rent_start_date"]?.toString() ?? "") ?? DateTime(1970);
        final dateB = DateTime.tryParse(b["rent_start_date"]?.toString() ?? "") ?? DateTime(1970);
        return dateA.compareTo(dateB);
      });
    } else {
      filteredAssignments.sort((a, b) {
        final dateA = DateTime.tryParse(a["rent_start_date"]?.toString() ?? "") ?? DateTime(1970);
        final dateB = DateTime.tryParse(b["rent_start_date"]?.toString() ?? "") ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });
    }

    setState(() {});
  }

  void resetFilters() {
    searchController.clear();
    minRentController.clear();
    maxRentController.clear();
    filterStatus = null;
    filterBuilding = null;
    filterFloor = null;
    filterRoom = null;
    filterSort = "newest";
    applyFilters();
  }

  void downloadPdf() {
    final search = searchController.text.trim();
    final building = filterBuilding ?? "";
    final floor = filterFloor ?? "";
    final room = filterRoom ?? "";
    final rentMin = minRentController.text.trim();
    final rentMax = maxRentController.text.trim();
    final status = filterStatus ?? "all";
    final sort = filterSort ?? "newest";

    final url = "${ApiService.baseUrl}/api/assignments/report/pdf/?"
        "search=${Uri.encodeComponent(search)}"
        "&building=${Uri.encodeComponent(building)}"
        "&floor=${Uri.encodeComponent(floor)}"
        "&room=${Uri.encodeComponent(room)}"
        "&rent_min=${Uri.encodeComponent(rentMin)}"
        "&rent_max=${Uri.encodeComponent(rentMax)}"
        "&status=${Uri.encodeComponent(status)}"
        "&sort=${Uri.encodeComponent(sort)}";

    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Widget _buildReportOptionsButton(BuildContext context, {required bool isFullWidth}) {
    return PopupMenuButton<String>(
      tooltip: "Report Options",
      onSelected: (value) {
        if (value == 'download') {
          downloadPdf();
        } else if (value == 'print') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Opening print preview...")),
          );
          downloadPdf();
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
            color: const Color(0xFF0F172A),
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

  bool validateForm() {
    if (selectedTenant == null) {
      showMessage("Select Tenant");
      return false;
    }
    if (selectedRentalUnit == null) {
      showMessage("Select Rental Unit");
      return false;
    }
    if (finalRentController.text.trim().isEmpty) {
      showMessage("Enter Final Rent");
      return false;
    }
    if (startDateController.text.trim().isEmpty) {
      showMessage("Select Start Date");
      return false;
    }
    return true;
  }

  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      startDateController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {});
    }
  }

  Future<void> addAssignment() async {
    if (!validateForm()) return;
    setState(() => isSaving = true);
    try {
      final res = await ApiService.post(
        "api/add-tenant-assignment/",
        {
          "tenant_id": selectedTenant,
          "rental_unit_id": selectedRentalUnit,
          "exclusive_occupancy": exclusiveOccupancy,
          "security_deposit": double.tryParse(securityDepositController.text) ?? 0,
          "discount_percent": double.tryParse(discountController.text) ?? 0,
          "final_rent": double.tryParse(finalRentController.text) ?? 0,
          "rent_start_date": startDateController.text,
        },
      );
      if (mounted) {
        Navigator.pop(context);
        clearForm();
        await loadAssignments();
        showMessage(res["message"] ?? "Tenant Assigned Successfully");
      }
    } catch (e) {
      debugPrint("Add Assignment Error: $e");
      showMessage(e.toString().replaceAll("Exception:", "").trim());
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> updateAssignment() async {
    if (editId.isEmpty) return;
    setState(() => isSaving = true);
    try {
      await ApiService.put(
        "api/update-tenant-assignment/$editId/",
        {
          "security_deposit": double.tryParse(securityDepositController.text) ?? 0,
          "discount_percent": double.tryParse(discountController.text) ?? 0,
          "final_rent": double.tryParse(finalRentController.text) ?? 0,
        },
      );
      if (mounted) {
        Navigator.pop(context);
        clearForm();
        await loadAssignments();
        showMessage("Assignment Updated Successfully");
      }
    } catch (e) {
      debugPrint("Update Assignment Error: $e");
      showMessage("Update Failed");
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> vacateTenant(String assignmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Vacate Tenant"),
        content: const Text("Are you sure you want to vacate this tenant?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("Vacate"),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      await ApiService.put("api/vacate-tenant/$assignmentId/", {});
      await loadAssignments();
      showMessage("Tenant Vacated Successfully");
    } catch (e) {
      debugPrint(e.toString());
      showMessage("Vacate Failed");
    }
  }

  Future<void> deleteAssignment(String assignmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Assignment"),
        content: const Text("Are you sure? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      await ApiService.delete("api/delete-assignment/$assignmentId/");
      await loadAssignments();
      showMessage("Deleted Successfully");
    } catch (e) {
      debugPrint(e.toString());
      showMessage("Delete Failed");
    }
  }

  Widget buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  void showAssignmentDialog({Map? assignment}) {
    clearForm();
    final dialogTenantSearchController = TextEditingController();
    String? dialogSelectedBuilding;
    String? dialogSelectedFloor;

    if (assignment != null) {
      isEdit = true;
      editId = assignment["id"]?.toString() ?? "";
      selectedTenant = assignment["tenant_id"]?.toString();
      selectedRentalUnit = assignment["rental_unit_id"]?.toString();
      securityDepositController.text = assignment["security_deposit"]?.toString() ?? "0";
      discountController.text = assignment["discount_percent"]?.toString() ?? "0";
      finalRentController.text = assignment["final_rent"]?.toString() ?? "0";
      startDateController.text = assignment["rent_start_date"]?.toString() ?? "";
      exclusiveOccupancy = assignment["exclusive_occupancy"] == true;
    }

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final Map<String, String> buildingMap = {};
            for (var u in rentalUnits) {
              final bId = u["building_id"]?.toString();
              final bName = u["building_name"]?.toString();
              if (bId != null && bId.isNotEmpty) buildingMap[bId] = bName ?? "No Building";
            }

            final Map<String, String> floorMap = {};
            for (var u in rentalUnits) {
              if (dialogSelectedBuilding != null && u["building_id"]?.toString() != dialogSelectedBuilding) continue;
              final fId = u["floor_id"]?.toString();
              final fNum = u["floor_number"]?.toString();
              if (fId != null && fId.isNotEmpty) floorMap[fId] = fNum != null ? "Floor $fNum" : "No Floor";
            }

            final tenantQuery = dialogTenantSearchController.text.trim().toLowerCase();
            final filteredTenants = tenants.where((tenant) {
              final name = (tenant["name"] ?? "").toString().toLowerCase();
              final phone = (tenant["phone"] ?? "").toString().toLowerCase();
              final matches = name.contains(tenantQuery) || phone.contains(tenantQuery);
              final isSelected = tenant["id"].toString() == selectedTenant;
              return tenantQuery.isEmpty || matches || isSelected;
            }).toList();

            final filteredUnits = rentalUnits.where((unit) {
              final bMatch = dialogSelectedBuilding == null || unit["building_id"]?.toString() == dialogSelectedBuilding;
              final fMatch = dialogSelectedFloor == null || unit["floor_id"]?.toString() == dialogSelectedFloor;
              
              final int cap = unit["capacity"] ?? 1;
              final int occ = unit["occupied_count"] ?? 0;
              final String occType = unit["occupancy_type"] ?? "shared";
              final bool isFull = (occType == "exclusive" && occ >= 1) || occ >= cap;
              final isSelected = unit["id"].toString() == selectedRentalUnit;

              return (bMatch && fMatch && (!isFull || isSelected)) || isSelected;
            }).toList();

            return AlertDialog(
              title: Text(isEdit ? "Edit Assignment" : "Assign Tenant"),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isEdit) ...[
                        TextField(
                          controller: dialogTenantSearchController,
                          decoration: InputDecoration(
                            labelText: "Search Tenant",
                            prefixIcon: const Icon(Icons.search, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                        const SizedBox(height: 12),
                      ],
                      DropdownButtonFormField<String>(
                        value: filteredTenants.any((t) => t["id"].toString() == selectedTenant) ? selectedTenant : null,
                        decoration: const InputDecoration(labelText: "Tenant", border: OutlineInputBorder()),
                        items: filteredTenants.map((tenant) {
                          return DropdownMenuItem<String>(
                            value: tenant["id"].toString(),
                            child: Text("${tenant["name"]} (${tenant["phone"]})", style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: isEdit ? null : (value) => setDialogState(() => selectedTenant = value),
                      ),
                      const SizedBox(height: 15),
                      if (!isEdit) ...[
                      if (MediaQuery.of(context).size.width < 500) ...[
                        DropdownButtonFormField<String>(
                          value: dialogSelectedBuilding,
                          decoration: const InputDecoration(labelText: "Building Filter", border: OutlineInputBorder()),
                          items: [
                            const DropdownMenuItem<String>(value: null, child: Text("All")),
                            ...buildingMap.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                          ],
                          onChanged: (val) {
                            setDialogState(() {
                              dialogSelectedBuilding = val;
                              dialogSelectedFloor = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: dialogSelectedFloor,
                          decoration: const InputDecoration(labelText: "Floor Filter", border: OutlineInputBorder()),
                          items: [
                            const DropdownMenuItem<String>(value: null, child: Text("All")),
                            ...floorMap.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                          ],
                          onChanged: (val) => setDialogState(() => dialogSelectedFloor = val),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: dialogSelectedBuilding,
                                decoration: const InputDecoration(labelText: "Building Filter", border: OutlineInputBorder()),
                                items: [
                                  const DropdownMenuItem<String>(value: null, child: Text("All")),
                                  ...buildingMap.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                                ],
                                onChanged: (val) {
                                  setDialogState(() {
                                    dialogSelectedBuilding = val;
                                    dialogSelectedFloor = null;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: dialogSelectedFloor,
                                decoration: const InputDecoration(labelText: "Floor Filter", border: OutlineInputBorder()),
                                items: [
                                  const DropdownMenuItem<String>(value: null, child: Text("All")),
                                  ...floorMap.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                                ],
                                onChanged: (val) => setDialogState(() => dialogSelectedFloor = val),
                              ),
                            ),
                          ],
                        ),
                      ],
                        const SizedBox(height: 15),
                      ],
                       DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: filteredUnits.any((u) => u["id"].toString() == selectedRentalUnit) ? selectedRentalUnit : null,
                        decoration: const InputDecoration(labelText: "Rental Unit", border: OutlineInputBorder()),
                        items: filteredUnits.map((unit) {
                          String type = (unit["unit_type"] ?? "").toString().toUpperCase();
                          String details = "";
                          if (unit["room_number"].toString().isNotEmpty) {
                            details = unit["flat_number"].toString().isNotEmpty
                                ? "Room ${unit["room_number"]} (Flat ${unit["flat_number"]})"
                                : "Room ${unit["room_number"]} (Floor ${unit["floor_number"]})";
                          } else if (unit["flat_number"].toString().isNotEmpty) {
                            details = "Flat ${unit["flat_number"]}";
                          } else {
                            details = "Unit ${unit["id"].toString().substring(0, 8)}";
                          }

                          final int cap = unit["capacity"] ?? 1;
                          final int occ = unit["occupied_count"] ?? 0;
                          final String occType = (unit["occupancy_type"] ?? "shared").toString().toUpperCase();

                          return DropdownMenuItem<String>(
                            value: unit["id"].toString(),
                            child: Text(
                              "$type: $details | ₹${unit["rent"]} ($occType: $occ/$cap)",
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: isEdit
                            ? null
                            : (value) {
                                setDialogState(() {
                                  selectedRentalUnit = value;
                                  final selected = rentalUnits.firstWhere(
                                    (e) => e["id"].toString() == value,
                                    orElse: () => {},
                                  );
                                  if (selected.isNotEmpty) {
                                    finalRentController.text = selected["rent"].toString();
                                  }
                                });
                              },
                      ),
                      const SizedBox(height: 15),
                      buildField("Security Deposit", securityDepositController),
                      buildField("Discount %", discountController),
                      buildField("Final Rent", finalRentController),
                      TextField(
                        controller: startDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: "Start Date",
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_month),
                            onPressed: pickStartDate,
                          ),
                        ),
                        onTap: pickStartDate,
                      ),
                      const SizedBox(height: 12),
                      StatefulBuilder(
                        builder: (context, setSwitchState) {
                          final selectedUnit = selectedRentalUnit == null
                              ? null
                              : rentalUnits.firstWhere(
                                  (u) => u["id"].toString() == selectedRentalUnit,
                                  orElse: () => null,
                                );
                          final bool isSingleCapacity = selectedUnit != null && (selectedUnit["capacity"] ?? 1) == 1;

                          if (isSingleCapacity && exclusiveOccupancy) {
                            exclusiveOccupancy = false;
                          }

                          return SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("Exclusive Occupancy", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              isSingleCapacity
                                  ? "Disabled: Already a single occupant unit"
                                  : "Tenant occupies entire unit",
                              style: const TextStyle(fontSize: 11),
                            ),
                            value: exclusiveOccupancy,
                            onChanged: isSingleCapacity
                                ? null
                                : (value) => setDialogState(() => exclusiveOccupancy = value),
                          );
                        },
                      ),
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
                  onPressed: isSaving
                      ? null
                      : () {
                          if (isEdit) {
                            updateAssignment();
                          } else {
                            if (exclusiveOccupancy) {
                              final unit = rentalUnits.firstWhere(
                                (u) => u["id"].toString() == selectedRentalUnit,
                                orElse: () => {},
                              );
                              final int occ = unit["occupied_count"] ?? 0;
                              if (occ > 0) {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text("Unit Already Occupied"),
                                    content: const Text(
                                      "This unit already has active occupants. Please vacate or delete all other assignments for this unit before assigning it exclusively."
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text("OK"),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }
                            }
                            addAssignment();
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(isEdit ? "Update" : "Assign"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget buildAssignmentCard(Map assignment) {
    final status = (assignment["status"] ?? "").toString().toLowerCase();
    Color statusColor = Colors.orange;
    if (status == "active") statusColor = Colors.green;
    if (status == "vacated") statusColor = Colors.red;

    String unitName = "";
    if ((assignment["bed_number"] ?? "").toString().isNotEmpty) {
      unitName = "${assignment["building_name"]} > ${assignment["floor_name"]} > Flat ${assignment["flat_number"]} > Room ${assignment["room_number"]} > Bed ${assignment["bed_number"]}";
    } else if ((assignment["room_number"] ?? "").toString().isNotEmpty) {
      final flatPart = (assignment["flat_number"] ?? "").toString().isNotEmpty ? "Flat ${assignment["flat_number"]} > " : "";
      unitName = "${assignment["building_name"]} > ${assignment["floor_name"]} > $flatPart Room ${assignment["room_number"]}";
    } else if ((assignment["flat_number"] ?? "").toString().isNotEmpty) {
      unitName = "${assignment["building_name"]} > ${assignment["floor_name"]} > Flat ${assignment["flat_number"]}";
    } else {
      unitName = assignment["building_name"] ?? "";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.005), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.08),
                radius: 20,
                child: Icon(Icons.person_outline, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment["tenant_name"] ?? "",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      assignment["tenant_phone"] ?? "",
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    unitName,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildInfoColumn("Rent", "₹${assignment["final_rent"]}"),
              _buildInfoColumn("Deposit", "₹${assignment["security_deposit"]}"),
              _buildInfoColumn("Discount", "${assignment["discount_percent"]}%"),
              _buildInfoColumn("Start Date", assignment["rent_start_date"] ?? "-"),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      assignment["exclusive_occupancy"] == true ? Icons.lock_outline : Icons.groups_outlined,
                      size: 14,
                      color: assignment["exclusive_occupancy"] == true ? Colors.red.shade400 : Colors.green.shade400,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        assignment["exclusive_occupancy"] == true ? "Exclusive" : "Shared",
                        style: TextStyle(
                          fontSize: 11,
                          color: assignment["exclusive_occupancy"] == true ? Colors.red.shade700 : Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (widget.role == "owner" || widget.role == "manager") ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => showAssignmentDialog(assignment: assignment),
                ),
                if (status == "active") ...[
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.logout_outlined, color: Colors.orange, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => vacateTenant(assignment["id"].toString()),
                  ),
                ],
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => deleteAssignment(assignment["id"].toString()),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return MainLayout(
      role: widget.role,
      userName: widget.userName,
      renterId: widget.renterId,
      currentIndex: 8,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 20),
                  _buildSearchAndToggleRow(),
                  if (showFilters) ...[
                    const SizedBox(height: 12),
                    _buildFiltersPanel(isDesktop),
                  ],
                  const SizedBox(height: 20),
                  filteredAssignments.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Text(
                              "No Assignments Found",
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredAssignments.length,
                          itemBuilder: (context, index) {
                            return buildAssignmentCard(filteredAssignments[index]);
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = MediaQuery.of(context).size.width < 600;
        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Tenant Assignments",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 4),
              Text(
                "${assignments.length} assignments registered",
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              if (widget.role == "owner" || widget.role == "manager") ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => showAssignmentDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Assign Tenant"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ],
          );
        } else {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tenant Assignments",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${assignments.length} assignments registered",
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              if (widget.role == "owner" || widget.role == "manager")
                ElevatedButton.icon(
                  onPressed: () => showAssignmentDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Assign Tenant"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
          );
        }
      }
    );
  }

  Widget _buildSearchAndToggleRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 450;
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                onChanged: (_) => applyFilters(),
                decoration: InputDecoration(
                  hintText: isSmall ? "Search..." : "Search by tenant, phone, flat, room...",
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (isSmall)
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  foregroundColor: const Color(0xFF334155),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.all(14),
                ),
                onPressed: () => setState(() => showFilters = !showFilters),
                icon: Icon(showFilters ? Icons.filter_alt_off : Icons.filter_alt_outlined, size: 18),
              )
            else
              OutlinedButton.icon(
                onPressed: () => setState(() => showFilters = !showFilters),
                icon: Icon(showFilters ? Icons.filter_alt_off : Icons.filter_alt_outlined, size: 18),
                label: Text(showFilters ? "Hide Filters" : "Filters"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
          ],
        );
      }
    );
  }

  Widget _buildFiltersPanel(bool isDesktop) {
    final buildings = getUniqueBuildings();
    final floors = getUniqueFloors();
    final rooms = getUniqueRooms();

    final buildingFilterWidget = DropdownButtonFormField<String>(
      isExpanded: true,
      value: filterBuilding,
      decoration: const InputDecoration(labelText: "Building", border: OutlineInputBorder()),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text("All Buildings", overflow: TextOverflow.ellipsis)),
        ...buildings.map((b) => DropdownMenuItem(value: b, child: Text(b, overflow: TextOverflow.ellipsis))),
      ],
      onChanged: (val) {
        setState(() {
          filterBuilding = val;
          filterFloor = null;
          filterRoom = null;
        });
        applyFilters();
      },
    );

    final floorFilterWidget = DropdownButtonFormField<String>(
      isExpanded: true,
      value: filterFloor,
      decoration: const InputDecoration(labelText: "Floor", border: OutlineInputBorder()),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text("All Floors", overflow: TextOverflow.ellipsis)),
        ...floors.map((f) => DropdownMenuItem(value: f, child: Text(f, overflow: TextOverflow.ellipsis))),
      ],
      onChanged: (val) {
        setState(() {
          filterFloor = val;
          filterRoom = null;
        });
        applyFilters();
      },
    );

    final roomFilterWidget = DropdownButtonFormField<String>(
      isExpanded: true,
      value: filterRoom,
      decoration: const InputDecoration(labelText: "Room", border: OutlineInputBorder()),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text("All Rooms", overflow: TextOverflow.ellipsis)),
        ...rooms.map((r) => DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis))),
      ],
      onChanged: (val) {
        setState(() => filterRoom = val);
        applyFilters();
      },
    );

    final statusFilterWidget = DropdownButtonFormField<String>(
      isExpanded: true,
      value: filterStatus,
      decoration: const InputDecoration(labelText: "Status", border: OutlineInputBorder()),
      items: const [
        DropdownMenuItem(value: null, child: Text("All Statuses", overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: "active", child: Text("Active", overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: "pending", child: Text("Pending", overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: "vacated", child: Text("Vacated", overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (val) {
        setState(() => filterStatus = val);
        applyFilters();
      },
    );

    final sortFilterWidget = DropdownButtonFormField<String>(
      isExpanded: true,
      value: filterSort,
      decoration: const InputDecoration(labelText: "Sorting", border: OutlineInputBorder()),
      items: const [
        DropdownMenuItem(value: "newest", child: Text("Newest first", overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: "oldest", child: Text("Oldest first", overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (val) {
        setState(() => filterSort = val);
        applyFilters();
      },
    );

    final rentRangeWidget = Row(
      children: [
        Expanded(
          child: TextField(
            controller: minRentController,
            keyboardType: TextInputType.number,
            onChanged: (_) => applyFilters(),
            decoration: const InputDecoration(labelText: "Min Rent", border: OutlineInputBorder()),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: maxRentController,
            keyboardType: TextInputType.number,
            onChanged: (_) => applyFilters(),
            decoration: const InputDecoration(labelText: "Max Rent", border: OutlineInputBorder()),
          ),
        ),
      ],
    );

    final actionButtonsWidget = LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = MediaQuery.of(context).size.width < 600;
        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextButton.icon(
                onPressed: resetFilters,
                icon: const Icon(Icons.refresh),
                label: const Text("Reset Filters"),
              ),
              const SizedBox(height: 8),
              _buildReportOptionsButton(context, isFullWidth: true),
            ],
          );
        } else {
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: resetFilters,
                icon: const Icon(Icons.refresh),
                label: const Text("Reset Filters"),
              ),
              const SizedBox(width: 10),
              _buildReportOptionsButton(context, isFullWidth: false),
            ],
          );
        }
      }
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          if (isDesktop) ...[
            Row(
              children: [
                Expanded(child: buildingFilterWidget),
                const SizedBox(width: 10),
                Expanded(child: floorFilterWidget),
                const SizedBox(width: 10),
                Expanded(child: roomFilterWidget),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: statusFilterWidget),
                const SizedBox(width: 10),
                Expanded(child: sortFilterWidget),
                const SizedBox(width: 10),
                Expanded(child: rentRangeWidget),
              ],
            ),
          ] else ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(width: 150, child: buildingFilterWidget),
                  const SizedBox(width: 10),
                  SizedBox(width: 150, child: floorFilterWidget),
                  const SizedBox(width: 10),
                  SizedBox(width: 150, child: roomFilterWidget),
                  const SizedBox(width: 10),
                  SizedBox(width: 150, child: statusFilterWidget),
                  const SizedBox(width: 10),
                  SizedBox(width: 150, child: sortFilterWidget),
                  const SizedBox(width: 10),
                  SizedBox(width: 180, child: rentRangeWidget),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          actionButtonsWidget,
        ],
      ),
    );
  }
}