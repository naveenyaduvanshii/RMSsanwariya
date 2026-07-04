import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../layout/main_layout.dart';

class VacatePipelinePage extends StatefulWidget {
  final String role;
  final String userName;
  final String renterId;

  const VacatePipelinePage({
    super.key,
    required this.role,
    required this.userName,
    required this.renterId,
  });

  @override
  State<VacatePipelinePage> createState() =>
      _VacatePipelinePageState();
}

class _VacatePipelinePageState
    extends State<VacatePipelinePage> {

  final String baseUrl = "http://127.0.0.1:8000";

  List notices = [];
  bool loading = true;

  final TextEditingController reasonController = TextEditingController();
  DateTime? selectedVacateDate;
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  String? activeAssignmentId;

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
              activeAssignmentId = item["id"].toString();
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
    fetchActiveAssignment();
    fetchNotices();
  }

  Future<void> fetchNotices() async {
    setState(() => loading = true);
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/vacate/list/"),
      );

      if (res.statusCode == 200) {
        setState(() {
          notices = jsonDecode(res.body);
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  ////////////////////////////////////////////////////////////
  /// ACTIONS
  ////////////////////////////////////////////////////////////

  Future<void> approve(String id) async {
    await http.post(
      Uri.parse("$baseUrl/api/vacate/$id/approve/"),
    );
    fetchNotices();
  }

  Future<void> reject(String id) async {
    await http.post(
      Uri.parse("$baseUrl/api/vacate/$id/reject/"),
    );
    fetchNotices();
  }

  Future<void> complete(String id) async {
    await http.post(
      Uri.parse("$baseUrl/api/vacate/$id/complete/"),
    );
    fetchNotices();
  }

  void openCreateNoticeDialog() {
    if (activeAssignmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No active assignment found. Cannot submit vacate request.")),
      );
      return;
    }

    reasonController.clear();
    selectedVacateDate = null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Request Vacate Notice"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Reason for Vacating",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedVacateDate == null
                                ? "Choose Vacate Date"
                                : "Vacate Date: ${selectedVacateDate!.year}-${selectedVacateDate!.month.toString().padLeft(2, '0')}-${selectedVacateDate!.day.toString().padLeft(2, '0')}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today, color: Colors.deepPurple),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedVacateDate = picked;
                              });
                            }
                          },
                        ),
                      ],
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
                  onPressed: () async {
                    if (selectedVacateDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select a vacate date")),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    await submitVacateNotice();
                  },
                  child: const Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> submitVacateNotice() async {
    setState(() => loading = true);
    try {
      final String todayStr = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
      final String vacateStr = "${selectedVacateDate!.year}-${selectedVacateDate!.month.toString().padLeft(2, '0')}-${selectedVacateDate!.day.toString().padLeft(2, '0')}";
      
      final response = await http.post(
        Uri.parse("$baseUrl/api/vacate/create/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "tenant": widget.renterId,
          "assignment": activeAssignmentId,
          "notice_date": todayStr,
          "vacate_date": vacateStr,
          "reason": reasonController.text,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        fetchNotices();
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${err['error'] ?? 'Failed to submit'}")),
        );
        setState(() => loading = false);
      }
    } catch (e) {
      debugPrint("Error submitting notice: $e");
      setState(() => loading = false);
    }
  }

  List getFilteredNotices() {
    // If tenant, only show their own notices
    final filtered = widget.role == "tenant"
        ? notices.where((n) => n["tenant"].toString() == widget.renterId).toList()
        : notices;

    if (searchQuery.isEmpty) return filtered;
    final q = searchQuery.toLowerCase();
    return filtered.where((n) {
      final name = (n["tenant_name"] ?? "").toString().toLowerCase();
      final phone = (n["tenant_phone"] ?? "").toString().toLowerCase();
      return name.contains(q) || phone.contains(q);
    }).toList();
  }

  ////////////////////////////////////////////////////////////
  /// UI
  ////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    final filtered = getFilteredNotices();

    return MainLayout(
      role: widget.role,
      userName: widget.userName,
      renterId: widget.renterId,
      currentIndex: 15,
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (widget.role == "tenant") ...[
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: openCreateNoticeDialog,
                        icon: const Icon(Icons.logout),
                        label: const Text("Request Vacate / Notice"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ],

                //////////////////////////////////////////////////////
                /// SEARCH BAR (Owner / Manager Only)
                //////////////////////////////////////////////////////

                if (widget.role != "tenant") ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: "Search by tenant name or mobile...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    searchController.clear();
                                    searchQuery = "";
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) {
                        setState(() {
                          searchQuery = val;
                        });
                      },
                    ),
                  ),
                ],

                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text("No vacate notices match selection"))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final n = filtered[index];
                            return _pipelineCard(n);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// PIPELINE CARD (ALL IN ONE)
  ////////////////////////////////////////////////////////////

  Widget _pipelineCard(Map n) {

    bool isPending = n["status"] == "pending";
    bool isApproved = n["status"] == "approved";
    bool isRejected = n["status"] == "rejected";
    bool isCompleted = n["status"] == "completed";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),

      padding: const EdgeInsets.all(20),

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

          //////////////////////////////////////////////////////
          /// HEADER
          //////////////////////////////////////////////////////

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.role == "tenant"
                      ? "Tenant: ${n['tenant_name'] ?? n['tenant']}"
                      : "Tenant: ${n['tenant_name'] ?? n['tenant']} (${n['tenant_phone'] ?? ''})",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(n["status"]),
            ],
          ),

          const SizedBox(height: 15),

          if (n["building_name"] != null && n["building_name"].toString().isNotEmpty) ...[
            Text(
              "Unit: ${n["building_name"]} - Flat: ${n["flat_number"] ?? ''} - Room: ${n["room_number"] ?? ''}",
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 5),
          ],

          Text("Vacate Date: ${n['vacate_date']}"),
          Text("Reason: ${n['reason'] ?? ''}"),

          const SizedBox(height: 20),

          //////////////////////////////////////////////////////
          /// PIPELINE TIMELINE (SINGLE VIEW)
          //////////////////////////////////////////////////////

          _step("1. Request Submitted", true),

          _step("2. Owner Review",
              !isPending),

          _step("3. Approval Decision",
              isApproved || isRejected),

          _step("4. Checkout Check",
              isApproved),

          _step("5. Room Release",
              isCompleted),

          const SizedBox(height: 20),

          //////////////////////////////////////////////////////
          /// ACTIONS (ROLE BASED)
          //////////////////////////////////////////////////////

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ////////////////////////////////////////////////////
              /// OWNER ACTIONS
              ////////////////////////////////////////////////////
              if (widget.role == "owner" && isPending) ...[
                ElevatedButton.icon(
                  onPressed: () => approve(n["id"]),
                  icon: const Icon(Icons.check),
                  label: const Text("Approve"),
                ),
                OutlinedButton.icon(
                  onPressed: () => reject(n["id"]),
                  icon: const Icon(Icons.close),
                  label: const Text("Reject"),
                ),
              ],

              ////////////////////////////////////////////////////
              /// FINAL CHECKOUT
              ////////////////////////////////////////////////////
              if (widget.role == "owner" && isApproved) ...[
                ElevatedButton.icon(
                  onPressed: () => complete(n["id"]),
                  icon: const Icon(Icons.logout),
                  label: const Text("Complete Checkout"),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// STATUS BADGE
  ////////////////////////////////////////////////////////////

  Widget _statusBadge(String status) {

    Color color = Colors.grey;

    if (status == "approved") color = Colors.green;
    if (status == "rejected") color = Colors.red;
    if (status == "completed") color = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),

      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// STEP UI
  ////////////////////////////////////////////////////////////

  Widget _step(String title, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),

      child: Row(
        children: [

          Icon(
            done
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: done ? Colors.green : Colors.grey,
            size: 20,
          ),

          const SizedBox(width: 10),

          Text(title),
        ],
      ),
    );
  }
}