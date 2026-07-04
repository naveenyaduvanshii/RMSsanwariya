import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final String role;
  final int selectedIndex;
  final Function(int) onTap;

  const Sidebar({
    super.key,
    required this.role,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final menuItems = getMenuByRole(role);

    return Container(
      width: 260,
      color: const Color(0xFF111827),

      child: Column(
        children: [

          //////////////////////////////////////////////////////
          // TOP SPACE
          //////////////////////////////////////////////////////

          const SizedBox(height: 20),

          //////////////////////////////////////////////////////
          // MENU LIST
          //////////////////////////////////////////////////////

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
              ),

              itemCount: menuItems.length,

              itemBuilder: (context, index) {

                final item = menuItems[index];

                final isSelected =
                    selectedIndex == index;

                //////////////////////////////////////////////////////
                // FIXED LIST TILE
                //////////////////////////////////////////////////////

                return Container(
                  margin: const EdgeInsets.only(
                    bottom: 10,
                  ),

                  child: Material(
                    color: isSelected
                        ? Colors.blue.shade700
                        : Colors.transparent,

                    borderRadius:
                        BorderRadius.circular(14),

                    child: ListTile(

                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),

                      leading: Icon(
                        item['icon'],
                        color: Colors.white,
                      ),

                      title: Text(
                        item['title'],

                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      onTap: () {
                        onTap(index);
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          //////////////////////////////////////////////////////
          // LOGOUT BUTTON
          //////////////////////////////////////////////////////

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

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

 List<Map<String, dynamic>> getMenuByRole(String role) {

  //////////////////////////////////////////////////////
  // OWNER
  //////////////////////////////////////////////////////

  if (role == "owner") {
    return [

      {
        "title": "Dashboard",
        "icon": Icons.dashboard,
      },

      {
        "title": "Profile",
        "icon": Icons.person,
      },
      {
      "title": "Managers",
      "icon": Icons.manage_accounts,
    },


      {
        "title": "Buildings",
        "icon": Icons.apartment,
      },
      {
        "title": "Flats",
        "icon": Icons.home_work,
      },

      {
        "title": "Rooms",
        "icon": Icons.meeting_room,
      },

      {
        "title": "Rental Units",
        "icon": Icons.business,
      },

      {
        "title": "Tenants",
        "icon": Icons.people,
      },

      {
        "title": "Assignments",
        "icon": Icons.assignment_ind,
      },

      {
        "title": "Bills",
        "icon": Icons.receipt_long,
      },

      {
        "title": "Payments",
        "icon": Icons.payments,
      },

      {
        "title": "Electricity",
        "icon": Icons.electric_bolt,
      },

      {
        "title": "Complaints",
        "icon": Icons.report_problem,
      },

      {
        "title": "Documents",
        "icon": Icons.folder,
      },

      {
        "title": "Vacate Requests",
        "icon": Icons.logout,
      },

      {
        "title": "Notifications",
        "icon": Icons.notifications,
      },

      {
        "title": "Settings",
        "icon": Icons.settings,
      },
    ];
  }

  //////////////////////////////////////////////////////
  // MANAGER
  //////////////////////////////////////////////////////

  if (role == "manager") {
    return [

      {
        "title": "Dashboard",
        "icon": Icons.dashboard,
      },

      {
        "title": "Buildings",
        "icon": Icons.apartment,
      },

      {
        "title": "Flats",
        "icon": Icons.home_work,
      },

      {
        "title": "Rooms",
        "icon": Icons.meeting_room,
      },

      {
        "title": "Tenants",
        "icon": Icons.people,
      },

      {
        "title": "Assignments",
        "icon": Icons.assignment_ind,
      },

      {
        "title": "Bills",
        "icon": Icons.receipt_long,
      },

      {
        "title": "Payments",
        "icon": Icons.payments,
      },

      {
        "title": "Electricity",
        "icon": Icons.electric_bolt,
      },

      {
        "title": "Complaints",
        "icon": Icons.report_problem,
      },

      {
        "title": "Documents",
        "icon": Icons.folder,
      },

      {
        "title": "Vacate Requests",
        "icon": Icons.logout,
      },

      {
        "title": "Notifications",
        "icon": Icons.notifications,
      },
    ];
  }

  //////////////////////////////////////////////////////
  // TENANT
  //////////////////////////////////////////////////////

  return [

    {
      "title": "Dashboard",
      "icon": Icons.dashboard,
    },

    {
      "title": "My Assignment",
      "icon": Icons.assignment,
    },

    {
      "title": "Bills",
      "icon": Icons.receipt_long,
    },

    {
      "title": "Payments",
      "icon": Icons.payments,
    },

    {
      "title": "Electricity",
      "icon": Icons.electric_bolt,
    },

    {
      "title": "Complaints",
      "icon": Icons.report_problem,
    },

    {
      "title": "Documents",
      "icon": Icons.folder,
    },

    {
      "title": "Vacate Request",
      "icon": Icons.logout,
    },

    {
      "title": "Notifications",
      "icon": Icons.notifications,
    },

    {
      "title": "Profile",
      "icon": Icons.person,
    },
  ];
}}