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
    if (widget.renterId.trim().isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    } else {
      loadDashboard();
    }
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

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final weekdays = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
    ];
    return "${weekdays[now.weekday % 7]}, ${months[now.month - 1]} ${now.day}, ${now.year}";
  }

  void _navigateTo(String route) {
    Navigator.pushReplacementNamed(
      context,
      route,
      arguments: {
        "role": widget.role,
        "userName": widget.userName,
        "renterId": widget.renterId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

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
                  child: RefreshIndicator(
                    onRefresh: loadDashboard,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          if (widget.role == "tenant") ...[
                            _buildTenantPropertyCard(),
                            const SizedBox(height: 24),
                          ],
                          _buildQuickActions(),
                          const SizedBox(height: 28),
                          const Text(
                            "Overview",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildMetricsGrid(screenWidth),
                          const SizedBox(height: 28),
                          _buildRecentActivitySection(screenWidth),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Welcome back, ",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.userName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getFormattedDate(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: Text(
              widget.role.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4F46E5),
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantPropertyCard() {
    final building = dashboardData?["building_name"] ?? "";
    final floor = dashboardData?["floor_number"] ?? "";
    final flat = dashboardData?["flat_number"] ?? "";
    final room = dashboardData?["room_number"] ?? "";
    final startDate = dashboardData?["rent_start_date"] ?? "";

    if (building.isEmpty && room.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.home_work, color: Colors.blueAccent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Your Assigned Residence",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (startDate.isNotEmpty)
                      Text(
                        "Lease Started: $startDate",
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              if (building.isNotEmpty) _buildPropertyDetailItem("Building", building),
              if (floor.toString().isNotEmpty) _buildPropertyDetailItem("Floor", "Floor $floor"),
              if (flat.isNotEmpty) _buildPropertyDetailItem("Flat", "Flat $flat"),
              if (room.isNotEmpty) _buildPropertyDetailItem("Room", "Room $room"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final List<Map<String, dynamic>> actions = [];
    if (widget.role == "tenant") {
      actions.addAll([
        {
          "label": "Pay Bills",
          "icon": Icons.payment,
          "color": const Color(0xFF10B981),
          "route": "/bills",
        },
        {
          "label": "File Complaint",
          "icon": Icons.campaign_outlined,
          "color": const Color(0xFFEF4444),
          "route": "/complaints",
        },
        {
          "label": "Agreement",
          "icon": Icons.assignment_outlined,
          "color": const Color(0xFF3B82F6),
          "route": "/my-assignment",
        },
        {
          "label": "Documents",
          "icon": Icons.folder_outlined,
          "color": const Color(0xFF8B5CF6),
          "route": "/documents",
        },
      ]);
    } else {
      actions.addAll([
        {
          "label": "Rental Units",
          "icon": Icons.add_home_work_outlined,
          "color": const Color(0xFF3B82F6),
          "route": "/rental-units",
        },
        {
          "label": "Add Tenant",
          "icon": Icons.person_add_alt_1_outlined,
          "color": const Color(0xFF10B981),
          "route": "/tenants",
        },
        {
          "label": "Create Bill",
          "icon": Icons.post_add_outlined,
          "color": const Color(0xFFF59E0B),
          "route": "/bills",
        },
        {
          "label": "Complaints",
          "icon": Icons.forum_outlined,
          "color": const Color(0xFF8B5CF6),
          "route": "/complaints",
        },
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: actions.map((act) {
            return InkWell(
              onTap: () => _navigateTo(act["route"]),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 130,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.005),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      backgroundColor: (act["color"] as Color).withOpacity(0.08),
                      radius: 18,
                      child: Icon(act["icon"] as IconData, color: act["color"] as Color, size: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      act["label"] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(double screenWidth) {
    if (widget.role == "tenant") {
      final rent = dashboardData?["rent"] ?? "0";
      final unitType = dashboardData?["unit_type"] ?? "N/A";
      final pendingBills = dashboardData?["pending_bills"] ?? 0;
      final complaints = dashboardData?["complaints"] ?? 0;

      final monthlyRentCard = MetricCard(
        title: "MONTHLY RENT",
        value: "₹$rent",
        icon: Icons.currency_rupee,
        color: const Color(0xFF3B82F6),
        bottomWidget: Text(
          "Unit Type: ${unitType.toString().toUpperCase()}",
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
      );

      final pendingBillsCard = MetricCard(
        title: "PENDING BILLS",
        value: pendingBills.toString(),
        icon: Icons.warning_amber_rounded,
        color: pendingBills > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        bottomWidget: Text(
          pendingBills > 0 ? "Action required" : "All clear",
          style: TextStyle(
            fontSize: 11,
            color: pendingBills > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
            fontWeight: FontWeight.w600,
          ),
        ),
      );

      final activeRequestsCard = MetricCard(
        title: "ACTIVE REQUESTS",
        value: complaints.toString(),
        icon: Icons.forum_outlined,
        color: const Color(0xFF8B5CF6),
        bottomWidget: const Text(
          "Maintenance & complaints",
          style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
      );

      if (screenWidth < 600) {
        return Column(
          children: [
            monthlyRentCard,
            const SizedBox(height: 16),
            pendingBillsCard,
            const SizedBox(height: 16),
            activeRequestsCard,
          ],
        );
      }

      return GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
        ),
        children: [
          monthlyRentCard,
          pendingBillsCard,
          activeRequestsCard,
        ],
      );
    } else {
      // Owner or Manager metrics layout
      final revenue = dashboardData?["monthly_revenue"] ?? "0";
      final tenantsCount = dashboardData?["total_tenants"] ?? 0;
      final pendingBills = dashboardData?["pending_bills"] ?? 0;
      final occupied = dashboardData?["occupied_units"] ?? 0;
      final vacant = dashboardData?["vacant_units"] ?? 0;
      final totalUnits = occupied + vacant;
      final occupancyRate = totalUnits > 0 ? (occupied / totalUnits) : 0.0;

      final monthlyRevenueCard = MetricCard(
        title: "MONTHLY REVENUE",
        value: "₹$revenue",
        icon: Icons.payments_outlined,
        color: const Color(0xFF10B981),
        bottomWidget: const Text(
          "Current Month Collection",
          style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
      );

      final occupancyRateCard = MetricCard(
        title: "OCCUPANCY RATE",
        value: "${(occupancyRate * 100).toStringAsFixed(0)}%",
        icon: Icons.home_work_outlined,
        color: const Color(0xFF3B82F6),
        bottomWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: occupancyRate,
                backgroundColor: const Color(0xFFE2E8F0),
                color: const Color(0xFF3B82F6),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "$occupied occupied / $totalUnits total units",
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );

      final activeTenantsCard = MetricCard(
        title: "ACTIVE TENANTS & BILLS",
        value: tenantsCount.toString(),
        icon: Icons.people_outline,
        color: const Color(0xFFF59E0B),
        bottomWidget: Text(
          "$pendingBills pending bills",
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFFEF4444),
            fontWeight: FontWeight.w600,
          ),
        ),
      );

      if (screenWidth < 700) {
        return Column(
          children: [
            monthlyRevenueCard,
            const SizedBox(height: 16),
            occupancyRateCard,
            const SizedBox(height: 16),
            activeTenantsCard,
            const SizedBox(height: 16),
            _buildPropertySummaryCard(),
          ],
        );
      }

      int crossAxisCount = screenWidth < 1100 ? 2 : 3;
      double aspectRatio = 1.7;

      return Column(
        children: [
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: aspectRatio,
            ),
            children: [
              monthlyRevenueCard,
              occupancyRateCard,
              activeTenantsCard,
            ],
          ),
          const SizedBox(height: 16),
          _buildPropertySummaryCard(),
        ],
      );
    }
  }

  Widget _buildPropertySummaryCard() {
    final b = dashboardData?["total_buildings"] ?? 0;
    final f = dashboardData?["total_floors"] ?? 0;
    final fl = dashboardData?["total_flats"] ?? 0;
    final r = dashboardData?["total_rooms"] ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.business_outlined, color: Color(0xFF4F46E5), size: 18),
              SizedBox(width: 8),
              Text(
                "Property Directory",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPropItem("Buildings", b.toString(), const Color(0xFF3B82F6)),
              _buildPropItem("Floors", f.toString(), const Color(0xFF8B5CF6)),
              _buildPropItem("Flats", fl.toString(), const Color(0xFFF59E0B)),
              _buildPropItem("Rooms", r.toString(), const Color(0xFF10B981)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(double screenWidth) {
    bool isWide = screenWidth >= 950;
    
    final paymentsWidget = _buildRecentPayments();
    final complaintsWidget = _buildRecentComplaints();
    final vacatesWidget = widget.role != "tenant" ? _buildRecentVacateRequests() : const SizedBox.shrink();

    if (isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: paymentsWidget),
              const SizedBox(width: 16),
              Expanded(child: complaintsWidget),
            ],
          ),
          if (widget.role != "tenant") ...[
            const SizedBox(height: 20),
            vacatesWidget,
          ],
        ],
      );
    } else {
      return Column(
        children: [
          paymentsWidget,
          const SizedBox(height: 16),
          complaintsWidget,
          if (widget.role != "tenant") ...[
            const SizedBox(height: 16),
            vacatesWidget,
          ],
        ],
      );
    }
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.005),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.08),
                radius: 16,
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
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
    );
  }

  Widget _buildRecentPayments() {
    final payments = dashboardData?["recent_payments"] ?? [];

    return _buildSectionCard(
      title: "Recent Payments",
      icon: Icons.receipt_long_outlined,
      color: const Color(0xFF10B981),
      child: payments.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  "No recent payments",
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: payments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final p = payments[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p["tenant_name"] ?? "Payment",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF1E293B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p["paid_at"] ?? "",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "₹${p["amount_paid"]}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (p["payment_mode"] ?? "").toString().toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildRecentComplaints() {
    final complaints = dashboardData?["recent_complaints"] ?? [];

    return _buildSectionCard(
      title: "Recent Complaints",
      icon: Icons.bug_report_outlined,
      color: const Color(0xFFEF4444),
      child: complaints.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  "No recent complaints",
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: complaints.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final c = complaints[index];
                final priority = (c["priority"] ?? "").toString().toLowerCase();
                final status = (c["status"] ?? "").toString().toLowerCase();
                
                Color prioColor = Colors.grey;
                if (priority == "high") prioColor = const Color(0xFFEF4444);
                if (priority == "medium") prioColor = const Color(0xFFF59E0B);
                if (priority == "low") prioColor = const Color(0xFF3B82F6);

                Color statusColor = Colors.grey;
                if (status == "resolved") statusColor = const Color(0xFF10B981);
                if (status == "pending") statusColor = const Color(0xFFEF4444);
                if (status == "in_progress") statusColor = const Color(0xFFF59E0B);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              c["title"] ?? "",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF1E293B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: prioColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              priority.toUpperCase(),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: prioColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              c["tenant_name"] ?? "",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status.replaceAll("_", " ").toUpperCase(),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildRecentVacateRequests() {
    final vacates = dashboardData?["recent_vacate_requests"] ?? [];

    return _buildSectionCard(
      title: "Vacate Requests",
      icon: Icons.exit_to_app_outlined,
      color: const Color(0xFFF59E0B),
      child: vacates.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  "No pending vacate requests",
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vacates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final v = vacates[index];
                final status = (v["status"] ?? "").toString().toLowerCase();
                
                Color statusColor = Colors.grey;
                if (status == "approved") statusColor = const Color(0xFF10B981);
                if (status == "pending") statusColor = const Color(0xFFF59E0B);
                if (status == "rejected") statusColor = const Color(0xFFEF4444);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v["tenant_name"] ?? "",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF1E293B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Expected: ${v["vacate_date"] ?? ""}",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Widget? bottomWidget;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.bottomWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.005),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              CircleAvatar(
                backgroundColor: color.withOpacity(0.08),
                radius: 16,
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (bottomWidget != null) ...[
            const SizedBox(height: 6),
            bottomWidget!,
          ],
        ],
      ),
    );
  }
}