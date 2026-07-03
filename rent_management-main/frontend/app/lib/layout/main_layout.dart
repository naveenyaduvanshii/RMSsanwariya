import 'package:flutter/material.dart';

import 'sidebar.dart';
import 'drawer.dart';
import 'top_navbar.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final String role;
  final String userName;
  final String renterId;
  final int currentIndex;

  final Widget? floatingActionButton; // ✅ ADD THIS

  const MainLayout({
    super.key,
    required this.child,
    required this.role,
    required this.userName,
    required this.renterId,
    required this.currentIndex,
    this.floatingActionButton,
  });
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {

  //////////////////////////////////////////////////////
  // MENU CLICK
  //////////////////////////////////////////////////////

  void onMenuTap(int index) {

  final routes = getRoutesByRole(widget.role);

  if (index >= routes.length) return;

  final route = routes[index];

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
  //////////////////////////////////////////////////////
  // PAGE TITLE
  //////////////////////////////////////////////////////

  String getCurrentPageTitle() {

    final titles =
        getTitlesByRole(widget.role);

    if (widget.currentIndex >=
        titles.length) {
      return "";
    }

    return titles[widget.currentIndex];
  }

  //////////////////////////////////////////////////////
  // ROUTES
  //////////////////////////////////////////////////////

  List<String> getRoutesByRole(
      String role) {

    if (role == "owner") {
      return [

        '/dashboard',
        '/profile',
        '/managers',
        '/buildings',
        '/flats',
        '/rooms',
        '/rental-units',
        '/tenants',
        '/assignments',
        '/bills',
        '/payments',
        '/electricity',
        '/complaints',
        '/maintenance',
        '/documents',
        '/vacate-requests',
        '/notifications',
        '/reports',
        '/settings',
      ];
    }

    if (role == "manager") {
      return [

        '/dashboard',
        '/buildings',
        '/flats',
        '/rooms',
        '/tenants',
        '/assignments',
        '/bills',
        '/payments',
        '/electricity',
        '/complaints',
        '/maintenance',
        '/documents',
        '/vacate-requests',
        '/notifications',
      ];
    }

    return [

      '/dashboard',
      '/my-assignment',
      '/bills',
      '/payments',
      '/electricity',
      '/complaints',
      '/documents',
      '/vacate-request',
      '/notifications',
      '/profile',
    ];
  }

  //////////////////////////////////////////////////////
  // TITLES
  //////////////////////////////////////////////////////

  List<String> getTitlesByRole(
      String role) {

    if (role == "owner") {
      return [

        "Dashboard",
        "Profile",
        "Managers",
        "Buildings",
        "Flats",
        "Rooms",
        "Rental Units",
        "Tenants",
        "Assignments",
        "Bills",
        "Payments",
        "Electricity",
        "Complaints",
        "Maintenance",
        "Documents",
        "Vacate Requests",
        "Notifications",
        "Reports",
        "Settings",
      ];
    }

    if (role == "manager") {
      return [

        "Dashboard",
        "Buildings",
        "Flats",
        "Rooms",
        "Tenants",
        "Assignments",
        "Bills",
        "Payments",
        "Electricity",
        "Complaints",
        "Maintenance",
        "Documents",
        "Vacate Requests",
        "Notifications",
      ];
    }

    return [

      "Dashboard",
      "My Assignment",
      "Bills",
      "Payments",
      "Electricity",
      "Complaints",
      "Documents",
      "Vacate Request",
      "Notifications",
      "Profile",
    ];
  }

  @override
  Widget build(BuildContext context) {
    final currentRouteName = ModalRoute.of(context)?.settings.name;
    final routes = getRoutesByRole(widget.role);
    final activeIndex = (currentRouteName != null && routes.contains(currentRouteName))
        ? routes.indexOf(currentRouteName)
        : widget.currentIndex;

    final isMobile =
        MediaQuery.of(context).size.width < 800;

    return Scaffold(

      backgroundColor:
          const Color(0xFF0F172A),

      drawer: isMobile
          ? AppDrawer(
              role: widget.role,
              selectedIndex: activeIndex,
              onTap: onMenuTap,
            )
          : null,

      body: SafeArea(

        child: Column(
          children: [

            TopNavbar(
              isMobile: isMobile,
            ),

            Expanded(

              child: Row(
                children: [

                  //////////////////////////////////////////////////////
                  // DESKTOP SIDEBAR
                  //////////////////////////////////////////////////////

                  if (!isMobile)
                    Sidebar(
                      role: widget.role,
                      selectedIndex: activeIndex,
                      onTap: onMenuTap,
                    ),

                  //////////////////////////////////////////////////////
                  // PAGE BODY
                  //////////////////////////////////////////////////////

                  Expanded(

                    child: Container(

                      width: double.infinity,

                      color:
                          const Color(0xFFF1F5F9),

                      padding:
                          const EdgeInsets.all(20),

                      child: Column(

                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          Text(

                            getCurrentPageTitle(),

                            style:
                                const TextStyle(

                              fontSize: 28,

                              fontWeight:
                                  FontWeight.bold,

                              color:
                                  Color(0xFF0F172A),
                            ),
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          Expanded(
                            child: widget.child,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}