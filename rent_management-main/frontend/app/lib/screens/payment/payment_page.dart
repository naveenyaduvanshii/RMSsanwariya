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
  ////////////////////////////////////////////////////////////
  /// BASE URL
  ////////////////////////////////////////////////////////////

  final String baseUrl = "http://127.0.0.1:8000";

  ////////////////////////////////////////////////////////////
  /// CONTROLLERS
  ////////////////////////////////////////////////////////////

  final TextEditingController amountController = TextEditingController();
  final TextEditingController utrController = TextEditingController();

  ////////////////////////////////////////////////////////////
  /// DATA
  ////////////////////////////////////////////////////////////

  List bills = [];
  List payments = [];
  List transactions = [];

  String? selectedBillId;
  String? paymentMode;

  bool isLoading = true;
  bool isSaving = false;

  ////////////////////////////////////////////////////////////
  /// INIT
  ////////////////////////////////////////////////////////////

  @override
  void initState() {
    super.initState();
    fetchBills();
    fetchTransactions();
  }

  ////////////////////////////////////////////////////////////
  /// FETCH BILLS
  ////////////////////////////////////////////////////////////

  Future<void> fetchBills() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/bills/"),
      );

      if (res.statusCode == 200) {
        setState(() {
          bills = jsonDecode(res.body)["data"];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  ////////////////////////////////////////////////////////////
  /// FETCH TRANSACTIONS
  ////////////////////////////////////////////////////////////

  Future<void> fetchTransactions() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/payment-transactions/"),
      );

      if (res.statusCode == 200) {
        setState(() {
          transactions = jsonDecode(res.body)["data"];
        });
      }
    } catch (e) {}
  }

  ////////////////////////////////////////////////////////////
  /// MAKE PAYMENT
  ////////////////////////////////////////////////////////////

  Future<void> makePayment() async {
    if (selectedBillId == null || amountController.text.isEmpty) {
      return;
    }

    setState(() => isSaving = true);

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/create-payment/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "bill_id": selectedBillId,
          "amount_paid": amountController.text,
          "payment_mode": paymentMode ?? "cash",
          "utr_number": utrController.text,
          "received_by": null
        }),
      );

      if (res.statusCode == 200) {
        Navigator.pop(context);
        amountController.clear();
        utrController.clear();
        fetchBills();
      }
    } catch (e) {}

    setState(() => isSaving = false);
  }

  ////////////////////////////////////////////////////////////
  /// DELETE PAYMENT
  ////////////////////////////////////////////////////////////

  Future<void> deletePayment(String id) async {
    try {
      await http.delete(
        Uri.parse("$baseUrl/api/delete-payment/$id/"),
      );

      fetchBills();
    } catch (e) {}
  }

  ////////////////////////////////////////////////////////////
  /// PAYMENT DIALOG
  ////////////////////////////////////////////////////////////

  void openPaymentDialog(Map bill) {
    selectedBillId = bill["id"];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Pay Bill - ${bill["tenant_name"]}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Total: ${bill["total_amount"]}"),
            Text("Due: ${bill["status"]}"),

            const SizedBox(height: 10),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount Paid",
              ),
            ),

            TextField(
              controller: utrController,
              decoration: const InputDecoration(
                labelText: "UTR / Reference",
              ),
            ),

            DropdownButtonFormField(
              value: paymentMode,
              items: const [
                DropdownMenuItem(
                  value: "cash",
                  child: Text("Cash"),
                ),
                DropdownMenuItem(
                  value: "upi",
                  child: Text("UPI"),
                ),
                DropdownMenuItem(
                  value: "bank",
                  child: Text("Bank Transfer"),
                ),
              ],
              onChanged: (v) {
                paymentMode = v.toString();
              },
              decoration: const InputDecoration(
                labelText: "Payment Mode",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: isSaving ? null : makePayment,
            child: const Text("Pay"),
          ),
        ],
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// TRANSACTION VIEW
  ////////////////////////////////////////////////////////////

  void showTransactions() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ListView(
          children: transactions.map((t) {
            return ListTile(
              title: Text("₹${t["amount"]} - ${t["tenant_name"]}"),
              subtitle: Text(
                "${t["gateway_name"]} | ${t["transaction_status"]}",
              ),
              trailing: Text(t["created_at"]),
            );
          }).toList(),
        );
      },
    );
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
      currentIndex: 10,
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
                  color: Colors.blue,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Payments",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),

                      ElevatedButton(
                        onPressed: showTransactions,
                        child: const Text("Transactions"),
                      )
                    ],
                  ),
                ),

                //////////////////////////////////////////////////////
                /// BILL LIST
                //////////////////////////////////////////////////////

                Expanded(
                  child: ListView.builder(
                    itemCount: bills.length,
                    itemBuilder: (context, index) {
                      final b = bills[index];

                      Color statusColor;

                      switch (b["status"]) {
                        case "paid":
                          statusColor = Colors.green;
                          break;
                        case "partial":
                          statusColor = Colors.orange;
                          break;
                        default:
                          statusColor = Colors.red;
                      }

                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: ListTile(
                          title: Text(b["tenant_name"]),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text("Total: ₹${b["total_amount"]}"),
                              Text(
                                "Status: ${b["status"]}",
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          trailing: widget.role == "tenant"
                              ? null
                              : PopupMenuButton(
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      child: const Text("Pay"),
                                      onTap: () {
                                        Future.delayed(
                                          Duration.zero,
                                          () => openPaymentDialog(b),
                                        );
                                      },
                                    ),
                                    PopupMenuItem(
                                      child: const Text("Delete Payment"),
                                      onTap: () {
                                        if (b["latest_payment_id"] != null) {
                                          deletePayment(
                                            b["latest_payment_id"],
                                          );
                                        }
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