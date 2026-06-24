import 'package:flutter/material.dart';

import '../../layout/main_layout.dart';
import '../../services/api_service.dart';

class RoomsPage extends StatefulWidget {
  final String role;
  final String userName;
  final String renterId;

  const RoomsPage({
    super.key,
    required this.role,
    required this.userName,
    required this.renterId,
  });

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  //////////////////////////////////////////////////////
  /// DATA
  //////////////////////////////////////////////////////

  List<Map<String, dynamic>> rooms = [];
  List<Map<String, dynamic>> filteredRooms = [];

  List<Map<String, dynamic>> buildings = [];
  List<Map<String, dynamic>> floors = [];
  List<Map<String, dynamic>> flats = [];

  bool isLoading = true;
  bool isSaving = false;

  bool isEdit = false;
  String editId = "";

  //////////////////////////////////////////////////////
  /// CONTROLLERS
  //////////////////////////////////////////////////////

  final searchController = TextEditingController();

  final roomNumberController = TextEditingController();
  final roomTypeController = TextEditingController();
  final capacityController = TextEditingController();
  final rentController = TextEditingController();

  //////////////////////////////////////////////////////
  /// FILTERS
  //////////////////////////////////////////////////////

  String? selectedBuilding;
  String? selectedFloor;
  String? selectedFlat;

  //////////////////////////////////////////////////////
  /// INIT
  //////////////////////////////////////////////////////

  @override
  void initState() {
    super.initState();

    loadRooms();
    loadBuildings();
  }

  @override
  void dispose() {
    searchController.dispose();

    roomNumberController.dispose();
    roomTypeController.dispose();
    capacityController.dispose();
    rentController.dispose();

    super.dispose();
  }

  //////////////////////////////////////////////////////
  /// LOAD ROOMS
  //////////////////////////////////////////////////////

  Future<void> loadRooms() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await ApiService.get(
        "api/rooms/",
      );

      rooms = List<Map<String, dynamic>>.from(
        response["data"] ?? [],
      );

