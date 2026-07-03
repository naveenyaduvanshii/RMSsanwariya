
import 'package:flutter/material.dart';

// Auth
import '../screens/login_page.dart';

// Dashboard
import '../screens/dashboard/dashboard.dart';

// Profile
import '../screens/profile/profile_page.dart';

// Managers
import '../screens/managers/managers_page.dart';

// Buildings
import '../screens/buildings/building_list.dart';

// Flats
import '../screens/flats/flats_page.dart';

// Rooms
import '../screens/rooms/room_list.dart';


// Assignments
import '../screens/assignments/assignments_page.dart';

// Rental Units
import '../screens/rental_units/rental_units_page.dart';

// Tenants
import '../screens/tenant/tenant_list.dart';

// Bills
import '../screens/bills/bills_page.dart';

// Payments
import '../screens/payment/payment_page.dart';

// Electricity
import '../screens/electricity/electricity_page.dart';

// Complaints
import '../screens/complaint/complaint_page.dart';

// Maintenance
import '../screens/maintenance/maintenance_page.dart';

// Documents
import '../screens/document/document_page.dart';

// Vacate Requests
import '../screens/vacate_requests/vacate_requests_page.dart';

// Notifications
import '../screens/notifications/notifications_page.dart';

// Reports
import '../screens/reports/reports_page.dart';

// Settings
import '../screens/settings/settings_page.dart';

class AppRoutes {

  //////////////////////////////////////////////////////
  // COMMON PAGE BUILDER
  //////////////////////////////////////////////////////

  static Widget page(
    BuildContext context,

    Widget Function(
      String role,
      String userName,
      String renterId,
    ) builder,
  ) {

    final args =
        ModalRoute.of(context)
            ?.settings
            .arguments
        as Map<String, dynamic>?;

    final role =
        args?["role"] ?? "owner";

    final userName =
        args?["userName"] ?? "User";

    final renterId =
        args?["renterId"] ?? "";

    return builder(
      role,
      userName,
      renterId,
    );
  }

  //////////////////////////////////////////////////////
  // ROUTES
  //////////////////////////////////////////////////////

