import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import '../../layout/main_layout.dart';

class DashboardPage extends StatefulWidget {
  final String role;
  final String userName;
  final String renterId;

  const DashboardPage({
    super.key,
    required this.role,
    required this.userName,
    required this.renterId,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;
  final String baseUrl = ApiService.baseUrl;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.renterId != oldWidget.renterId && widget.renterId.isNotEmpty) {
      setState(() => isLoading = true);
      loadDashboard();
    }
  }

  Future<void> loadDashboard() async {
    if (widget.renterId.trim().isEmpty) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      return;
    }

    String url = "$baseUrl/api/dashboard/?role=${widget.role}&user_id=${widget.renterId}";

    try {
      final response = await http.get(Uri.parse(url));

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        setState(() {
          dashboardData = data["dashboard"];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Dashboard Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount = 4;
    double childAspectRatio = 1.7;

    if (screenWidth < 600) {
      crossAxisCount = 1;
      childAspectRatio = 3.2;
    } else if (screenWidth < 1100) {
      crossAxisCount = 2;
      childAspectRatio = 2.0;
    } else if (screenWidth < 1400) {
      crossAxisCount = 3;
      childAspectRatio = 1.8;
    }

    return MainLayout(
      role: widget.role,
      userName: widget.userName,
      renterId: widget.renterId,
      currentIndex: 0,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : dashboardData == null
              ? const Center(child: Text("No Data Found"))
              : SelectionArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// =======================================================
                        /// STATS GRID (COLLAPSES SAFELY BASED ON VIEWPORT WIDTH)
                        /// =======================================================
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: buildStatsCards().length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: childAspectRatio,
                          ),
                          itemBuilder: (context, index) {
                            return buildStatsCards()[index];
                          },
                        ),

                        const SizedBox(height: 24),

                        /// =======================================================
                        /// SECTION RECENT LISTS (SPLITS HORIZONTALLY ON BIG SCREENS)
                        /// =======================================================
                        if (screenWidth >= 1000) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: recentPayments()),
                              const SizedBox(width: 16),
                              Expanded(child: recentComplaints()),
                            ],
                          ),
                          if (widget.role != "tenant") ...[
                            const SizedBox(height: 24),
                            recentVacateRequests(),
                          ],
                        ] else ...[
                          recentPayments(),
                          const SizedBox(height: 16),
                          recentComplaints(),
                          const SizedBox(height: 16),
                          if (widget.role != "tenant") recentVacateRequests(),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  /// =====================================================
  /// STATS CARDS PARSER
  /// =====================================================
  List<Widget> buildStatsCards() {
    List<Widget> cards = [];
    if (dashboardData == null) return cards;

    dashboardData!.forEach((key, value) {
      if (key == "recent_payments" ||
          key == "recent_complaints" ||
          key == "recent_vacate_requests") {
        return;
      }

      cards.add(
        StatCard(
          title: formatTitle(key),
          value: value.toString(),
          icon: getIcon(key),
          color: getColor(key),
        ),
      );
    });

    return cards;
  }

  /// =====================================================
  /// RECENT PAYMENTS CARD VIEW
  /// =====================================================
  Widget recentPayments() {
    final payments = dashboardData?["recent_payments"] ?? [];

    return sectionCard(
      title: "Recent Payments",
      icon: Icons.payments,
      color: Colors.green,
      child: payments.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text("No recent payments")),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: payments.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final p = payments[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFDCFCE7),
                    child: Icon(Icons.payments, color: Colors.green, size: 20),
                  ),
                  title: Text(
                    p["tenant_name"] ?? "Payment",
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(p["paid_at"] ?? "", style: const TextStyle(fontSize: 12)),
                  trailing: Text(
                    "₹${p["amount_paid"]}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                  ),
                );
              },
            ),
    );
  }

  /// =====================================================
  /// RECENT COMPLAINTS CARD VIEW
  /// =====================================================
  Widget recentComplaints() {
    final complaints = dashboardData?["recent_complaints"] ?? [];

    return sectionCard(
      title: "Recent Complaints",
      icon: Icons.report,
      color: Colors.red,
      child: complaints.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text("No recent complaints")),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: complaints.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final c = complaints[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFEE2E2),
                    child: Icon(Icons.report, color: Colors.red, size: 20),
                  ),
                  title: Text(
                    c["title"] ?? "",
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text("Status: ${c["status"] ?? ""}", style: const TextStyle(fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      c["priority"] ?? "",
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ),
                );
              },
            ),
    );
  }

  /// =====================================================
  /// RECENT VACATE REQUESTS CARD VIEW
  /// =====================================================
  Widget recentVacateRequests() {
    final vacates = dashboardData?["recent_vacate_requests"] ?? [];

    return sectionCard(
      title: "Vacate Requests",
      icon: Icons.exit_to_app,
      color: Colors.orange,
      child: vacates.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text("No pending vacate requests")),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vacates.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final v = vacates[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFEDD5),
                    child: Icon(Icons.exit_to_app, color: Colors.orange, size: 20),
                  ),
                  title: Text(
                    v["tenant_name"] ?? "",
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text("Expected: ${v["vacate_date"] ?? ""}", style: const TextStyle(fontSize: 12)),
                  trailing: Text(
                    v["status"] ?? "",
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.orange),
                  ),
                );
              },
            ),
    );
  }

  /// =====================================================
  /// SECTION WRAPPER METADATA UTILITY CARD
  /// =====================================================
  Widget sectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  String formatTitle(String text) {
    return text.replaceAll("_", " ").toUpperCase();
  }

  IconData getIcon(String key) {
    switch (key) {
      case "total_buildings": return Icons.apartment;
      case "total_floors": return Icons.layers;
      case "total_rooms": return Icons.meeting_room;
      case "total_tenants": return Icons.people;
      case "occupied_units": return Icons.home;
      case "vacant_units": return Icons.home_outlined;
      case "pending_bills": return Icons.warning;
      case "monthly_revenue": return Icons.currency_rupee;
      default: return Icons.bar_chart;
    }
  }

  Color getColor(String key) {
    switch (key) {
      case "total_buildings": return Colors.blue;
      case "total_rooms": return Colors.indigo;
      case "total_tenants": return Colors.green;
      case "occupied_units": return Colors.teal;
      case "vacant_units": return Colors.orange;
      case "pending_bills": return Colors.red;
      case "monthly_revenue": return Colors.purple;
      default: return Colors.blueGrey;
    }
  }
}

/// ============================================================================
/// FIXED STAT CARD OVERFLOW IMMUNE IMPLEMENTATION
/// ============================================================================
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.06),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            radius: 20,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // 🧠 Prevents vertical expansion
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.blueGrey.shade700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Flexible( // 🧠 Prevents data values from breaking box thresholds
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900, // Fixed 'FontWeight.black' bug
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}