      filteredRooms = List<Map<String, dynamic>>.from(
        rooms,
      );
    } catch (e) {
      debugPrint("ROOM ERROR : $e");
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  //////////////////////////////////////////////////////
  /// LOAD BUILDINGS
  //////////////////////////////////////////////////////

  Future<void> loadBuildings() async {
    try {
      final response = await ApiService.get(
        "api/buildings-dropdown/",
      );

      buildings = List<Map<String, dynamic>>.from(
        response["data"] ?? [],
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("BUILDING ERROR : $e");
    }
  }

  //////////////////////////////////////////////////////
  /// LOAD FLOORS
  //////////////////////////////////////////////////////

  Future<void> loadFloors(
    String buildingId,
  ) async {
    try {
      final response = await ApiService.get(
        "api/floors-by-building/$buildingId/",
      );

      floors = List<Map<String, dynamic>>.from(
        response["data"] ?? [],
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("FLOOR ERROR : $e");
    }
  }

  //////////////////////////////////////////////////////
  /// LOAD FLATS
  //////////////////////////////////////////////////////

  Future<void> loadFlats(
    String floorId,
  ) async {
    try {
      final response = await ApiService.get(
        "api/flats-by-floor/$floorId/",
      );

      flats = List<Map<String, dynamic>>.from(
        response["data"] ?? [],
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("FLAT ERROR : $e");
    }
  }

  //////////////////////////////////////////////////////
  /// SEARCH + FILTER
  //////////////////////////////////////////////////////

  void applyFilters() {
    final query =
        searchController.text.trim().toLowerCase();

    filteredRooms = rooms.where((room) {
      bool searchMatch =
          query.isEmpty ||
          room["room_number"]
              .toString()
              .toLowerCase()
              .contains(query) ||
          room["building_name"]
              .toString()
              .toLowerCase()
              .contains(query) ||
          room["flat_number"]
              .toString()
              .toLowerCase()
              .contains(query) ||
          room["room_type"]
              .toString()
              .toLowerCase()
              .contains(query);

      bool buildingMatch =
          selectedBuilding == null ||
          room["building_id"].toString() ==
              selectedBuilding;

      bool floorMatch =
          selectedFloor == null ||
          room["floor_id"].toString() ==
              selectedFloor;

      bool flatMatch =
          selectedFlat == null ||
          room["flat_id"].toString() ==
              selectedFlat;

      return searchMatch &&
          buildingMatch &&
          floorMatch &&
          flatMatch;
    }).toList();

    if (mounted) {
      setState(() {});
    }
  }

  //////////////////////////////////////////////////////
  /// RESET FILTER
  //////////////////////////////////////////////////////

  void resetFilters() {
    searchController.clear();

    selectedBuilding = null;
    selectedFloor = null;
    selectedFlat = null;

    floors.clear();
    flats.clear();

    filteredRooms =
        List<Map<String, dynamic>>.from(rooms);

    setState(() {});
  }

  //////////////////////////////////////////////////////
  /// CLEAR FORM
  //////////////////////////////////////////////////////

  void clearForm() {
    roomNumberController.clear();
    roomTypeController.clear();
    capacityController.clear();
    rentController.clear();

    selectedBuilding = null;
    selectedFloor = null;
    selectedFlat = null;

    floors.clear();
    flats.clear();

    editId = "";
    isEdit = false;
  }
    //////////////////////////////////////////////////////
  /// ADD ROOM
  //////////////////////////////////////////////////////

  Future<void> addRoom() async {
    try {
      setState(() {
        isSaving = true;
      });

      final response = await ApiService.post(
        "api/add-room/",
        {
          "building_id": selectedBuilding,
          "floor_id": selectedFloor,
          "flat_id": (selectedFlat == null || selectedFlat == "") ? null : selectedFlat,
          "room_number": roomNumberController.text.trim(),
          "room_type": roomTypeController.text.trim(),
          "capacity":
              int.tryParse(capacityController.text) ?? 1,
          "base_rent":
              double.tryParse(rentController.text) ?? 0,
        },
      );

      if (response["success"] == true) {
        if (mounted) Navigator.pop(context);

        clearForm();
        await loadRooms();
      }
    } catch (e) {
      debugPrint("ADD ROOM ERROR : $e");
    }

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });
  }

  //////////////////////////////////////////////////////
  /// UPDATE ROOM
  //////////////////////////////////////////////////////

  Future<void> updateRoom() async {
    try {
      setState(() {
        isSaving = true;
      });

      final response = await ApiService.put(
        "api/update-room/$editId/",
        {
          "building_id": selectedBuilding,
          "floor_id": selectedFloor,
          "flat_id": (selectedFlat == null || selectedFlat == "") ? null : selectedFlat,
          "room_number": roomNumberController.text.trim(),
          "room_type": roomTypeController.text.trim(),
          "capacity":
              int.tryParse(capacityController.text) ?? 1,
          "base_rent":
              double.tryParse(rentController.text) ?? 0,
        },
      );

      if (response["success"] == true) {
        if (mounted) Navigator.pop(context);

        clearForm();
        await loadRooms();
      }
    } catch (e) {
      debugPrint("UPDATE ROOM ERROR : $e");
    }

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });
  }

  //////////////////////////////////////////////////////
  /// DELETE ROOM
  //////////////////////////////////////////////////////

  Future<void> deleteRoom(
    String roomId,
  ) async {
    try {
      final response = await ApiService.delete(
        "api/delete-room/$roomId/",
      );

      if (response["success"] == true) {
        await loadRooms();
      }
    } catch (e) {
      debugPrint("DELETE ROOM ERROR : $e");
    }
  }

  //////////////////////////////////////////////////////
  /// CONFIRM DELETE
  //////////////////////////////////////////////////////

  Future<void> confirmDelete(
    String roomId,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Delete Room"),
          content: const Text(
            "Are you sure you want to delete this room?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await deleteRoom(roomId);
    }
  }

  //////////////////////////////////////////////////////
  /// ROOM DIALOG
  //////////////////////////////////////////////////////

  void showRoomDialog({
    Map<String, dynamic>? room,
  }) {
    if (room != null) {
      isEdit = true;
      editId = room["id"].toString();

      roomNumberController.text =
          room["room_number"]?.toString() ?? "";

      roomTypeController.text =
          room["room_type"]?.toString() ?? "";

      capacityController.text =
          room["capacity"]?.toString() ?? "";

      rentController.text =
          room["base_rent"]?.toString() ?? "";

      selectedBuilding =
          room["building_id"]?.toString();

      selectedFloor =
          room["floor_id"]?.toString();

      selectedFlat =
          room["flat_id"]?.toString();

      if (selectedBuilding != null) {
        loadFloors(selectedBuilding!);
      }

      if (selectedFloor != null) {
        loadFlats(selectedFloor!);
      }
    } else {
      clearForm();
    }

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: Text(
                isEdit
                    ? "Update Room"
                    : "Add Room",
              ),

              content: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 500,
                ),

                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [

                      /////////////////////////////////////
                      /// BUILDING
                      /////////////////////////////////////

                      DropdownButtonFormField<String>(
                        value: buildings.any(
                          (e) =>
                              e["id"].toString() ==
                              selectedBuilding,
                        )
                            ? selectedBuilding
                            : null,

                        decoration:
                            const InputDecoration(
                          labelText:
                              "Building",
                          border:
                              OutlineInputBorder(),
                        ),

                        items: buildings.map((b) {
                          return DropdownMenuItem<
                              String>(
                            value: b["id"]
                                .toString(),
                            child: Text(
                              b["name"]
                                  .toString(),
                            ),
                          );
                        }).toList(),

                        onChanged: (value) async {
                          selectedBuilding =
                              value;

                          selectedFloor =
                              null;

                          selectedFlat =
                              null;

                          floors.clear();
                          flats.clear();

                          setDialogState(
                              () {});

                          if (value !=
                              null) {
                            await loadFloors(
                                value);

                            setDialogState(
                                () {});
                          }
                        },
                      ),

                      const SizedBox(
                          height: 12),

                      /////////////////////////////////////
                      /// FLOOR
                      /////////////////////////////////////

                      DropdownButtonFormField<String>(
                        value: floors.any(
                          (e) =>
                              e["id"].toString() ==
                              selectedFloor,
                        )
                            ? selectedFloor
                            : null,

                        decoration:
                            const InputDecoration(
                          labelText:
                              "Floor",
                          border:
                              OutlineInputBorder(),
                        ),

                        items: floors.map((f) {
                          return DropdownMenuItem<
                              String>(
                            value: f["id"]
                                .toString(),
                            child: Text(
                              f["floor_name"]
                                      ?.toString() ??
                                  "Floor ${f["floor_number"]}",
                            ),
                          );
                        }).toList(),

                        onChanged: (value) async {
                          selectedFloor =
                              value;

                          selectedFlat =
                              null;

                          flats.clear();

                          setDialogState(
                              () {});

                          if (value !=
                              null) {
                            await loadFlats(
                                value);

                            setDialogState(
                                () {});
                          }
                        },
                      ),

                      const SizedBox(
                          height: 12),

                      /////////////////////////////////////
                      /// FLAT
                      /////////////////////////////////////

                      DropdownButtonFormField<String>(
                        value: (selectedFlat != null && flats.any(
                          (e) =>
                              e["id"].toString() ==
                              selectedFlat,
                        ))
                            ? selectedFlat
                            : "",

                        decoration:
                            const InputDecoration(
                          labelText:
                              "Flat",
                          border:
                              OutlineInputBorder(),
                        ),

                        items: [
                          const DropdownMenuItem<String>(
                            value: "",
                            child: Text("None (No Flat)"),
                          ),
                          ...flats.map((f) {
                            return DropdownMenuItem<String>(
                              value: f["id"].toString(),
                              child: Text(
                                f["flat_number"].toString(),
                              ),
                            );
                          }),
                        ],

                        onChanged: (value) {
                          setDialogState(() {
                            selectedFlat =
                                value;
                          });
                        },
                      ),

                      const SizedBox(
                          height: 12),

                      TextField(
                        controller:
                            roomNumberController,
                        decoration:
                            const InputDecoration(
                          labelText:
                              "Room Number",
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                          height: 12),

                      DropdownButtonFormField<String>(
                        value: ["Single", "Sharing"].contains(roomTypeController.text)
                            ? roomTypeController.text
                            : null,
                        decoration: const InputDecoration(
                          labelText: "Room Type",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "Single",
                            child: Text("Single"),
                          ),
                          DropdownMenuItem(
                            value: "Sharing",
                            child: Text("Sharing"),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            roomTypeController.text = value ?? "";
                          });
                        },
                      ),

                      const SizedBox(
                          height: 12),

                      TextField(
                        controller:
                            capacityController,
                        keyboardType:
                            TextInputType
                                .number,
                        decoration:
                            const InputDecoration(
                          labelText:
                              "Capacity",
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                          height: 12),

                      TextField(
                        controller:
                            rentController,
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                        ),
                        decoration:
                            const InputDecoration(
                          labelText:
                              "Base Rent",
                          border:
                              OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },
                  child:
                      const Text("Cancel"),
                ),

                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          if (isEdit) {
                            updateRoom();
                          } else {
                            addRoom();
                          }
                        },

                  child: isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEdit
                              ? "Update"
                              : "Save",
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
    //////////////////////////////////////////////////////
  /// BUILD UI
  //////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      role: widget.role,
      userName: widget.userName,
      renterId: widget.renterId,
      currentIndex: 5,

      child: Stack(
        children: [
          isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Column(
                  children: [

                    //////////////////////////////////////////////////////
                    /// SEARCH
                    //////////////////////////////////////////////////////

                    TextField(
                      controller: searchController,
                      onChanged: (value) {
                        applyFilters();
                      },
                      decoration: InputDecoration(
                        hintText: "Search room...",
                        prefixIcon:
                            const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    //////////////////////////////////////////////////////
                    /// FILTERS
                    //////////////////////////////////////////////////////

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [

                        //////////////////////////////////
                        /// BUILDING FILTER
                        //////////////////////////////////

                        SizedBox(
                          width: 220,
                          child:
                              DropdownButtonFormField<
                                  String>(
                            value: buildings.any(
                              (e) =>
                                  e["id"]
                                      .toString() ==
                                  selectedBuilding,
                            )
                                ? selectedBuilding
                                : null,

                            decoration:
                                const InputDecoration(
                              labelText:
                                  "Building",
                              border:
                                  OutlineInputBorder(),
                            ),

                            items: buildings.map((b) {
                              return DropdownMenuItem<
                                  String>(
                                value: b["id"]
                                    .toString(),
                                child: Text(
                                  b["name"]
                                      .toString(),
                                ),
                              );
                            }).toList(),

                            onChanged: (value) async {
                              selectedBuilding =
                                  value;

                              selectedFloor =
                                  null;

                              selectedFlat =
                                  null;

                              floors.clear();
                              flats.clear();

                              if (value != null) {
                                await loadFloors(
                                    value);
                              }

                              applyFilters();
                            },
                          ),
                        ),

                        //////////////////////////////////
                        /// FLOOR FILTER
                        //////////////////////////////////

                        SizedBox(
                          width: 180,
                          child:
                              DropdownButtonFormField<
                                  String>(
                            value: floors.any(
                              (e) =>
                                  e["id"]
                                      .toString() ==
                                  selectedFloor,
                            )
                                ? selectedFloor
                                : null,

                            decoration:
                                const InputDecoration(
                              labelText: "Floor",
                              border:
                                  OutlineInputBorder(),
                            ),

                            items: floors.map((f) {
                              return DropdownMenuItem<
                                  String>(
                                value: f["id"]
                                    .toString(),
                                child: Text(
                                  f["floor_name"]
                                          ?.toString() ??
                                      "Floor ${f["floor_number"]}",
                                ),
                              );
                            }).toList(),

                            onChanged: (value) async {
                              selectedFloor =
                                  value;

                              selectedFlat =
                                  null;

                              flats.clear();

                              if (value != null) {
                                await loadFlats(
                                    value);
                              }

                              applyFilters();
                            },
                          ),
                        ),

                        //////////////////////////////////
                        /// FLAT FILTER
                        //////////////////////////////////

                        SizedBox(
                          width: 180,
                          child:
                              DropdownButtonFormField<
                                  String>(
                            value: flats.any(
                              (e) =>
                                  e["id"]
                                      .toString() ==
                                  selectedFlat,
                            )
                                ? selectedFlat
                                : null,

                            decoration:
                                const InputDecoration(
                              labelText: "Flat",
                              border:
                                  OutlineInputBorder(),
                            ),

                            items: flats.map((f) {
                              return DropdownMenuItem<
                                  String>(
                                value: f["id"]
                                    .toString(),
                                child: Text(
                                  f["flat_number"]
                                      .toString(),
                                ),
                              );
                            }).toList(),

                            onChanged: (value) {
                              selectedFlat =
                                  value;

                              applyFilters();
                            },
                          ),
                        ),

                        //////////////////////////////////
                        /// RESET FILTER
                        //////////////////////////////////

                        ElevatedButton.icon(
                          onPressed: resetFilters,
                          icon: const Icon(
                            Icons.refresh,
                          ),
                          label:
                              const Text("Reset"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    //////////////////////////////////////////////////////
                    /// ROOM LIST
                    //////////////////////////////////////////////////////

                    Expanded(
                      child: filteredRooms.isEmpty
                          ? const Center(
                              child: Text(
                                "No Rooms Found",
                              ),
                            )
                          : ListView.builder(
                              itemCount:
                                  filteredRooms.length,

                              itemBuilder:
                                  (context, index) {
                                final room =
                                    filteredRooms[
                                        index];

                                return Container(
                                  margin:
                                      const EdgeInsets
                                          .only(
                                    bottom: 12,
                                  ),

                                  padding:
                                      const EdgeInsets
                                          .all(14),

                                  decoration:
                                      BoxDecoration(
                                    color:
                                        Colors.white,

                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                16),

                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius:
                                            10,
                                        color: Colors
                                            .black
                                            .withOpacity(
                                                0.05),
                                      ),
                                    ],
                                  ),

                                  child: Row(
                                    children: [

                                      //////////////////////////////////
                                      /// ICON
                                      //////////////////////////////////

                                      const CircleAvatar(
                                        child: Icon(
                                          Icons
                                              .meeting_room,
                                        ),
                                      ),

                                      const SizedBox(
                                        width: 12,
                                      ),

                                      //////////////////////////////////
                                      /// DETAILS
                                      //////////////////////////////////

                                      Expanded(
                                        child:
                                            Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,

                                          children: [
                                            Text(
                                              room["room_number"]
                                                      ?.toString() ??
                                                  "",

                                              style:
                                                  const TextStyle(
                                                fontSize:
                                                    16,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),

                                            const SizedBox(
                                                height:
                                                    4),

                                            Text(
                                              "${room["building_name"] ?? ""} • Floor ${room["floor_number"] ?? ""}",

                                              style:
                                                  const TextStyle(
                                                color:
                                                    Colors.grey,
                                              ),
                                            ),

                                            Text(
                                              "Flat : ${room["flat_number"] ?? "-"}",
                                              style:
                                                  const TextStyle(
                                                color:
                                                    Colors.grey,
                                              ),
                                            ),

                                            Text(
                                              "Type : ${room["room_type"] ?? "-"}",
                                            ),

                                            Text(
                                              "Capacity : ${room["capacity"]}",
                                            ),

                                            Text(
                                              "Rent : ₹${room["base_rent"]}",
                                            ),
                                          ],
                                        ),
                                      ),

                                      //////////////////////////////////
                                      /// ACTIONS
                                      //////////////////////////////////

                                      if (widget.role ==
                                              "owner" ||
                                          widget.role ==
                                              "manager")
                                        Wrap(
                                          children: [
                                            IconButton(
                                              icon:
                                                  const Icon(
                                                Icons
                                                    .edit,
                                                color: Colors
                                                    .blue,
                                              ),
                                              onPressed:
                                                  () {
                                                showRoomDialog(
                                                  room:
                                                      room,
                                                );
                                              },
                                            ),

                                            IconButton(
                                              icon:
                                                  const Icon(
                                                Icons
                                                    .delete,
                                                color: Colors
                                                    .red,
                                              ),
                                              onPressed:
                                                  () {
                                                confirmDelete(
                                                  room["id"]
                                                      .toString(),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),

          //////////////////////////////////////////////////////
          /// FLOATING BUTTON
          //////////////////////////////////////////////////////

          if (widget.role == "owner" ||
              widget.role == "manager")
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton(
                onPressed: () {
                  showRoomDialog();
                },
                child: const Icon(
                  Icons.add,
                ),
              ),
            ),
        ],
      ),
    );
  }
}