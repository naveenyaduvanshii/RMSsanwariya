import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../layout/main_layout.dart';

class ComplaintsPage extends StatefulWidget {
  final String role;
  final String userName;
  final String? renterId;

  const ComplaintsPage({
    super.key,
    required this.role,
    required this.userName,
    required this.renterId,
  });

  @override
  State<ComplaintsPage> createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends State<ComplaintsPage> {
  ////////////////////////////////////////////////////////////
  /// BASE URL
  ////////////////////////////////////////////////////////////

  final String baseUrl = "http://127.0.0.1:8000";

  ////////////////////////////////////////////////////////////
  /// CONTROLLERS
  ////////////////////////////////////////////////////////////

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  ////////////////////////////////////////////////////////////
  /// DATA
  ////////////////////////////////////////////////////////////

  List complaints = [];
  List users = [];

  String? selectedPriority = "medium";
  String? selectedAssignedTo;

  bool isLoading = true;
  bool isSaving = false;

  String editId = "";
  bool isEdit = false;

  ////////////////////////////////////////////////////////////
  /// INIT
  ////////////////////////////////////////////////////////////

  @override
  void initState() {
    super.initState();
    fetchComplaints();
    fetchUsers();
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
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  ////////////////////////////////////////////////////////////
  /// FETCH USERS (for assignment)
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
  /// CREATE COMPLAINT (TENANT)
  ////////////////////////////////////////////////////////////

  Future<void> createComplaint() async {
    if (titleController.text.isEmpty) return;

    setState(() => isSaving = true);

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/create-complaint/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "tenant_id": widget.renterId,
          "assignment_id": null,
          "title": titleController.text,
          "description": descController.text,
          "priority": selectedPriority,
          "assigned_to": selectedAssignedTo,
        }),
      );

      if (res.statusCode == 200) {
        Navigator.pop(context);
        clear();
        fetchComplaints();
      }
    } catch (e) {}

    setState(() => isSaving = false);
  }

  ////////////////////////////////////////////////////////////
  /// UPDATE COMPLAINT (MANAGER/OWNER)
  ////////////////////////////////////////////////////////////

  Future<void> updateComplaint() async {
    setState(() => isSaving = true);

    try {
      final res = await http.put(
        Uri.parse("$baseUrl/api/update-complaint/$editId/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "title": titleController.text,
          "description": descController.text,
          "priority": selectedPriority,
          "status": "in_progress",
          "assigned_to": selectedAssignedTo,
        }),
      );

      if (res.statusCode == 200) {
        Navigator.pop(context);
        clear();
        fetchComplaints();
      }
    } catch (e) {}

    setState(() => isSaving = false);
  }

  ////////////////////////////////////////////////////////////
  /// DELETE COMPLAINT (OWNER ONLY)
  ////////////////////////////////////////////////////////////

  Future<void> deleteComplaint(String id) async {
    try {
      await http.delete(
        Uri.parse("$baseUrl/api/delete-complaint/$id/"),
      );

      fetchComplaints();
    } catch (e) {}
  }

  ////////////////////////////////////////////////////////////
  /// CLEAR
  ////////////////////////////////////////////////////////////

  void clear() {
    titleController.clear();
    descController.clear();
    selectedPriority = "medium";
    selectedAssignedTo = null;
    isEdit = false;
    editId = "";
  }

  ////////////////////////////////////////////////////////////
  /// OPEN DIALOG
  ////////////////////////////////////////////////////////////

  void openDialog({Map? c}) {
    if (c != null) {
      isEdit = true;
      editId = c["id"];

      titleController.text = c["title"] ?? "";
      descController.text = c["description"] ?? "";
      selectedPriority = c["priority"];
    } else {
      clear();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? "Update Complaint" : "Create Complaint"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Title",
                ),
              ),

              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: "Description",
                ),
              ),

              DropdownButtonFormField(
                value: selectedPriority,
                items: const [
                  DropdownMenuItem(value: "low", child: Text("Low")),
                  DropdownMenuItem(value: "medium", child: Text("Medium")),
                  DropdownMenuItem(value: "high", child: Text("High")),
                ],
                onChanged: (v) {
                  selectedPriority = v.toString();
                },
                decoration:
                    const InputDecoration(labelText: "Priority"),
              ),

              //////////////////////////////////////////////////////
              /// ASSIGN TO (OWNER/MANAGER)
              //////////////////////////////////////////////////////

              if (widget.role != "tenant")
                DropdownButtonFormField(
                  value: selectedAssignedTo,
                  items: users.map((u) {
                    return DropdownMenuItem(
                      value: u["id"],
                      child: Text("${u["name"]} (${u["role"]})"),
                    );
                  }).toList(),
                  onChanged: (v) {
                    selectedAssignedTo = v.toString();
                  },
                  decoration: const InputDecoration(
                    labelText: "Assign To",
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
                    ? updateComplaint
                    : createComplaint,
            child: Text(isEdit ? "Update" : "Create"),
          ),
        ],
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// STATUS COLOR
  ////////////////////////////////////////////////////////////

  Color getStatusColor(String status) {
    switch (status) {
      case "open":
        return Colors.red;
      case "in_progress":
        return Colors.orange;
      case "resolved":
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
      renterId: widget.renterId ??"",
      currentIndex: 12,
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
                  color: Colors.deepPurple,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Complaints",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),

                      ElevatedButton(
                        onPressed: () => openDialog(),
                        child: const Text("New Complaint"),
                      )
                    ],
                  ),
                ),

                //////////////////////////////////////////////////////
                /// LIST
                //////////////////////////////////////////////////////

                Expanded(
                  child: ListView.builder(
                    itemCount: complaints.length,
                    itemBuilder: (context, index) {
                      final c = complaints[index];

                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: ListTile(
                          title: Text(c["title"]),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(c["description"] ?? ""),
                              const SizedBox(height: 5),
                              Text(
                                "Priority: ${c["priority"]}",
                              ),
                              Text(
                                "Status: ${c["status"]}",
                                style: TextStyle(
                                  color: getStatusColor(
                                      c["status"]),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          trailing: PopupMenuButton(
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                child: const Text("Edit"),
                                onTap: () {
                                  Future.delayed(
                                    Duration.zero,
                                    () => openDialog(c: c),
                                  );
                                },
                              ),

                              if (widget.role == "owner")
                                PopupMenuItem(
                                  child: const Text("Delete"),
                                  onTap: () {
                                    Future.delayed(
                                      Duration.zero,
                                      () => deleteComplaint(c["id"]),
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