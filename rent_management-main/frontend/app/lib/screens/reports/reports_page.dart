import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../layout/main_layout.dart';

class ReportsPage extends StatefulWidget {
  final String role;
  final String userName;
  final String renterId;

  const ReportsPage({
    super.key,
    required this.role,
    required this.userName,
    required this.renterId,
  });

  @override
  State<ReportsPage> createState() =>
      _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final String baseUrl = "http://127.0.0.1:8000";

  bool isLoading = true;

  Map summary = {
    "totalTenants": 0,
    "totalRevenue": 0,
    "pendingBills": 0,
    "vacatedRooms": 0,
    "activeComplaints": 0,
  };

  List recentPayments = [];
  List recentBills = [];

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  ////////////////////////////////////////////////////////////
  /// FETCH ALL REPORT DATA (AGGREGATED)
  ////////////////////////////////////////////////////////////
  Future<void> fetchReports() async {
    try {
      // You can replace this with real API later
      final res = await http.get(
        Uri.parse("$baseUrl/api/reports-summary/"),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        setState(() {
          summary = data["summary"];
          recentPayments = data["recent_payments"];
          recentBills = data["recent_bills"];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(e.toString());

      // fallback demo mode (UI still works)
      setState(() {
        summary = {
          "totalTenants": 24,
          "totalRevenue": 185000,
          "pendingBills": 7,
          "vacatedRooms": 3,
          "activeComplaints": 5,
        };
        isLoading = false;
      });
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
      currentIndex: 17,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [

                  //////////////////////////////////////////////////
                  /// HEADER
                  //////////////////////////////////////////////////
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0F172A),
                          Color(0xFF334155),
                        ],
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Reports Dashboard",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Analytics of rent, tenants, payments & operations",
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  //////////////////////////////////////////////////
                  /// KPI CARDS
                  //////////////////////////////////////////////////
                  GridView(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.8,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    children: [

                      _buildCard(
                        "Total Tenants",
                        summary["totalTenants"].toString(),
                        Icons.people,
                        Colors.blue,
                      ),

                      _buildCard(
                        "Total Revenue",
                        "₹${summary["totalRevenue"]}",
                        Icons.currency_rupee,
                        Colors.green,
                      ),

                      _buildCard(
                        "Pending Bills",
                        summary["pendingBills"].toString(),
                        Icons.receipt_long,
                        Colors.orange,
                      ),

                      _buildCard(
                        "Vacated Rooms",
                        summary["vacatedRooms"].toString(),
                        Icons.exit_to_app,
                        Colors.red,
                      ),

                      _buildCard(
                        "Active Complaints",
                        summary["activeComplaints"].toString(),
                        Icons.report_problem,
                        Colors.purple,
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  //////////////////////////////////////////////////
                  /// RECENT PAYMENTS
                  //////////////////////////////////////////////////
                  _sectionTitle("Recent Payments"),

                  ListView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount: recentPayments.length,
                    itemBuilder: (context, i) {
                      final p = recentPayments[i];

                      return ListTile(
                        leading: const Icon(
                          Icons.payment,
                          color: Colors.green,
                        ),
                        title: Text("₹${p["amount_paid"]}"),
                        subtitle: Text(p["payment_mode"] ?? ""),
                        trailing: Text(
                          p["date"] ?? "",
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  //////////////////////////////////////////////////
                  /// RECENT BILLS
                  //////////////////////////////////////////////////
                  _sectionTitle("Recent Bills"),

                  ListView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount: recentBills.length,
                    itemBuilder: (context, i) {
                      final b = recentBills[i];

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.receipt),
                          title: Text(
                              "₹${b["total_amount"]}"),
                          subtitle: Text(
                              "Status: ${b["status"]}"),
                          trailing: Text(
                              b["bill_month"] ?? ""),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// KPI CARD
  ////////////////////////////////////////////////////////////
  Widget _buildCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(title),
        ],
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// SECTION TITLE
  ////////////////////////////////////////////////////////////
  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}