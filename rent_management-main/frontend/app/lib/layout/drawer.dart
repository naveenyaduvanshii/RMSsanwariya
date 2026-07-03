import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final String role;
  final int selectedIndex;
  final Function(int) onTap;

  const AppDrawer({
    super.key,
    required this.role,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final menuItems = getMenuByRole(role);

    return Drawer(
      backgroundColor: const Color(0xFF111827),
      child: SafeArea(
        child: Column(
          children: [

            const SizedBox(height: 10),

            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.home_work,
                    color: Colors.white,
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Rent Management",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(
              color: Colors.white24,
              height: 1,
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];

                  final isSelected =
                      selectedIndex == index;

                  return Container(
                    margin: const EdgeInsets.only(
                      bottom: 8,
                    ),
                    child: Material(
                      color: isSelected
                          ? Colors.blue.shade700
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(12),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        leading: Icon(
                          item["icon"] as IconData,
                          color: Colors.white,
                        ),
                        title: Text(
                          item["title"] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          onTap(index);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(
              color: Colors.white24,
              height: 1,
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      '/login',
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.red.shade600,
                    foregroundColor:
                        Colors.white,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> getMenuByRole(
      String role) {

    if (role == "owner") {
      return [
        {"title": "Dashboard", "icon": Icons.dashboard},
        {"title": "Profile", "icon": Icons.person},
        {"title": "Managers", "icon": Icons.manage_accounts,},
        {"title": "Buildings", "icon": Icons.apartment},
        {"title": "Flats", "icon": Icons.home_work},
        {"title": "Rooms", "icon": Icons.meeting_room},
        {"title": "Rental Units", "icon": Icons.business},
        {"title": "Tenants", "icon": Icons.people},
        {"title": "Assignments", "icon": Icons.assignment_ind},
        {"title": "Bills", "icon": Icons.receipt_long},
        {"title": "Payments", "icon": Icons.payments},
        {"title": "Electricity", "icon": Icons.electric_bolt},
        {"title": "Complaints", "icon": Icons.report_problem},
        {"title": "Maintenance", "icon": Icons.build},
        {"title": "Documents", "icon": Icons.folder},
        {"title": "Vacate Requests", "icon": Icons.logout},
        {"title": "Notifications", "icon": Icons.notifications},
        {"title": "Reports", "icon": Icons.bar_chart},
        {"title": "Settings", "icon": Icons.settings},
      ];
    }

    if (role == "manager") {
      return [
        {"title": "Dashboard", "icon": Icons.dashboard},
        {"title": "Buildings", "icon": Icons.apartment},
        {"title": "Flats", "icon": Icons.home_work},
        {"title": "Rooms", "icon": Icons.meeting_room},
        {"title": "Tenants", "icon": Icons.people},
        {"title": "Assignments", "icon": Icons.assignment_ind},
        {"title": "Bills", "icon": Icons.receipt_long},
        {"title": "Payments", "icon": Icons.payments},
        {"title": "Electricity", "icon": Icons.electric_bolt},
        {"title": "Complaints", "icon": Icons.report_problem},
        {"title": "Maintenance", "icon": Icons.build},
        {"title": "Documents", "icon": Icons.folder},
        {"title": "Vacate Requests", "icon": Icons.logout},
        {"title": "Notifications", "icon": Icons.notifications},
      ];
    }

    return [
      {"title": "Dashboard", "icon": Icons.dashboard},
      {"title": "My Assignment", "icon": Icons.assignment},
      {"title": "Bills", "icon": Icons.receipt_long},
      {"title": "Payments", "icon": Icons.payments},
      {"title": "Electricity", "icon": Icons.electric_bolt},
      {"title": "Complaints", "icon": Icons.report_problem},
      {"title": "Documents", "icon": Icons.folder},
      {"title": "Vacate Request", "icon": Icons.logout},
      {"title": "Notifications", "icon": Icons.notifications},
      {"title": "Profile", "icon": Icons.person},
    ];
  }
}