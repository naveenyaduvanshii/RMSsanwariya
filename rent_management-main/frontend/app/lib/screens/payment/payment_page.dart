import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../layout/main_layout.dart';

class PaymentsPage extends StatefulWidget {
  final String role;
  final String userName;
  final String renterId;

  const PaymentsPage({
    super.key,
    required this.role,
    required this.userName,
    required this.renterId,
  });

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final String baseUrl = "http://127.0.0.1:8000";

  List bills = [];
  bool isLoading = true;

  // Search & Filter state
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  String paymentModeFilter = "all"; // all, cash, upi

  @override
  void initState() {
    super.initState();
    fetchBills();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchBills() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/bills/"));
      if (res.statusCode == 200) {
        setState(() {
          bills = jsonDecode(res.body)["data"] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> deletePayment(String paymentId) async {
    if (paymentId.isEmpty) return;
    
    // Show confirm dialog
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Delete Payment Entry"),
        content: const Text("Are you sure you want to delete this payment record? The associated bill will revert to pending status."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => isLoading = true);
    try {
      final res = await http.delete(Uri.parse("$baseUrl/api/payments/$paymentId/delete/"));
      if (res.statusCode == 200 || res.statusCode == 204) {
        fetchBills();
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  List getPaidBills() {
    return bills.where((b) {
      if (widget.role == "tenant" && b["tenant_id"]?.toString() != widget.renterId) {
        return false;
      }

      // 1. Must be PAID
      if (b["status"] != "paid") return false;

      // 2. Search filter (Tenant Name & Mobile No)
      final name = b["tenant_name"].toString().toLowerCase();
      final phone = b["tenant_phone"].toString().toLowerCase();
      final query = searchQuery.toLowerCase();
      if (!name.contains(query) && !phone.contains(query)) {
        return false;
      }

      // 3. Payment Mode filter
      final mode = b["payment_mode"].toString().toLowerCase();
      if (paymentModeFilter != "all" && mode != paymentModeFilter) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final paidList = getPaidBills();

    // Calculate total collection amount for the filtered set
    double totalCollection = 0;
    for (var b in paidList) {
      totalCollection += b["total_amount"];
    }

    return MainLayout(
      role: widget.role,
      userName: widget.userName,
      renterId: widget.renterId,
      currentIndex: 10,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PAGE TITLE
                  const Text(
                    "Collection Ledger",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 15),

                  // TOTAL LEDGER CARD
                  if (widget.role != "tenant") ...[
                    Card(
                      color: Colors.blue.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("TOTAL RECORDED COLLECTION", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                                const SizedBox(height: 6),
                                Text("₹${totalCollection.toStringAsFixed(1)}", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                              ],
                            ),
                            const Icon(Icons.account_balance_wallet, size: 40, color: Colors.blue),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],

                  // SEARCH & FILTERS CONTAINER
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        // Search Input
                        TextField(
                          controller: searchController,
                          onChanged: (v) => setState(() => searchQuery = v),
                          decoration: InputDecoration(
                            hintText: "Search payments by tenant or mobile number...",
                            prefixIcon: const Icon(Icons.search),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Mode Chips Filter
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            const Text("Payment Mode: ", style: TextStyle(fontWeight: FontWeight.bold)),
                            ChoiceChip(
                              label: const Text("All"),
                              selected: paymentModeFilter == "all",
                              onSelected: (s) => setState(() => paymentModeFilter = "all"),
                            ),
                            ChoiceChip(
                              label: const Text("Cash"),
                              selected: paymentModeFilter == "cash",
                              onSelected: (s) => setState(() => paymentModeFilter = "cash"),
                            ),
                            ChoiceChip(
                              label: const Text("UPI / Online"),
                              selected: paymentModeFilter == "upi",
                              onSelected: (s) => setState(() => paymentModeFilter = "upi"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // LEDGER LIST
                  paidList.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text("No payment collections found.")))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: paidList.length,
                          itemBuilder: (context, index) {
                            final b = paidList[index];
                            final isCash = b["payment_mode"] == "cash";

                            // Designations (Room/Flat details)
                            String designation = "Suite";
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
                                child: Row(
                                  children: [
                                    // Left side Payment mode Icon
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: (isCash ? Colors.green : Colors.blue).withOpacity(0.12),
                                      child: Icon(
                                        isCash ? Icons.money : Icons.phone_android,
                                        color: isCash ? Colors.green : Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 15),

                                    // Main description
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            b["tenant_name"],
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "${b["building_name"] ?? ''} • $designation • Mob: ${b["tenant_phone"] ?? ''}",
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Billing month: ${b["bill_month"].toString().substring(0, 7)}",
                                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (!isCash && b["utr_number"].toString().isNotEmpty)
                                            Text(
                                              "UTR: ${b["utr_number"]}",
                                              style: const TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.w600),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          Text(
                                            "Received at: ${b["paid_at"]}",
                                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Amount & deletion action
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "₹${b["total_amount"]}",
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                                        ),
                                        if (widget.role != "tenant") ...[
                                          const SizedBox(height: 10),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                            onPressed: () => deletePayment(b["payment_id"]),
                                            tooltip: "Delete Payment Record",
                                          ),
                                        ],
                                      ],
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