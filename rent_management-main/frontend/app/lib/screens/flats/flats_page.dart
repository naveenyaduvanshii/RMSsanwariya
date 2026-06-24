import 'package:flutter/material.dart';

import '../../layout/main_layout.dart';
import '../../services/api_service.dart';

class FlatsPage extends StatefulWidget {
  final String role;
  final String userName;
  final String renterId;

  const FlatsPage({
    super.key,
    required this.role,
    required this.userName,
    required this.renterId,
  });

  @override
  State<FlatsPage> createState() => _FlatsPageState();
}

class _FlatsPageState extends State<FlatsPage> {
  List flats = [];
  List buildings = [];
  List floors = [];

  bool isLoading = true;

  final flatNumberController = TextEditingController();
  final capacityController = TextEditingController();
  final rentController = TextEditingController();
  final searchController = TextEditingController();

  String? selectedBuilding;
  String? selectedFloor;

  String? filterBuilding;
  String? filterFloor;
  String? filterStatus;

  @override
  void initState() {
    super.initState();
    loadFlats();
    loadBuildings();
  }

  @override
  void dispose() {
    flatNumberController.dispose();
    capacityController.dispose();
    rentController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // ---------------- LOAD DATA ----------------

  Future<void> loadFlats() async {
    try {
      final response = await ApiService.get("api/flats/");

      if (!mounted) return;

      setState(() {
        flats = response["data"] ?? [];
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadBuildings() async {
    try {
      final response = await ApiService.get("api/buildings-dropdown/");

      if (!mounted) return;

      setState(() {
        buildings = response["data"] ?? [];
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> loadFloors(String buildingId) async {
    try {
      final response = await ApiService.get(
        "api/floors-by-building/$buildingId/",
      );

      if (!mounted) return;

      setState(() {
        floors = response["data"] ?? [];
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // ---------------- REFRESH ----------------

  Future<void> refreshAll() async {
    await loadFlats();
  }

  // ---------------- CRUD ----------------

  Future<void> addFlat() async {
    try {
      await ApiService.post("api/add-flat/", {
        "building_id": selectedBuilding,
        "floor_id": selectedFloor,
        "flat_number": flatNumberController.text,
        "capacity": int.tryParse(capacityController.text) ?? 1,
        "base_rent": double.tryParse(rentController.text) ?? 0,
      });

      if (mounted) Navigator.pop(context);

      await refreshAll();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> updateFlat(String flatId) async {
    try {
      await ApiService.put("api/update-flat/$flatId/", {
        "building_id": selectedBuilding,
        "floor_id": selectedFloor,
        "flat_number": flatNumberController.text,
        "capacity": int.tryParse(capacityController.text) ?? 1,
        "base_rent": double.tryParse(rentController.text) ?? 0,
      });

      if (mounted) Navigator.pop(context);

      await refreshAll();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> deleteFlat(String flatId) async {
    try {
      await ApiService.delete("api/delete-flat/$flatId/");
      await refreshAll();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // ---------------- FILTER LOGIC ----------------

  List get filteredFlats {
    return flats.where((flat) {
      final search = searchController.text.toLowerCase();

      final matchSearch = search.isEmpty ||
          flat["flat_number"]
              .toString()
              .toLowerCase()
              .contains(search);

      final matchBuilding = filterBuilding == null ||
          flat["building_id"].toString() == filterBuilding;

      final matchFloor = filterFloor == null ||
          flat["floor_id"].toString() == filterFloor;

      final matchStatus = filterStatus == null ||
          flat["status"].toString() == filterStatus;

      return matchSearch && matchBuilding && matchFloor && matchStatus;
    }).toList();
  }

  // ---------------- DIALOG ----------------

  void showFlatDialog({Map? flat}) {
    if (flat != null) {
      flatNumberController.text = flat["flat_number"] ?? "";
      capacityController.text = flat["capacity"].toString();
      rentController.text = flat["base_rent"].toString();

      selectedBuilding = flat["building_id"]?.toString();
      selectedFloor = flat["floor_id"]?.toString();

      if (selectedBuilding != null) {
        loadFloors(selectedBuilding!);
      }
    } else {
      flatNumberController.clear();
      capacityController.clear();
      rentController.clear();

      selectedBuilding = null;
      selectedFloor = null;
      floors = [];
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(flat == null ? "Add Flat" : "Update Flat"),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedBuilding,
                        decoration: const InputDecoration(
                          labelText: "Building",
                          border: OutlineInputBorder(),
                        ),
                        items: buildings.map<DropdownMenuItem<String>>((b) {
                          return DropdownMenuItem(
                            value: b["id"].toString(),
                            child: Text(b["name"].toString()),
                          );
                        }).toList(),
                        onChanged: (value) async {
                          selectedBuilding = value;
                          selectedFloor = null;

                          setDialogState(() {});

                          if (value != null) {
                            await loadFloors(value);
                            setDialogState(() {});
                          }
                        },
                      ),

                      const SizedBox(height: 10),

                      DropdownButtonFormField<String>(
                        value: selectedFloor,
                        decoration: const InputDecoration(
                          labelText: "Floor",
                          border: OutlineInputBorder(),
                        ),
                        items: floors.map<DropdownMenuItem<String>>((f) {
                          return DropdownMenuItem(
                            value: f["id"].toString(),
                            child: Text(
                              f["floor_number"].toString(),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedFloor = value;
                          });
                        },
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: flatNumberController,
                        decoration: const InputDecoration(
                          labelText: "Flat Number",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: capacityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Capacity",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: rentController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Base Rent",
                          border: OutlineInputBorder(),
                        ),
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
                  onPressed: () {
                    if (flat == null) {
                      addFlat();
                    } else {
                      updateFlat(flat["id"].toString());
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      role: widget.role,
      userName: widget.userName,
      renterId: widget.renterId,
      currentIndex: 4,
      child: Column(
        children: [
          // ADD BUTTON
          if (widget.role == "owner" || widget.role == "manager")
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => showFlatDialog(),
                icon: const Icon(Icons.add),
                label: const Text("Add Flat"),
              ),
            ),

          const SizedBox(height: 10),

          // SEARCH + FILTER
          TextField(
            controller: searchController,
            decoration: const InputDecoration(
              labelText: "Search Flat Number",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 10),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                DropdownButton<String>(
                  hint: const Text("Building"),
                  value: filterBuilding,
                  items: buildings.map<DropdownMenuItem<String>>((b) {
                    return DropdownMenuItem(
                      value: b["id"].toString(),
                      child: Text(b["name"].toString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      filterBuilding = value;
                    });
                  },
                ),

                const SizedBox(width: 10),

                DropdownButton<String>(
                  hint: const Text("Status"),
                  value: filterStatus,
                  items: const [
                    DropdownMenuItem(
                        value: "vacant", child: Text("Vacant")),
                    DropdownMenuItem(
                        value: "occupied", child: Text("Occupied")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      filterStatus = value;
                    });
                  },
                ),

                const SizedBox(width: 10),

                TextButton(
                  onPressed: () {
                    setState(() {
                      searchController.clear();
                      filterBuilding = null;
                      filterFloor = null;
                      filterStatus = null;
                    });
                  },
                  child: const Text("Clear"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // LIST
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredFlats.isEmpty
                    ? const Center(child: Text("No Flats Found"))
                    : ListView.builder(
                        itemCount: filteredFlats.length,
                        itemBuilder: (context, index) {
                          final flat = filteredFlats[index];

                          return Card(
                            child: ListTile(
                              leading:
                                  const CircleAvatar(child: Icon(Icons.home)),
                              title: Text(flat["flat_number"] ?? ""),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "${flat["building_name"]} | Floor ${flat["floor_number"]}"),
                                  Text("Rent: ₹${flat["base_rent"]}"),
                                  Text("Status: ${flat["status"]}"),
                                ],
                              ),
                              trailing: widget.role == "owner" ||
                                      widget.role == "manager"
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.blue),
                                          onPressed: () =>
                                              showFlatDialog(flat: flat),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () =>
                                              deleteFlat(flat["id"]),
                                        ),
                                      ],
                                    )
                                  : null,
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