  static Map<String, WidgetBuilder> routes = {

    //////////////////////////////////////////////////////
    // LOGIN
    //////////////////////////////////////////////////////

    '/login': (context) =>
        const LoginPage(),

    //////////////////////////////////////////////////////
    // DASHBOARD
    //////////////////////////////////////////////////////

    '/dashboard': (context) =>
        page(
      context,
      (role, userName, renterId) =>
          DashboardPage(
        role: role,
        userName: userName,
        renterId: renterId,
      ),
    ),

    //////////////////////////////////////////////////////
    // PROFILE
    //////////////////////////////////////////////////////

    '/profile': (context) =>
        page(
      context,
      (role, userName, renterId) =>
          ProfilePage(
        role: role,
        userName: userName,
        renterId: renterId,
      ),
    ),

    //////////////////////////////////////////////////////
    // MANAGERS
    //////////////////////////////////////////////////////

    '/managers': (context) =>
        page(
      context,
      (role, userName, renterId) =>
          ManagersPage(
        role: role,
        userName: userName,
        renterId: renterId,
      ),
    ),

    //////////////////////////////////////////////////////
    // BUILDINGS
    //////////////////////////////////////////////////////

    '/buildings': (context) =>
        page(
      context,
      (role, userName, renterId) =>
          BuildingsPage(
        role: role,
        userName: userName,
        renterId: renterId,
      ),
    ),

    //////////////////////////////////////////////////////
    // FLATS
    //////////////////////////////////////////////////////

    '/flats': (context) =>
        page(
      context,
      (role, userName, renterId) =>
          FlatsPage(
        role: role,
        userName: userName,
        renterId: renterId,
      ),
    ),

    //////////////////////////////////////////////////////
    // ROOMS
    //////////////////////////////////////////////////////

    '/rooms': (context) =>
        page(
      context,
      (role, userName, renterId) =>
          RoomsPage(
        role: role,
        userName: userName,
        renterId: renterId,
      ),
    ),


    //////////////////////////////////////////////////////
    // RENTAL UNITS
    //////////////////////////////////////////////////////

    '/rental-units': (context) =>
        page(
      context,
      (role, userName, renterId) =>
          RentalUnitsPage(
        role: role,
        userName: userName,
        renterId: renterId,
      ),
    ),

    //////////////////////////////////////////////////////
    // TENANTS
    //////////////////////////////////////////////////////

    '/tenants': (context) =>
        page(
      context,
      (role, userName, renterId) =>
          TenantsPage(
        role: role,
        userName: userName,
        renterId: renterId,
      ),
    ),

    //////////////////////////////////////////////////////
    // ASSIGNMENTS
    //////////////////////////////////////////////////////

    '/assignments': (context) =>
        page(
      context,
      (role, userName, renterId) =>
          TenantAssignmentsPage(
        role: role,
        userName: userName,
        renterId: renterId,
      ),
    ),

    '/my-assignment': (context) =>
        page(
      context,
      (role, userName, renterId) =>
          TenantAssignmentsPage(
        role: role,
        userName: userName,
        renterId: renterId,
      ),
    ),

    //////////////////////////////////////////////////////
    // BILLS
    //////////////////////////////////////////////////////

    '/bills': (context) =>
        page(
      context,
      (role, userName, renterId) =>
          BillsPage(
        role: role,
        userName: userName,
        renterId: renterId,
      ),
    ),

    //////////////////////////////////////////////////////
    // PAYMENTS
    //////////////////////////////////////////////////////

    '/payments': (context) =>
        page(
      context,
      (role, userName, renterId) =>
          PaymentsPage(
        role: role,
        userName: userName,
        renterId: renterId,
      ),
    ),

    //////////////////////////////////////////////////////
    // ELECTRICITY
    //////////////////////////////////////////////////////

    '/electricity': (context) =>
        page(
      context,
      (role, userName, renterId) =>
          ElectricityPage(
        role: role,
        userName: userName,
        renterId: renterId,
      ),
    ),

    //////////////////////////////////////////////////////
    // COMPLAINTS
    //////////////////////////////////////////////////////

    '/complaints': (context) =>
        page(
      context,
      (role, userName, renterId) =>
          ComplaintsPage(
        role: role,
        userName: userName,
        renterId: renterId,
      ),
    ),

    //////////////////////////////////////////////////////
    // MAINTENANCE
    //////////////////////////////////////////////////////

    '/maintenance': (context) =>
        page(
      context,
      (role, userName, renterId) =>
          MaintenancePage(
        role: role,
        userName: userName,
        renterId: renterId,
      ),
    ),

    //////////////////////////////////////////////////////
    // DOCUMENTS
    //////////////////////////////////////////////////////

    '/documents': (context) =>
        page(
      context,
      (role, userName, renterId) =>
          DocumentsPage(
        role: role,
        userName: userName,
        renterId: renterId,
      ),
    ),

    //////////////////////////////////////////////////////
    // VACATE REQUESTS
    //////////////////////////////////////////////////////

    '/vacate-requests': (context) =>
        page(
      context,
      (role, userName, renterId) =>
          VacatePipelinePage(
        role: role,
        userName: userName,
        renterId: renterId,
      ),
    ),

    '/vacate-request': (context) =>
        page(
      context,
      (role, userName, renterId) =>
          VacatePipelinePage(
        role: role,
        userName: userName,
        renterId: renterId,
      ),
    ),

    //////////////////////////////////////////////////////
    // NOTIFICATIONS
    //////////////////////////////////////////////////////

    '/notifications': (context) =>
        page(
      context,
      (role, userName, renterId) =>
          NotificationsPage(
        role: role,
        userName: userName,
        renterId: renterId,
      ),
    ),

    //////////////////////////////////////////////////////
    // REPORTS
    //////////////////////////////////////////////////////

    '/reports': (context) =>
        page(
      context,
      (role, userName, renterId) =>
          ReportsPage(
        role: role,
        userName: userName,
        renterId: renterId,
      ),
    ),

    //////////////////////////////////////////////////////
    // SETTINGS
    //////////////////////////////////////////////////////

    '/settings': (context) =>
        page(
      context,
      (role, userName, renterId) =>
          SettingsPage(
        role: role,
        userName: userName,
        renterId: renterId,
      ),
    ),
  };
}
