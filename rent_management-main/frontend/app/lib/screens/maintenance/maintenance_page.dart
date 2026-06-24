import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../layout/main_layout.dart';

class MaintenancePage extends StatefulWidget {
  final String role;
  final String userName;
  final String renterId;

  const MaintenancePage({
    super.key,
    required this.role,
    required this.userName,
    required this.renterId,
  });

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  ////////////////////////////////////////////////////////////
  /// BASE URL
  ////////////////////////////////////////////////////////////

  final String baseUrl = "http://127.0.0.1:8000";

  ////////////////////////////////////////////////////////////
  /// DATA
  ////////////////////////////////////////////////////////////

  List requests = [];
  List complaints = [];
  List users = [];

  bool isLoading = true;
  bool isSaving = false;

  String? selectedComplaint;
  String? selectedAssignee;
  String notes = "";

  String editId = "";
  bool isEdit = false;

  ////////////////////////////////////////////////////////////
  /// INIT
  ////////////////////////////////////////////////////////////

  @override
  void initState() {
    super.initState();
    fetchMaintenance();
    fetchComplaints();
    fetchUsers();
  }

  ////////////////////////////////////////////////////////////
  /// FETCH MAINTENANCE
  ////////////////////////////////////////////////////////////

  Future<void> fetchMaintenance() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/maintenance-requests/"),
      );

      if (res.statusCode == 200) {
        setState(() {
          requests = jsonDecode(res.body)["data"];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  ////////////////////////////////////////////////////////////
  /// FETCH COMPLAINTS
  ////////////////////////////////////////////////////////////

  Future<void> fetchComplaints() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/complaints/"),
      );

      if (res.statusCode == 200) {
        setState(() {
          complaints = jsonDecode(res.body)["data"];
        });
      }
    } catch (e) {}
  }

  ////////////////////////////////////////////////////////////
  /// FETCH USERS (TECHNICIANS / MANAGERS)
  ////////////////////////////////////////////////////////////

  Future<void> fetchUsers() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/users/"),
      );

      if (res.statusCode == 200) {
        setState(() {
          users = jsonDecode(res.body)["data"];
        });
      }
    } catch (e) {}
  }

  ////////////////////////////////////////////////////////////
  /// CREATE MAINTENANCE REQUEST
  ////////////////////////////////////////////////////////////

  Future<void> createRequest() async {
    if (selectedComplaint == null) return;

    setState(() => isSaving = true);

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/create-maintenance-request/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "complaint_id": selectedComplaint,
          "assigned_to": selectedAssignee,
          "notes": notes,
        }),
      );

      if (res.statusCode == 200) {
        Navigator.pop(context);
        clear();
        fetchMaintenance();
      }
    } catch (e) {}

    setState(() => isSaving = false);
  }

  ////////////////////////////////////////////////////////////
  /// UPDATE MAINTENANCE
  ////////////////////////////////////////////////////////////

  Future<void> updateRequest() async {
    setState(() => isSaving = true);

    try {
      final res = await http.put(
        Uri.parse("$baseUrl/api/update-maintenance-request/$editId/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "notes": notes,
          "status": "completed",
          "assigned_to": selectedAssignee,
        }),
      );

      if (res.statusCode == 200) {
        Navigator.pop(context);
        clear();
        fetchMaintenance();
      }
    } catch (e) {}

    setState(() => isSaving = false);
  }

  ////////////////////////////////////////////////////////////
  /// CLEAR
  ////////////////////////////////////////////////////////////

  void clear() {
    selectedComplaint = null;
    selectedAssignee = null;
    notes = "";
    isEdit = false;
    editId = "";
  }

  ////////////////////////////////////////////////////////////
  /// OPEN DIALOG
  ////////////////////////////////////////////////////////////

  void openDialog({Map? req}) {
    if (req != null) {
      isEdit = true;
      editId = req["id"];
      notes = req["notes"] ?? "";
    } else {
      clear();
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(isEdit
                ? "Update Maintenance"
                : "Create Maintenance Request"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  //////////////////////////////////////////////////////
                  /// COMPLAINT SELECT
                  //////////////////////////////////////////////////////

                  if (!isEdit)
                    DropdownButtonFormField(
                      value: selectedComplaint,
                      items: complaints.map((c) {
                        return DropdownMenuItem(
                          value: c["id"],
                          child: Text(c["title"]),
                        );
                      }).toList(),
                      onChanged: (v) {
                        setStateDialog(() {
                          selectedComplaint = v.toString();
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: "Complaint",
                      ),
                    ),

                  const SizedBox(height: 10),

                  //////////////////////////////////////////////////////
                  /// ASSIGN TO
                  //////////////////////////////////////////////////////

                  DropdownButtonFormField(
                    value: selectedAssignee,
                    items: users.map((u) {
                      return DropdownMenuItem(
                        value: u["id"],
                        child: Text("${u["name"]} (${u["role"]})"),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setStateDialog(() {
                        selectedAssignee = v.toString();
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: "Assign Technician",
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    onChanged: (v) => notes = v,
                    controller: TextEditingController(text: notes),
                    decoration: const InputDecoration(
                      labelText: "Notes",
                    ),
                  ),
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
                    : isEdit
                        ? updateRequest
                        : createRequest,
                child: Text(isEdit ? "Complete" : "Create"),
              ),
            ],
          );
        },
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// STATUS COLOR
  ////////////////////////////////////////////////////////////

  Color getColor(String status) {
    switch (status) {
      case "pending":
        return Colors.red;
      case "in_progress":
        return Colors.orange;
      case "completed":
        return Colors.green;
      default:
        return Colors.grey;
    }
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
      currentIndex: 13,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                //////////////////////////////////////////////////////
                /// HEADER
                //////////////////////////////////////////////////////

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: Colors.teal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Maintenance System",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                        ),
                      ),

                      ElevatedButton(
                        onPressed: () => openDialog(),
                        child: const Text("New Request"),
                      )
                    ],
                  ),
                ),

                //////////////////////////////////////////////////////
                /// LIST
                //////////////////////////////////////////////////////

                Expanded(
                  child: ListView.builder(
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final r = requests[index];

                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: ListTile(
                          title: Text(r["complaint_title"]),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text("Tenant: ${r["tenant_name"]}"),
                              Text("Notes: ${r["notes"]}"),
                              Text(
                                "Status: ${r["status"]}",
                                style: TextStyle(
                                  color: getColor(r["status"]),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Assigned: ${r["assigned_to"]}",
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                child: const Text("Complete"),
                                onTap: () {
                                  Future.delayed(
                                    Duration.zero,
                                    () {
                                      editId = r["id"];
                                      notes = r["notes"];
                                      selectedAssignee =
                                          r["assigned_to"];
                                      updateRequest();
                                    },
                                  );
                                },
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