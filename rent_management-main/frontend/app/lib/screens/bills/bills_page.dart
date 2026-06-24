import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../layout/main_layout.dart';

class BillsPage extends StatefulWidget {
  final String role;
  final String userName;
  final String renterId;

  const BillsPage({
    super.key,
    required this.role,
    required this.userName,
    required this.renterId,
  });

  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  final String baseUrl = "http://127.0.0.1:8000";

  List bills = [];
  List assignments = [];
  bool isLoading = true;
  bool isSaving = false;

  // Dialog Form Elements
  String? selectedAssignmentId;
  final TextEditingController monthController = TextEditingController(text: "2026-06-01");
  final TextEditingController rentController = TextEditingController();
  final TextEditingController elecAmountController = TextEditingController(text: "0.0");
  final TextEditingController dueDateController = TextEditingController(text: "2026-06-10");

  // Additional Charge Elements
  final TextEditingController chargeNameController = TextEditingController();
  final TextEditingController chargeAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchBills();
    if (widget.role != "tenant") fetchAssignments();
  }

  @override
  void dispose() {
    monthController.dispose();
    rentController.dispose();
    elecAmountController.dispose();
    dueDateController.dispose();
    chargeNameController.dispose();
    chargeAmountController.dispose();
    super.dispose();
  }

  Future<void> fetchBills() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/bills/"));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (mounted) setState(() => bills = body["data"] ?? []);
      }
    } catch (e) {
      debugPrint("Fetch Bills Error: $e");
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> fetchAssignments() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/tenant-assignments/"));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (mounted) setState(() => assignments = body["data"] ?? []);
      }
    } catch (e) {
      debugPrint("Fetch Leases Error: $e");
    }
  }

  Future<void> issueBill() async {
    if (selectedAssignmentId == null || monthController.text.isEmpty || dueDateController.text.isEmpty) return;
    setState(() => isSaving = true);

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/bills/create/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "assignment_id": selectedAssignmentId,
          "bill_month": monthController.text,
          "rent_amount": rentController.text.isNotEmpty ? double.parse(rentController.text) : null,
          "electricity_amount": double.parse(elecAmountController.text),
          "due_date": dueDateController.text,
        }),
      );

      if (res.statusCode == 201 && mounted) {
        Navigator.pop(context);
        fetchBills();
      }
    } catch (e) {
      debugPrint("Generation Fault: $e");
    }
    if (mounted) setState(() => isSaving = false);
  }

  Future<void> addSurcharge(String billId) async {
    if (chargeNameController.text.isEmpty || chargeAmountController.text.isEmpty) return;

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/additional-charges/create/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "bill_id": billId,
          "charge_name": chargeNameController.text.trim(),
          "charge_amount": double.parse(chargeAmountController.text),
          "notes": "Added via operations dashboard view panel workspace tracker line."
        }),
      );

      if (res.statusCode == 201) {
        chargeNameController.clear();
        chargeAmountController.clear();
        Navigator.pop(context);
        fetchBills();
      }
    } catch (e) {
      debugPrint("Surcharge Error: $e");
    }
  }

  void openBillGenerationDialog() {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Generate Monthly Rent Statement"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedAssignmentId,
                    items: assignments.map((a) {
                      return DropdownMenuItem<String>(
                        value: a["id"].toString(),
                        child: Text("${a['tenant_name']} (Suite: ${a['room_number'] ?? 'Flat'})"),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setDialogState(() {
                        selectedAssignmentId = v;
                        final match = assignments.firstWhere((element) => element["id"].toString() == v, orElse: () => {});
                        if (match.isNotEmpty) {
                          rentController.text = match["final_rent"].toString();
                        }
                      });
                    },
                    decoration: const InputDecoration(labelText: "Active Lease Target Record", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: monthController,
                    decoration: const InputDecoration(labelText: "Billing Period Cycle Start", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: rentController,
                    decoration: const InputDecoration(labelText: "Overriding Base Rent (Optional)", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: elecAmountController,
                    decoration: const InputDecoration(labelText: "Electricity Surcharge Cost Entry (₹)", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dueDateController,
                    decoration: const InputDecoration(labelText: "Payment Settlement Due Date Limit", border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Discard")),
              ElevatedButton(onPressed: isSaving ? null : issueBill, child: const Text("Issue Account Invoice")),
            ],
          );
        },
      ),
    );
  }

  void openSurchargeDialog(String billId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Inject Single-Line Service Surcharge"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: chargeNameController,
              decoration: const InputDecoration(labelText: "Surcharge Fee Type / Title Label", hintText: "e.g., Late Fees / Maintenance", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: chargeAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Surcharge Value Volume (₹)", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => addSurcharge(billId), child: const Text("Append Surcharge")),
        ],
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid': return Colors.green;
      case 'partial': return Colors.orange;
      case 'overdue': return Colors.red;
      default: return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      role: widget.role,
      userName: widget.userName,
      renterId: widget.renterId,
      currentIndex: 9,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Invoicing & Ledger Bills", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                      if (widget.role != "tenant")
                        ElevatedButton.icon(
                          onPressed: openBillGenerationDialog,
                          icon: const Icon(Icons.receipt_long),
                          label: const Text("Generate New Bill Statement"),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: bills.isEmpty
                        ? const Center(child: Text("No invoice records located."))
                        : ListView.builder(
                            itemCount: bills.length,
                            itemBuilder: (context, index) {
                              final b = bills[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: ExpansionTile(
                                  title: Text(
                                    "${b['tenant_name']} — ${b['bill_month'].toString().substring(0, 7)}",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text("Total Owed Matrix: ₹${b['total_amount']} | Due Date: ${b['due_date']}"),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: getStatusColor(b['status']).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      b['status'].toString().toUpperCase(),
                                      style: TextStyle(color: getStatusColor(b['status']), fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [const Text("Contract Rent Base:"), Text("₹${b['rent_amount'] ?? 0}")],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [const Text("Electricity Cost Addendum:"), Text("₹${b['electricity_amount'] ?? 0}")],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [const Text("Additional Miscellaneous Aggregate:"), Text("₹${b['additional_amount'] ?? 0}")],
                                          ),
                                          const Divider(),
                                          ...((b["charges"] as List? ?? []).map((charge) {
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(" • ${charge['charge_name']}:", style: const TextStyle(color: Colors.grey)),
                                                  Text("₹${charge['charge_amount']}", style: const TextStyle(color: Colors.grey)),
                                                ],
                                              ),
                                            );
                                          })),
                                          if (widget.role != "tenant" && b['status'] != 'paid') ...[
                                            const SizedBox(height: 8),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: TextButton.icon(
                                                onPressed: () => openSurchargeDialog(b["id"]),
                                                icon: const Icon(Icons.add_circle_outline, size: 16),
                                                label: const Text("Apply Dynamic Surcharge Line"),
                                              ),
                                            )
                                          ]
                                        ],
                                      ),
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
}