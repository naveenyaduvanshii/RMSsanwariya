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
  String selectedOccupancyType = "shared"; // policy selector

  final TextEditingController rentController = TextEditingController();
  final TextEditingController capacityController = TextEditingController();
  final TextEditingController buildingIdController = TextEditingController();
  final TextEditingController floorIdController = TextEditingController();
  final TextEditingController flatIdController = TextEditingController();
  final TextEditingController roomIdController = TextEditingController();

  List<dynamic> buildings = [];
  List<dynamic> allFlats = [];
  List<dynamic> allRooms = [];
  List<dynamic> currentFloors = [];
  bool isDropdownLoading = false;
  bool isFloorsLoading = false;

  // Filter State
  String searchQuery = "";
  String? selectedBuildingId;
  String? selectedFloorId;
  String? selectedFlatId;
  String? selectedRoomId;
  String? selectedStatus;
  String? filterOccupancyPolicy; // shared, exclusive, exclusive_occupied
  String selectedSort = "recently_changed"; // default to recently changed
  bool isFiltersExpanded = false;

  // Track dynamically loaded floors for filter bar
  List<dynamic> filterFloors = [];
  bool isFilterFloorsLoading = false;

  @override
  void initState() {
    super.initState();
    fetchUnits();
    fetchDropdownData();
  }

  Future<void> fetchDropdownData() async {
    setState(() => isDropdownLoading = true);
    try {
      final buildingsRes = await http.get(Uri.parse("$baseUrl/api/buildings-dropdown/"));
      final flatsRes = await http.get(Uri.parse("$baseUrl/api/flats/"));
      final roomsRes = await http.get(Uri.parse("$baseUrl/api/rooms/"));

      if (buildingsRes.statusCode == 200 && flatsRes.statusCode == 200 && roomsRes.statusCode == 200) {
        final bData = jsonDecode(buildingsRes.body);
        final flData = jsonDecode(flatsRes.body);
        final rData = jsonDecode(roomsRes.body);

        setState(() {
          buildings = bData["data"] ?? [];
          allFlats = flData["data"] ?? [];
          allRooms = rData["data"] ?? [];
          isDropdownLoading = false;
        });
      } else {
        setState(() => isDropdownLoading = false);
      }
    } catch (e) {
      debugPrint(e.toString());
      setState(() => isDropdownLoading = false);
    }
  }

  Future<void> fetchFloorsForBuilding(String buildingId, StateSetter setDialogState) async {
    setDialogState(() {
      isFloorsLoading = true;
      currentFloors = [];
    });

    try {
      final res = await http.get(Uri.parse("$baseUrl/api/floors-by-building/$buildingId/"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["success"] == true) {
          setDialogState(() {
            currentFloors = data["data"] ?? [];
            isFloorsLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    setDialogState(() {
      isFloorsLoading = false;
    });
  }

  Future<void> fetchFloorsForFilter(String buildingId) async {
    setState(() {
      isFilterFloorsLoading = true;
      filterFloors = [];
      selectedFloorId = null;
      selectedFlatId = null;
      selectedRoomId = null;
    });

    try {
      final res = await http.get(Uri.parse("$baseUrl/api/floors-by-building/$buildingId/"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["success"] == true) {
          setState(() {
            filterFloors = data["data"] ?? [];
            isFilterFloorsLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() {
      isFilterFloorsLoading = false;
    });
  }

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

  Future<void> saveUnit() async {
    if (rentController.text.isEmpty) return;

    setState(() => isSaving = true);

    try {
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
            behavior: SnackBarBehavior.floating,
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
    final int cap = int.tryParse(capacityController.text) ?? 1;
    return {
      "unit_type": selectedUnitType,
      "rent": double.tryParse(rentController.text) ?? 0.0,
      "capacity": cap,
      "allow_sharing": cap > 1, // Treat cap > 1 as sharing dynamically
      "occupancy_type": selectedOccupancyType,
      "building_id": buildingIdController.text.trim().isEmpty ? null : buildingIdController.text.trim(),
      "floor_id": floorIdController.text.trim().isEmpty ? null : floorIdController.text.trim(),
      "flat_id": flatIdController.text.trim().isEmpty ? null : flatIdController.text.trim(),
      "room_id": roomIdController.text.trim().isEmpty ? null : roomIdController.text.trim(),
    };
  }

  Future<void> deleteUnit(String id, {bool deleteUnderlying = false}) async {
    try {
      final res = await http.delete(
        Uri.parse("$baseUrl/api/rental-units/$id/delete/?delete_underlying=$deleteUnderlying"),
      );

      if (res.statusCode == 200) {
        fetchUnits();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            content: Text("Unit Permanently Purged"),
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> confirmDeleteUnit(Map unit) async {
    bool deleteUnderlying = false;
    final unitType = unit["unit_type"] ?? "unit";
    final unitId = unit["id"];

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Delete Rental Unit"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Are you sure you want to delete this Rental Unit?"),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Checkbox(
                        value: deleteUnderlying,
                        onChanged: (val) {
                          setState(() {
                            deleteUnderlying = val ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          "Also delete the associated $unitType from the database",
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
      },
    );

    if (result == true) {
      await deleteUnit(unitId, deleteUnderlying: deleteUnderlying);
    }
  }

  void clearFields() {
    rentController.clear();
    capacityController.clear();
    buildingIdController.clear();
    floorIdController.clear();
    flatIdController.clear();
    roomIdController.clear();
    selectedUnitType = "room";
    selectedOccupancyType = "shared";
    isEdit = false;
    editId = "";
  }

  void openDialog({Map? unit}) async {
    if (unit != null) {
      isEdit = true;
      editId = unit["id"];
      selectedUnitType = unit["unit_type"] ?? "room";
      selectedOccupancyType = unit["occupancy_type"] ?? "shared";
      rentController.text = (unit["rent"] ?? 0).toString();
      capacityController.text = (unit["capacity"] ?? 1).toString();
      buildingIdController.text = unit["building_id"] ?? "";
      floorIdController.text = unit["floor_id"] ?? "";
      flatIdController.text = unit["flat_id"] ?? "";
      roomIdController.text = unit["room_id"] ?? "";
    } else {
      clearFields();
    }

    String? tempBuildingId = buildingIdController.text.trim().isEmpty ? null : buildingIdController.text.trim();
    String? tempFloorId = floorIdController.text.trim().isEmpty ? null : floorIdController.text.trim();
    String? tempFlatId = flatIdController.text.trim().isEmpty ? null : flatIdController.text.trim();
    String? tempRoomId = roomIdController.text.trim().isEmpty ? null : roomIdController.text.trim();

    currentFloors = [];
    if (tempBuildingId != null) {
      setState(() => isFloorsLoading = true);
      try {
        final res = await http.get(Uri.parse("$baseUrl/api/floors-by-building/$tempBuildingId/"));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data["success"] == true) {
            currentFloors = data["data"] ?? [];
          }
        }
      } catch (e) {
        debugPrint(e.toString());
      }
      setState(() => isFloorsLoading = false);
    }

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Safety checks to prevent dropdown assertion errors
            if (tempBuildingId != null && !buildings.any((b) => b["id"] == tempBuildingId)) {
              tempBuildingId = null;
            }
            if (tempFloorId != null && !currentFloors.any((f) => f["id"] == tempFloorId)) {
              tempFloorId = null;
            }

            final filteredFlats = allFlats.where((f) => f["building_id"] == tempBuildingId && f["floor_id"] == tempFloorId).toList();
            if (tempFlatId != null && !filteredFlats.any((f) => f["id"] == tempFlatId)) {
              tempFlatId = null;
            }

            final filteredRooms = allRooms.where((r) {
              if (r["building_id"] != tempBuildingId || r["floor_id"] != tempFloorId) {
                return false;
              }
              if (tempFlatId != null) {
                return r["flat_id"] == tempFlatId;
              } else {
                return r["flat_id"] == null || r["flat_id"].toString().isEmpty;
              }
            }).toList();

            if (tempRoomId != null && !filteredRooms.any((r) => r["id"] == tempRoomId)) {
              tempRoomId = null;
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(isEdit ? "Modify Rental Unit" : "Add Rental Unit", style: const TextStyle(fontWeight: FontWeight.bold)),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: selectedUnitType,
                        decoration: const InputDecoration(labelText: "Unit Type", border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: "building", child: Text("Building", overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: "floor", child: Text("Floor", overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: "flat", child: Text("Flat", overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: "room", child: Text("Room", overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (val) => setDialogState(() {
                          selectedUnitType = val!;
                          tempBuildingId = null;
                          buildingIdController.clear();
                          tempFloorId = null;
                          floorIdController.clear();
                          tempFlatId = null;
                          flatIdController.clear();
                          tempRoomId = null;
                          roomIdController.clear();
                        }),
                      ),
                      const SizedBox(height: 12),
                      _field("Monthly Rent (₹)", rentController, isNumeric: true),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _field("Capacity (Max Occupants)", capacityController, isNumeric: true),
                          const SizedBox(height: 4),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(
                              "Capacity = 1: Single Occupancy Only | Capacity > 1: Sharing Allowed",
                              style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: selectedOccupancyType,
                        decoration: const InputDecoration(labelText: "Unit Policy", border: OutlineInputBorder()),
                         items: const [
                           DropdownMenuItem(value: "shared", child: Text("Shared Policy", overflow: TextOverflow.ellipsis)),
                           DropdownMenuItem(value: "exclusive", child: Text("Exclusive Policy", overflow: TextOverflow.ellipsis)),
                         ],
                        onChanged: (val) => setDialogState(() => selectedOccupancyType = val!),
                      ),
                      const Divider(height: 24),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Structural Hierarchies", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                      ),
                      const SizedBox(height: 12),
                      
                      // Building Dropdown
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: tempBuildingId,
                        decoration: const InputDecoration(labelText: "Select Building", border: OutlineInputBorder()),
                        items: buildings.map<DropdownMenuItem<String>>((b) {
                          return DropdownMenuItem<String>(
                            value: b["id"],
                            child: Text(b["name"] ?? "", overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            tempBuildingId = val;
                            buildingIdController.text = val ?? "";
                            tempFloorId = null;
                            floorIdController.clear();
                            tempFlatId = null;
                            flatIdController.clear();
                            tempRoomId = null;
                            roomIdController.clear();
                          });
                          if (val != null) {
                            fetchFloorsForBuilding(val, setDialogState);
                          }
                        },
                      ),

                      // Floor Dropdown
                      if (selectedUnitType != "building" && tempBuildingId != null) ...[
                        const SizedBox(height: 12),
                        isFloorsLoading
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              )
                            : DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: tempFloorId,
                                decoration: const InputDecoration(labelText: "Select Floor", border: OutlineInputBorder()),
                                items: currentFloors.map<DropdownMenuItem<String>>((f) {
                                  final dispName = f["floor_name"] != null && f["floor_name"].toString().isNotEmpty
                                      ? f["floor_name"]
                                      : "Floor ${f["floor_number"]}";
                                  return DropdownMenuItem<String>(
                                    value: f["id"],
                                    child: Text(dispName.toString(), overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setDialogState(() {
                                    tempFloorId = val;
                                    floorIdController.text = val ?? "";
                                    tempFlatId = null;
                                    flatIdController.clear();
                                    tempRoomId = null;
                                    roomIdController.clear();
                                  });
                                },
                              ),
                      ],

                      // Flat Dropdown
                      if ((selectedUnitType == "flat" || selectedUnitType == "room") && tempFloorId != null) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: tempFlatId,
                          decoration: InputDecoration(
                            labelText: selectedUnitType == "room" ? "Select Flat (Optional)" : "Select Flat",
                            border: const OutlineInputBorder()
                          ),
                          items: [
                            if (selectedUnitType == "room")
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text("None (Direct Room under Floor)", overflow: TextOverflow.ellipsis),
                              ),
                            ...filteredFlats.map<DropdownMenuItem<String>>((f) {
                              return DropdownMenuItem<String>(
                                value: f["id"],
                                child: Text("Flat ${f["flat_number"]}", overflow: TextOverflow.ellipsis),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            setDialogState(() {
                              tempFlatId = val;
                              flatIdController.text = val ?? "";
                              tempRoomId = null;
                              roomIdController.clear();
                            });
                          },
                        ),
                      ],

                      // Room Dropdown
                      if (selectedUnitType == "room" && tempFloorId != null) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: tempRoomId,
                          decoration: const InputDecoration(labelText: "Select Room", border: OutlineInputBorder()),
                          items: filteredRooms.map<DropdownMenuItem<String>>((r) {
                            return DropdownMenuItem<String>(
                              value: r["id"],
                              child: Text("Room ${r["room_number"]}", overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setDialogState(() {
                              tempRoomId = val;
                              roomIdController.text = val ?? "";
                            });
                          },
                        ),
                        if (filteredRooms.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              "No matching rooms found. Please create a Room first.",
                              style: TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                      ],
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
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
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

  @override
  Widget build(BuildContext context) {
    // 1. Process local UI filtering
    final filtered = units.where((unit) {
      final query = searchQuery.trim().toLowerCase();
      final bName = (unit["building_name"] ?? "").toString().toLowerCase();
      final fNum = (unit["floor_number"] ?? "").toString().toLowerCase();
      final flNum = (unit["flat_number"] ?? "").toString().toLowerCase();
      final rNum = (unit["room_number"] ?? "").toString().toLowerCase();
      final matchesQuery = query.isEmpty ||
          bName.contains(query) ||
          fNum.contains(query) ||
          flNum.contains(query) ||
          rNum.contains(query);

      final matchesBuilding = selectedBuildingId == null ||
          unit["building_id"]?.toString() == selectedBuildingId;

      final matchesFloor = selectedFloorId == null ||
          unit["floor_id"]?.toString() == selectedFloorId;

      final matchesFlat = selectedFlatId == null ||
          unit["flat_id"]?.toString() == selectedFlatId;

      final matchesRoom = selectedRoomId == null ||
          unit["room_id"]?.toString() == selectedRoomId;

      final matchesStatus = selectedStatus == null ||
          unit["status"]?.toString().toLowerCase() == selectedStatus!.toLowerCase();

      final matchesPolicy = filterOccupancyPolicy == null ||
          (filterOccupancyPolicy == "shared" && unit["occupancy_type"] == "shared") ||
          (filterOccupancyPolicy == "exclusive" && unit["occupancy_type"] == "exclusive") ||
          (filterOccupancyPolicy == "exclusive_occupied" && unit["exclusive_tenant_id"] != null);

      return matchesQuery &&
          matchesBuilding &&
          matchesFloor &&
          matchesFlat &&
          matchesRoom &&
          matchesStatus &&
          matchesPolicy;
    }).toList();

    // 2. Process sorting
    filtered.sort((a, b) {
      if (selectedSort == "newest") {
        final aDate = a["created_at"]?.toString() ?? "";
        final bDate = b["created_at"]?.toString() ?? "";
        return bDate.compareTo(aDate);
      } else if (selectedSort == "oldest") {
        final aDate = a["created_at"]?.toString() ?? "";
        final bDate = b["created_at"]?.toString() ?? "";
        return aDate.compareTo(bDate);
      } else if (selectedSort == "recently_changed") {
        final aDate = a["updated_at"]?.toString() ?? "";
        final bDate = b["updated_at"]?.toString() ?? "";
        return bDate.compareTo(aDate);
      }
      return 0;
    });

    final int vacantCount = units.where((u) => u["status"] == "vacant").length;
    final int partialCount = units.where((u) => u["status"] == "partial").length;
    final int occupiedCount = units.where((u) => u["status"] == "occupied").length;

    return MainLayout(
      role: widget.role,
      userName: widget.userName,
      renterId: widget.renterId,
      currentIndex: 6,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 24),
                  
                  // Summary Badges
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      if (isMobile) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _summaryCard("Vacant", vacantCount, Colors.green),
                              const SizedBox(width: 12),
                              _summaryCard("Partial", partialCount, Colors.orange),
                              const SizedBox(width: 12),
                              _summaryCard("Occupied", occupiedCount, Colors.red),
                            ],
                          ),
                        );
                      } else {
                        return Row(
                          children: [
                            Expanded(child: _summaryCard("Vacant", vacantCount, Colors.green)),
                            const SizedBox(width: 12),
                            Expanded(child: _summaryCard("Partial", partialCount, Colors.orange)),
                            const SizedBox(width: 12),
                            Expanded(child: _summaryCard("Occupied", occupiedCount, Colors.red)),
                          ],
                        );
                      }
                    }
                  ),
                  const SizedBox(height: 24),

                  // Search and filter options
                  _filterBar(),
                  const SizedBox(height: 20),

                  // Action + Results Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      if (isMobile) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${filtered.length} Rental Units Found",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E3A8A),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                onPressed: () => openDialog(),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text("Add Rental Unit", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${filtered.length} Rental Units Found",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E3A8A),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              onPressed: () => openDialog(),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text("Add Rental Unit", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        );
                      }
                    }
                  ),
                  const SizedBox(height: 20),

                  filtered.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.house_siding_rounded, size: 48, color: Colors.grey),
                              SizedBox(height: 12),
                              Text("No matching rental units found.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                            ],
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final int crossAxisCount = constraints.maxWidth < 650
                                ? 1
                                : (constraints.maxWidth < 1000 ? 2 : 3);
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: constraints.maxWidth < 650 ? 1.05 : 1.3,
                              ),
                              itemBuilder: (context, index) {
                                return _unitCard(filtered[index]);
                              },
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Rental Assets Inventory",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        Text(
          "Manage, filter, and track rooms, flats, and building structures.",
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  Widget _summaryCard(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 6,
            backgroundColor: color,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text("$count units", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterBar() {
    final Map<String, String> buildingMap = {};
    for (var u in units) {
      final bId = u["building_id"]?.toString();
      final bName = u["building_name"]?.toString();
      if (bId != null && bId.isNotEmpty) {
        buildingMap[bId] = bName ?? "No Building";
      }
    }

    final Map<String, String> flatMap = {};
    for (var u in units) {
      if (selectedBuildingId != null && u["building_id"]?.toString() != selectedBuildingId) continue;
      if (selectedFloorId != null && u["floor_id"]?.toString() != selectedFloorId) continue;
      final flId = u["flat_id"]?.toString();
      final flNum = u["flat_number"]?.toString();
      if (flId != null && flId.isNotEmpty) {
        flatMap[flId] = "Flat $flNum";
      }
    }

    final Map<String, String> roomMap = {};
    for (var u in units) {
      if (selectedBuildingId != null && u["building_id"]?.toString() != selectedBuildingId) continue;
      if (selectedFloorId != null && u["floor_id"]?.toString() != selectedFloorId) continue;
      if (selectedFlatId != null && u["flat_id"]?.toString() != selectedFlatId) continue;
      final rId = u["room_id"]?.toString();
      final rNum = u["room_number"]?.toString();
      if (rId != null && rId.isNotEmpty) {
        roomMap[rId] = "Room $rNum";
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 450;
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                        hintText: isSmall ? "Search..." : "Search by building, flat, room...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      onChanged: (val) => setState(() => searchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (isSmall)
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        foregroundColor: const Color(0xFF334155),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.all(14),
                      ),
                      onPressed: () => setState(() => isFiltersExpanded = !isFiltersExpanded),
                      icon: Icon(isFiltersExpanded ? Icons.filter_list_off : Icons.filter_list, size: 18),
                    )
                  else
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        foregroundColor: const Color(0xFF334155),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => setState(() => isFiltersExpanded = !isFiltersExpanded),
                      icon: Icon(isFiltersExpanded ? Icons.filter_list_off : Icons.filter_list, size: 18),
                      label: const Text("Filters", style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                ],
              );
            }
          ),
          if (isFiltersExpanded) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;

              final buildingDropdown = SizedBox(
                width: 170,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedBuildingId,
                  decoration: const InputDecoration(labelText: "Building", border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("All Buildings", overflow: TextOverflow.ellipsis)),
                    ...buildingMap.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (val) {
                    setState(() {
                      selectedBuildingId = val;
                      filterFloors = [];
                    });
                    if (val != null) {
                      fetchFloorsForFilter(val);
                    } else {
                      setState(() {
                        selectedFloorId = null;
                        selectedFlatId = null;
                        selectedRoomId = null;
                      });
                    }
                  },
                ),
              );

              final floorDropdown = SizedBox(
                width: 150,
                child: isFilterFloorsLoading
                    ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                    : DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: selectedFloorId,
                        decoration: const InputDecoration(labelText: "Floor", border: OutlineInputBorder()),
                        items: [
                          const DropdownMenuItem(value: null, child: Text("All Floors", overflow: TextOverflow.ellipsis)),
                          ...filterFloors.map((f) {
                            final dispName = f["floor_name"] != null && f["floor_name"].toString().isNotEmpty
                                ? f["floor_name"]
                                : "Floor ${f["floor_number"]}";
                            return DropdownMenuItem(value: f["id"].toString(), child: Text(dispName.toString(), overflow: TextOverflow.ellipsis));
                          }),
                        ],
                        onChanged: (val) => setState(() {
                          selectedFloorId = val;
                          selectedFlatId = null;
                          selectedRoomId = null;
                        }),
                      ),
              );

              final flatDropdown = SizedBox(
                width: 150,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedFlatId,
                  decoration: const InputDecoration(labelText: "Flat", border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("All Flats", overflow: TextOverflow.ellipsis)),
                    ...flatMap.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (val) => setState(() {
                    selectedFlatId = val;
                    selectedRoomId = null;
                  }),
                ),
              );

              final roomDropdown = SizedBox(
                width: 150,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedRoomId,
                  decoration: const InputDecoration(labelText: "Room", border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("All Rooms", overflow: TextOverflow.ellipsis)),
                    ...roomMap.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (val) => setState(() => selectedRoomId = val),
                ),
              );

              final statusDropdown = SizedBox(
                width: 170,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: "Occupancy Status", border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: null, child: Text("All Status", overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: "vacant", child: Text("Vacant", overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: "partial", child: Text("Partial", overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: "occupied", child: Text("Occupied", overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (val) => setState(() => selectedStatus = val),
                ),
              );

              final policyDropdown = SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: filterOccupancyPolicy,
                  decoration: const InputDecoration(labelText: "Occupancy Policy", border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: null, child: Text("All Policies", overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: "shared", child: Text("Shared Policy", overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: "exclusive", child: Text("Exclusive Policy", overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: "exclusive_occupied", child: Text("Exclusively Occupied", overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (val) => setState(() => filterOccupancyPolicy = val),
                ),
              );

              final sortDropdown = SizedBox(
                width: 170,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedSort,
                  decoration: const InputDecoration(labelText: "Sort By", border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: "recently_changed", child: Text("Recently Changed", overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: "newest", child: Text("Newest Added", overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: "oldest", child: Text("Oldest Added", overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (val) => setState(() => selectedSort = val!),
                ),
              );

              if (isWide) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    buildingDropdown,
                    floorDropdown,
                    flatDropdown,
                    roomDropdown,
                    statusDropdown,
                    policyDropdown,
                    sortDropdown,
                  ],
                );
              } else {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      buildingDropdown,
                      const SizedBox(width: 10),
                      floorDropdown,
                      const SizedBox(width: 10),
                      flatDropdown,
                      const SizedBox(width: 10),
                      roomDropdown,
                      const SizedBox(width: 10),
                      statusDropdown,
                      const SizedBox(width: 10),
                      policyDropdown,
                      const SizedBox(width: 10),
                      sortDropdown,
                    ],
                  ),
                );
              }
            }),
          ],
        ],
      ),
    );
  }

  Widget _unitCard(Map unit) {
    String designation = "Unit Block";
    String detailsPath = "";

    final String bName = unit["building_name"] ?? "";
    final String fNum = unit["floor_number"]?.toString() ?? "";
    final String flNum = unit["flat_number"] ?? "";
    final String rNum = unit["room_number"] ?? "";

    if (rNum.isNotEmpty) {
      designation = "Room $rNum";
      detailsPath = flNum.isNotEmpty ? "$bName > Floor $fNum > Flat $flNum" : "$bName > Floor $fNum";
    } else if (flNum.isNotEmpty) {
      designation = "Flat $flNum";
      detailsPath = "$bName > Floor $fNum";
    } else if (bName.isNotEmpty) {
      designation = bName;
      detailsPath = "Building Structure";
    }

    final int cap = unit["capacity"] ?? 1;
    final int occ = unit["occupied_count"] ?? 0;
    final String unitStatus = (unit["status"] ?? "vacant").toString().toLowerCase();
    final String unitPolicy = (unit["occupancy_type"] ?? "shared").toString().toLowerCase();

    Color statusColor = Colors.green;
    if (unitStatus == "occupied") {
      statusColor = Colors.red;
    } else if (unitStatus == "partial") {
      statusColor = Colors.orange;
    }

    // Determine sharing tag
    final bool sharing = cap > 1;
    final String policyLabel = unitPolicy == "exclusive" ? "EXCLUSIVE" : "SHARED";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${unit["unit_type"].toString().toUpperCase()} ($policyLabel)",
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  unitStatus.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            designation,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            detailsPath,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (unit["exclusive_tenant_name"] != null && unit["exclusive_tenant_name"].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red[100]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, size: 12, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      "Exclusive Tenant: ${unit["exclusive_tenant_name"]}",
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("₹${unit["rent"]} / mo", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                    Text(
                      sharing ? "Sharing ($occ/$cap)" : "Single ($occ/$cap)",
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () => openDialog(unit: unit),
                    icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 20),
                    tooltip: "Edit Asset",
                  ),
                  IconButton(
                    onPressed: () => confirmDeleteUnit(unit),
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                    tooltip: "Purge Asset",
                  ),
                ],
              )
            ],
          ),
        ],
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