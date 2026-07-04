import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
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

  // Search & Filter state
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  String statusFilter = "all"; // all, paid, unpaid
  String? selectedBuilding; // building name filter
  String? selectedFloor; // floor number filter string
  String overdueFilter = "all"; // all, overdue, 1month, 2months, 3months
  String sortBy = "month_desc"; // month_desc, month_asc, unpaid_first, paid_first
  String? selectedMonth; // month filter (e.g. YYYY-MM)

  // Dialog Form Controllers
  String? selectedAssignmentId;
  final TextEditingController monthController = TextEditingController();
  final TextEditingController rentController = TextEditingController();
  final TextEditingController elecAmountController = TextEditingController(text: "0.0");
  final TextEditingController dueDateController = TextEditingController();

  // Record Payment Dialog Controllers
  final TextEditingController paymentAmountController = TextEditingController();
  final TextEditingController paymentUtrController = TextEditingController();
  String selectedPaymentMode = "cash";

  // Additional Charge Controllers
  final TextEditingController chargeNameController = TextEditingController();
  final TextEditingController chargeAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default dates for billing period creation (default to current month)
    final now = DateTime.now();
    monthController.text = "${now.year}-${now.month.toString().padLeft(2, '0')}-01";
    dueDateController.text = "${now.year}-${now.month.toString().padLeft(2, '0')}-10";
    
    fetchBills();
    if (widget.role != "tenant") fetchAssignments();
  }

  @override
  void dispose() {
    searchController.dispose();
    monthController.dispose();
    rentController.dispose();
    elecAmountController.dispose();
    dueDateController.dispose();
    paymentAmountController.dispose();
    paymentUtrController.dispose();
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
        if (mounted) {
          setState(() {
            bills = body["data"] ?? [];
          });
        }
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
      debugPrint("Fetch Assignments Error: $e");
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

  Future<void> recordPayment(String billId) async {
    if (paymentAmountController.text.isEmpty) return;
    setState(() => isSaving = true);

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/payments/create/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "bill_id": billId,
          "amount_paid": double.parse(paymentAmountController.text),
          "payment_mode": selectedPaymentMode,
          "utr_number": selectedPaymentMode == "upi" ? paymentUtrController.text.trim() : "",
          "received_by": null,
        }),
      );

      if (res.statusCode == 200 && mounted) {
        Navigator.pop(context);
        paymentAmountController.clear();
        paymentUtrController.clear();
        fetchBills();
      }
    } catch (e) {
      debugPrint("Record Payment Error: $e");
    }
    if (mounted) setState(() => isSaving = false);
  }

  Future<void> addSurcharge(String billId) async {
    if (chargeNameController.text.isEmpty || chargeAmountController.text.isEmpty) return;

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/charges/create/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "bill_id": billId,
          "charge_name": chargeNameController.text.trim(),
          "charge_amount": double.parse(chargeAmountController.text),
          "notes": "Added from Rent Manager Panel"
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

  // DIALOGS
  void openBillGenerationDialog() {
    selectedAssignmentId = null;
    rentController.clear();
    elecAmountController.text = "0.0";
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Generate Rent Bill"),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedAssignmentId,
                      items: assignments.map((a) {
                        String suite = "";
                        if (a['room_number'] != null && a['room_number'].toString().isNotEmpty) {
                          suite = "Room ${a['room_number']}";
                        } else if (a['flat_number'] != null && a['flat_number'].toString().isNotEmpty) {
                          suite = "Flat ${a['flat_number']}";
                        } else {
                          suite = "Suite";
                        }
                        return DropdownMenuItem<String>(
                          value: a["id"].toString(),
                          child: Text("${a['tenant_name']} ($suite)"),
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
                      decoration: const InputDecoration(labelText: "Select Tenant Assignment", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: monthController,
                      decoration: const InputDecoration(labelText: "Billing Month (YYYY-MM-DD)", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: rentController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Rent Amount (₹)", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: elecAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Electricity Bill (₹)", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dueDateController,
                      decoration: const InputDecoration(labelText: "Due Date (YYYY-MM-DD)", border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(onPressed: isSaving ? null : issueBill, child: const Text("Generate Bill")),
            ],
          );
        },
      ),
    );
  }

  void openRecordPaymentDialog(Map bill) {
    paymentAmountController.text = bill["total_amount"].toString();
    paymentUtrController.clear();
    selectedPaymentMode = "cash";

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Record Payment for ${bill["tenant_name"]}"),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Total Due: ₹${bill["total_amount"]}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 15),
                    TextField(
                      controller: paymentAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Amount Received (₹)", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedPaymentMode,
                      items: const [
                        DropdownMenuItem(value: "cash", child: Text("Cash")),
                        DropdownMenuItem(value: "upi", child: Text("UPI / Online")),
                      ],
                      onChanged: (v) {
                        setDialogState(() {
                          selectedPaymentMode = v ?? "cash";
                        });
                      },
                      decoration: const InputDecoration(labelText: "Payment Mode", border: OutlineInputBorder()),
                    ),
                    if (selectedPaymentMode == "upi") ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: paymentUtrController,
                        decoration: const InputDecoration(labelText: "UTR / Transaction ID (Optional)", border: OutlineInputBorder()),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: isSaving ? null : () => recordPayment(bill["id"]),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: const Text("Mark Paid"),
              ),
            ],
          );
        },
      ),
    );
  }

  void openSurchargeDialog(String billId) {
    chargeNameController.clear();
    chargeAmountController.clear();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Apply Extra Surcharge / Fine"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: chargeNameController,
              decoration: const InputDecoration(labelText: "Charge Label (e.g. Penalty, Cleaning)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: chargeAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount (₹)", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => addSurcharge(billId), child: const Text("Add Charge")),
        ],
      ),
    );
  }

  // filtering logic
  List getFilteredBills() {
    final now = DateTime.now();
    final res = bills.where((b) {
      if (widget.role == "tenant" && b["tenant_id"]?.toString() != widget.renterId) {
        return false;
      }

      // 1. Search Query (tenant name & mobile no)
      final name = b["tenant_name"].toString().toLowerCase();
      final phone = b["tenant_phone"].toString().toLowerCase();
      final query = searchQuery.toLowerCase();
      if (!name.contains(query) && !phone.contains(query)) {
        return false;
      }

      // Month filter
      if (selectedMonth != null) {
        final monthStr = b["bill_month"].toString().substring(0, 7);
        if (monthStr != selectedMonth) return false;
      }

      // 2. Status filter
      final status = b["status"].toString().toLowerCase();
      if (statusFilter == "paid" && status != "paid") return false;
      if (statusFilter == "unpaid" && status == "paid") return false;

      // 3. Building filter
      if (selectedBuilding != null && b["building_name"] != selectedBuilding) {
        return false;
      }

      // 4. Floor filter
      if (selectedFloor != null && b["floor_number"]?.toString() != selectedFloor) {
        return false;
      }

      // 5. Overdue/Aging filters for unpaid bills
      if (status != "paid" && overdueFilter != "all") {
        final dueStr = b["due_date"].toString();
        if (dueStr.isNotEmpty) {
          final due = DateTime.parse(dueStr);
          final monthStr = b["bill_month"].toString();
          final billMonth = monthStr.isNotEmpty ? DateTime.parse(monthStr) : due;
          
          if (overdueFilter == "overdue") {
            // Unpaid from due date (current time past due date)
            if (!due.isBefore(now)) return false;
          } else {
            // Months difference from billMonth
            final diffDays = now.difference(billMonth).inDays;
            if (overdueFilter == "1month" && diffDays < 30) return false;
            if (overdueFilter == "2months" && diffDays < 60) return false;
            if (overdueFilter == "3months" && diffDays < 90) return false;
          }
        } else {
          return false; // has no due date -> doesn't match aging
        }
      }

      return true;
    }).toList();

    // Sorting logic
    if (sortBy == "month_desc") {
      res.sort((a, b) => b["bill_month"].compareTo(a["bill_month"]));
    } else if (sortBy == "month_asc") {
      res.sort((a, b) => a["bill_month"].compareTo(b["bill_month"]));
    } else if (sortBy == "unpaid_first") {
      res.sort((a, b) {
        if (a["status"] != "paid" && b["status"] == "paid") return -1;
        if (a["status"] == "paid" && b["status"] != "paid") return 1;
        return b["bill_month"].compareTo(a["bill_month"]);
      });
    } else if (sortBy == "paid_first") {
      res.sort((a, b) {
        if (a["status"] == "paid" && b["status"] != "paid") return -1;
        if (a["status"] != "paid" && b["status"] == "paid") return 1;
        return b["bill_month"].compareTo(a["bill_month"]);
      });
    }
    return res;
  }

  void downloadPdfReport() {
    final String tenantParam = widget.role == "tenant" ? "&tenant_id=${widget.renterId}" : "";
    final String url = "$baseUrl/api/bills/report/pdf/?search=$searchQuery&status=$statusFilter&building=${selectedBuilding ?? ''}&floor=${selectedFloor ?? ''}&aging=$overdueFilter&month=${selectedMonth ?? ''}$tenantParam";
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

  @override
  Widget build(BuildContext context) {
    // Dynamic list extraction for filters
    final Set<String> buildingsSet = {};
    final Set<String> floorsSet = {};
    final Set<String> monthsSet = {};
    for (var b in bills) {
      if (b["building_name"] != null && b["building_name"].toString().isNotEmpty) {
        buildingsSet.add(b["building_name"]);
      }
      if (b["floor_number"] != null) {
        floorsSet.add(b["floor_number"].toString());
      }
      if (b["bill_month"] != null && b["bill_month"].toString().isNotEmpty) {
        monthsSet.add(b["bill_month"].toString().substring(0, 7)); // e.g. "2026-05"
      }
    }

    final filteredList = getFilteredBills();

    // Summary counts for filtered month/set
    double totalRentCollected = 0;
    double totalRentCollectedCash = 0;
    double totalRentPending = 0;
    for (var b in filteredList) {
      if (b["status"] == "paid") {
        totalRentCollected += b["total_amount"];
        if (b["payment_mode"] == "cash") {
          totalRentCollectedCash += b["total_amount"];
        }
      } else {
        totalRentPending += b["total_amount"];
      }
    }

    return MainLayout(
      role: widget.role,
      userName: widget.userName,
      renterId: widget.renterId,
      currentIndex: 9,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PAGE TITLE
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      if (isMobile) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Rent Manager",
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
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
                                      onPressed: openBillGenerationDialog,
                                      icon: const Icon(Icons.add),
                                      label: const Text("Generate Rent Bill"),
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
                            const Text(
                              "Rent Manager",
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            Row(
                              children: [
                                _buildReportOptionsButton(context, isFullWidth: false),
                                if (widget.role != "tenant") ...[
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    onPressed: openBillGenerationDialog,
                                    icon: const Icon(Icons.add),
                                    label: const Text("Generate Rent Bill"),
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

                  // SUMMARY METRICS CARDS
                  if (widget.role != "tenant") ...[
                    LayoutBuilder(
                      builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      final collectedCard = Card(
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("COLLECTED RENT", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                              const SizedBox(height: 6),
                              Text("₹${totalRentCollected.toStringAsFixed(1)}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
                              const SizedBox(height: 4),
                              Text("Cash: ₹${totalRentCollectedCash.toStringAsFixed(1)}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                            ],
                          ),
                        ),
                      );

                      final pendingCard = Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("PENDING RENT", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                              const SizedBox(height: 6),
                              Text("₹${totalRentPending.toStringAsFixed(1)}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                            ],
                          ),
                        ),
                      );

                      if (isMobile) {
                        return Column(
                          children: [
                            SizedBox(width: double.infinity, child: collectedCard),
                            const SizedBox(height: 10),
                            SizedBox(width: double.infinity, child: pendingCard),
                          ],
                        );
                      } else {
                        return Row(
                          children: [
                            Expanded(child: collectedCard),
                            const SizedBox(width: 15),
                            Expanded(child: pendingCard),
                          ],
                        );
                      }
                    }
                  ),
                  const SizedBox(height: 15),
                  ],

                  if (widget.role != "tenant") ...[
                  // FILTERS ACCORDION / BOX
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        // Search bar
                        TextField(
                          controller: searchController,
                          onChanged: (v) => setState(() => searchQuery = v),
                          decoration: InputDecoration(
                            hintText: "Search tenant name or mobile number...",
                            prefixIcon: const Icon(Icons.search),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Filter selectors (Building, Floor, Status, Overdue Aging)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobile = constraints.maxWidth < 600;
                            final filtersList = [
                              ChoiceChip(
                                label: const Text("All Bills"),
                                selected: statusFilter == "all",
                                onSelected: (s) => setState(() {
                                  statusFilter = "all";
                                  overdueFilter = "all";
                                }),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text("Paid"),
                                selected: statusFilter == "paid",
                                onSelected: (s) => setState(() {
                                  statusFilter = "paid";
                                  overdueFilter = "all";
                                }),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text("Unpaid"),
                                selected: statusFilter == "unpaid",
                                onSelected: (s) => setState(() => statusFilter = "unpaid"),
                              ),
                              const SizedBox(width: 12),
                              DropdownButton<String>(
                                hint: const Text("Month"),
                                value: selectedMonth,
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
                                onChanged: (v) => setState(() => selectedMonth = v),
                              ),
                              const SizedBox(width: 12),
                              DropdownButton<String>(
                                hint: const Text("Building"),
                                value: selectedBuilding,
                                underline: const SizedBox(),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text("All Buildings")),
                                  ...buildingsSet.map((b) => DropdownMenuItem(value: b, child: Text(b))),
                                ],
                                onChanged: (v) => setState(() => selectedBuilding = v),
                              ),
                              const SizedBox(width: 12),
                              DropdownButton<String>(
                                hint: const Text("Floor"),
                                value: selectedFloor,
                                underline: const SizedBox(),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text("All Floors")),
                                  ...floorsSet.map((f) => DropdownMenuItem(value: f, child: Text("Floor $f"))),
                                ],
                                onChanged: (v) => setState(() => selectedFloor = v),
                              ),
                              if (statusFilter != "paid") ...[
                                const SizedBox(width: 12),
                                DropdownButton<String>(
                                  value: overdueFilter,
                                  underline: const SizedBox(),
                                  items: const [
                                    DropdownMenuItem(value: "all", child: Text("All Aging")),
                                    DropdownMenuItem(value: "overdue", child: Text("Past Due Date")),
                                    DropdownMenuItem(value: "1month", child: Text("> 1 Month")),
                                    DropdownMenuItem(value: "2months", child: Text("> 2 Months")),
                                    DropdownMenuItem(value: "3months", child: Text("> 3 Months")),
                                  ],
                                  onChanged: (v) => setState(() => overdueFilter = v ?? "all"),
                                ),
                              ],
                              const SizedBox(width: 12),
                              DropdownButton<String>(
                                value: sortBy,
                                underline: const SizedBox(),
                                items: const [
                                  DropdownMenuItem(value: "month_desc", child: Text("Newest Month First")),
                                  DropdownMenuItem(value: "month_asc", child: Text("Oldest Month First")),
                                  DropdownMenuItem(value: "unpaid_first", child: Text("Unpaid Bills First")),
                                  DropdownMenuItem(value: "paid_first", child: Text("Paid Bills First")),
                                ],
                                onChanged: (v) => setState(() => sortBy = v ?? "month_desc"),
                              ),
                            ];

                            if (isMobile) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: filtersList,
                                ),
                              );
                            } else {
                              return Wrap(
                                spacing: 12,
                                runSpacing: 10,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  ChoiceChip(
                                    label: const Text("All Bills"),
                                    selected: statusFilter == "all",
                                    onSelected: (s) => setState(() {
                                      statusFilter = "all";
                                      overdueFilter = "all";
                                    }),
                                  ),
                                  ChoiceChip(
                                    label: const Text("Paid"),
                                    selected: statusFilter == "paid",
                                    onSelected: (s) => setState(() {
                                      statusFilter = "paid";
                                      overdueFilter = "all";
                                    }),
                                  ),
                                  ChoiceChip(
                                    label: const Text("Unpaid"),
                                    selected: statusFilter == "unpaid",
                                    onSelected: (s) => setState(() => statusFilter = "unpaid"),
                                  ),
                                  DropdownButton<String>(
                                    hint: const Text("Month"),
                                    value: selectedMonth,
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
                                    onChanged: (v) => setState(() => selectedMonth = v),
                                  ),
                                  DropdownButton<String>(
                                    hint: const Text("Building"),
                                    value: selectedBuilding,
                                    underline: const SizedBox(),
                                    items: [
                                      const DropdownMenuItem(value: null, child: Text("All Buildings")),
                                      ...buildingsSet.map((b) => DropdownMenuItem(value: b, child: Text(b))),
                                    ],
                                    onChanged: (v) => setState(() => selectedBuilding = v),
                                  ),
                                  DropdownButton<String>(
                                    hint: const Text("Floor"),
                                    value: selectedFloor,
                                    underline: const SizedBox(),
                                    items: [
                                      const DropdownMenuItem(value: null, child: Text("All Floors")),
                                      ...floorsSet.map((f) => DropdownMenuItem(value: f, child: Text("Floor $f"))),
                                    ],
                                    onChanged: (v) => setState(() => selectedFloor = v),
                                  ),
                                  if (statusFilter != "paid")
                                    DropdownButton<String>(
                                      value: overdueFilter,
                                      underline: const SizedBox(),
                                      items: const [
                                        DropdownMenuItem(value: "all", child: Text("All Aging")),
                                        DropdownMenuItem(value: "overdue", child: Text("Past Due Date")),
                                        DropdownMenuItem(value: "1month", child: Text("> 1 Month")),
                                        DropdownMenuItem(value: "2months", child: Text("> 2 Months")),
                                        DropdownMenuItem(value: "3months", child: Text("> 3 Months")),
                                      ],
                                      onChanged: (v) => setState(() => overdueFilter = v ?? "all"),
                                    ),
                                  DropdownButton<String>(
                                    value: sortBy,
                                    underline: const SizedBox(),
                                    items: const [
                                      DropdownMenuItem(value: "month_desc", child: Text("Newest Month First")),
                                      DropdownMenuItem(value: "month_asc", child: Text("Oldest Month First")),
                                      DropdownMenuItem(value: "unpaid_first", child: Text("Unpaid Bills First")),
                                      DropdownMenuItem(value: "paid_first", child: Text("Paid Bills First")),
                                    ],
                                    onChanged: (v) => setState(() => sortBy = v ?? "month_desc"),
                                  ),
                                ],
                              );
                            }
                          }
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  ]

                  // BILL LIST
                  filteredList.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text("No matching bills found.")))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredList.length,
                          itemBuilder: (context, idx) {
                              final b = filteredList[idx];
                              final isPaid = b["status"] == "paid";

                              // Designations (Room/Flat details)
                              String designation = "Whole Suite";
                              if (b["room_number"] != null && b["room_number"].toString().isNotEmpty) {
                                designation = "Room ${b["room_number"]}";
                              } else if (b["flat_number"] != null && b["flat_number"].toString().isNotEmpty) {
                                designation = "Flat ${b["flat_number"]}";
                              }

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.all(15.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top Header
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  b["tenant_name"],
                                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  "${b["building_name"] ?? ''} • $designation • Mob: ${b["tenant_phone"] ?? ''}",
                                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: (isPaid ? Colors.green : Colors.red).withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              isPaid ? "PAID" : "UNPAID",
                                              style: TextStyle(color: isPaid ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 20),

                                      // Bill breakdown
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("Billing Month: ${b["bill_month"].toString().substring(0, 7)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Text("Due: ${b["due_date"]}", style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text("Base Room Rent:"),
                                          Text("₹${b["rent_amount"]}"),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text("Electricity Surcharge:"),
                                          Text("₹${b["electricity_amount"]}"),
                                        ],
                                      ),
                                      if (b["additional_amount"] > 0)
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text("Other Fine/Charges:"),
                                            Text("₹${b["additional_amount"]}"),
                                          ],
                                        ),
                                      
                                      const Divider(height: 15),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text("TOTAL BILL:", style: TextStyle(fontWeight: FontWeight.bold)),
                                          Text("₹${b["total_amount"]}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
                                        ],
                                      ),

                                      // Payment info rendering or actions
                                      if (isPaid) ...[
                                        const SizedBox(height: 10),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Paid by: ${b["payment_mode"].toString().toUpperCase()}",
                                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900),
                                              ),
                                              if (b["payment_mode"] == "upi" && b["utr_number"].toString().isNotEmpty)
                                                Text("UTR: ${b["utr_number"]}", style: TextStyle(fontSize: 12, color: Colors.green.shade800)),
                                              Text("Paid at: ${b["paid_at"]}", style: TextStyle(fontSize: 12, color: Colors.green.shade800)),
                                            ],
                                          ),
                                        ),
                                      ] else if (widget.role != "tenant") ...[
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          alignment: WrapAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              onPressed: () => openSurchargeDialog(b["id"]),
                                              icon: const Icon(Icons.add_circle_outline, size: 16),
                                              label: const Text("Apply Charge/Fine"),
                                            ),
                                            ElevatedButton.icon(
                                              onPressed: () => openRecordPaymentDialog(b),
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                              icon: const Icon(Icons.check_circle_outline, size: 16),
                                              label: const Text("Record Payment"),
                                            ),
                                          ],
                                        )
                                      ]
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