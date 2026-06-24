import 'package:flutter/material.dart';

import '../../layout/main_layout.dart';
import '../../services/api_service.dart';

class TenantAssignmentsPage extends StatefulWidget {
  final String role;
  final String userName;
  final String renterId;

  const TenantAssignmentsPage({
    super.key,
    required this.role,
    required this.userName,
    required this.renterId,
  });

  @override
  State<TenantAssignmentsPage> createState() =>
      _TenantAssignmentsPageState();
}

class _TenantAssignmentsPageState
    extends State<TenantAssignmentsPage> {

  //////////////////////////////////////////////////////
  /// DATA
  //////////////////////////////////////////////////////

  List assignments = [];

  List filteredAssignments = [];

  List tenants = [];

  List rentalUnits = [];

  //////////////////////////////////////////////////////
  /// LOADING
  //////////////////////////////////////////////////////

  bool isLoading = true;

  bool isSaving = false;

  bool isEdit = false;

  String editId = "";

  //////////////////////////////////////////////////////
  /// SEARCH
  //////////////////////////////////////////////////////

  final searchController =
      TextEditingController();

  //////////////////////////////////////////////////////
  /// FILTER
  //////////////////////////////////////////////////////

  String? filterStatus;

  //////////////////////////////////////////////////////
  /// FORM CONTROLLERS
  //////////////////////////////////////////////////////

  final securityDepositController =
      TextEditingController();

  final discountController =
      TextEditingController();

  final finalRentController =
      TextEditingController();

  final startDateController =
      TextEditingController();

  //////////////////////////////////////////////////////
  /// FORM VALUES
  //////////////////////////////////////////////////////

  String? selectedTenant;

  String? selectedRentalUnit;

  bool exclusiveOccupancy = false;

  //////////////////////////////////////////////////////
  /// INIT
  //////////////////////////////////////////////////////

  @override
  void initState() {

    super.initState();

    loadInitialData();

  }

  @override
  void dispose() {

    searchController.dispose();

    securityDepositController.dispose();

    discountController.dispose();

    finalRentController.dispose();

    startDateController.dispose();

    super.dispose();

  }

  //////////////////////////////////////////////////////
  /// LOAD INITIAL DATA
  //////////////////////////////////////////////////////

  Future<void> loadInitialData() async {

    setState(() {

      isLoading = true;

    });

    await Future.wait([

      loadAssignments(),

      loadTenants(),

      loadRentalUnits(),

    ]);

    if (mounted) {

      setState(() {

        isLoading = false;

      });

    }

  }

  //////////////////////////////////////////////////////
  /// CLEAR FORM
  //////////////////////////////////////////////////////

  void clearForm() {

    selectedTenant = null;

    selectedRentalUnit = null;

    exclusiveOccupancy = false;

    securityDepositController.clear();

    discountController.clear();

    finalRentController.clear();

    startDateController.clear();

    editId = "";

    isEdit = false;

  }

  //////////////////////////////////////////////////////
  /// SNACKBAR
  //////////////////////////////////////////////////////

  void showMessage(
    String message,
  ) {

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(

        content:
            Text(message),

      ),

    );

  }
    //////////////////////////////////////////////////////
  /// LOAD ASSIGNMENTS
  //////////////////////////////////////////////////////

  Future<void> loadAssignments() async {

    try {

      final response =
          await ApiService.get(
        "api/tenant-assignments/",
      );

      assignments =
          response["data"] ?? [];

      filteredAssignments =
          List.from(assignments);

      if (mounted) {

        setState(() {});

      }

    }

    catch (e) {

      debugPrint(
        "Assignment Error : $e",
      );

    }

  }

  //////////////////////////////////////////////////////
  /// LOAD TENANTS
  //////////////////////////////////////////////////////

  Future<void> loadTenants() async {

    try {

      final response =
          await ApiService.get(
        "api/tenants-dropdown/",
      );

      tenants =
          response["data"] ?? [];

      if (mounted) {

        setState(() {});

      }

    }

    catch (e) {

      debugPrint(
        "Tenant Error : $e",
      );

    }

  }

  //////////////////////////////////////////////////////
  /// LOAD RENTAL UNITS
  //////////////////////////////////////////////////////

  Future<void> loadRentalUnits() async {

    try {

      final response =
          await ApiService.get(
        "api/rental-units-dropdown/",
      );

      rentalUnits =
          response["data"] ?? [];

      if (mounted) {

        setState(() {});

      }

    }

    catch (e) {

      debugPrint(
        "Rental Unit Error : $e",
      );

    }

  }

  //////////////////////////////////////////////////////
  /// SEARCH + FILTER
  //////////////////////////////////////////////////////

  void applyFilters() {

    final query =

        searchController.text

            .trim()

            .toLowerCase();

    filteredAssignments =

        assignments.where((item) {

      final tenantName =

          (item["tenant_name"] ?? "")

              .toString()

              .toLowerCase();

      final phone =

          (item["tenant_phone"] ?? "")

              .toString()

              .toLowerCase();

      final room =

          (item["room_number"] ?? "")

              .toString()

              .toLowerCase();

      final bed =

          (item["bed_number"] ?? "")

              .toString()

              .toLowerCase();

      final searchMatch =

          tenantName.contains(query)

          ||

          phone.contains(query)

          ||

          room.contains(query)

          ||

          bed.contains(query);

      final statusMatch =

          filterStatus == null

          ||

          item["status"]

                  ?.toString()

              ==

              filterStatus;

      return

          searchMatch

          &&

          statusMatch;

    }).toList();

    setState(() {});

  }

  //////////////////////////////////////////////////////
  /// RESET FILTER
  //////////////////////////////////////////////////////

  void resetFilters() {

    searchController.clear();

    filterStatus = null;

    filteredAssignments =

        List.from(assignments);

    setState(() {});

  }

  //////////////////////////////////////////////////////
  /// VALIDATE FORM
  //////////////////////////////////////////////////////

  bool validateForm() {

    if (selectedTenant == null) {

      showMessage(
        "Select Tenant",
      );

      return false;

    }

    if (selectedRentalUnit == null) {

      showMessage(
        "Select Rental Unit",
      );

      return false;

    }

    if (finalRentController
        .text
        .trim()
        .isEmpty) {

      showMessage(
        "Enter Final Rent",
      );

      return false;

    }

    if (startDateController
        .text
        .trim()
        .isEmpty) {

      showMessage(
        "Select Start Date",
      );

      return false;

    }

    return true;

  }

  //////////////////////////////////////////////////////
  /// DATE PICKER
  //////////////////////////////////////////////////////

  Future<void> pickStartDate() async {

    final picked =

        await showDatePicker(

      context: context,

      initialDate:

          DateTime.now(),

      firstDate:

          DateTime(2020),

      lastDate:

          DateTime(2100),

    );

    if (picked != null) {

      startDateController.text =

          "${picked.year}-"

          "${picked.month.toString().padLeft(2, '0')}-"

          "${picked.day.toString().padLeft(2, '0')}";

      setState(() {});

    }

  }
    //////////////////////////////////////////////////////
  /// ADD ASSIGNMENT
  //////////////////////////////////////////////////////

  Future<void> addAssignment() async {

    if (!validateForm()) return;

    setState(() {

      isSaving = true;

    });

    try {

      await ApiService.post(

        "api/add-tenant-assignment/",

        {

          "tenant_id":
              selectedTenant,

          "rental_unit_id":
              selectedRentalUnit,

          "exclusive_occupancy":
              exclusiveOccupancy,

          "security_deposit":

              double.tryParse(

                    securityDepositController
                        .text,

                  ) ??

                  0,

          "discount_percent":

              double.tryParse(

                    discountController
                        .text,

                  ) ??

                  0,

          "final_rent":

              double.tryParse(

                    finalRentController
                        .text,

                  ) ??

                  0,

          "rent_start_date":

              startDateController
                  .text,

        },

      );

      if (mounted) {

        Navigator.pop(context);

        clearForm();

        await loadAssignments();

        showMessage(

          "Tenant Assigned Successfully",

        );

      }

    }

    catch (e) {

      debugPrint(e.toString());

      showMessage(

        "Failed To Assign Tenant",

      );

    }

    if (mounted) {

      setState(() {

        isSaving = false;

      });

    }

  }

  //////////////////////////////////////////////////////
  /// UPDATE ASSIGNMENT
  //////////////////////////////////////////////////////

  Future<void> updateAssignment() async {

    if (editId.isEmpty) {

      return;

    }

    setState(() {

      isSaving = true;

    });

    try {

      await ApiService.put(

        "api/update-tenant-assignment/$editId/",

        {

          "security_deposit":

              double.tryParse(

                    securityDepositController
                        .text,

                  ) ??

                  0,

          "discount_percent":

              double.tryParse(

                    discountController
                        .text,

                  ) ??

                  0,

          "final_rent":

              double.tryParse(

                    finalRentController
                        .text,

                  ) ??

                  0,

        },

      );

      if (mounted) {

        Navigator.pop(context);

        clearForm();

        await loadAssignments();

        showMessage(

          "Assignment Updated",

        );

      }

    }

    catch (e) {

      debugPrint(e.toString());

      showMessage(

        "Update Failed",

      );

    }

    if (mounted) {

      setState(() {

        isSaving = false;

      });

    }

  }

  //////////////////////////////////////////////////////
  /// VACATE TENANT
  //////////////////////////////////////////////////////

  Future<void> vacateTenant(

    String assignmentId,

  ) async {

    final confirm =

        await showDialog<bool>(

              context: context,

              builder: (_) {

                return AlertDialog(

                  title:

                      const Text(

                    "Vacate Tenant",

                  ),

                  content:

                      const Text(

                    "Are you sure?",

                  ),

                  actions: [

                    TextButton(

                      onPressed: () {

                        Navigator.pop(

                          context,

                          false,

                        );

                      },

                      child:

                          const Text(

                        "Cancel",

                      ),

                    ),

                    ElevatedButton(

                      onPressed: () {

                        Navigator.pop(

                          context,

                          true,

                        );

                      },

                      child:

                          const Text(

                        "Vacate",

                      ),

                    ),

                  ],

                );

              },

            ) ??

            false;

    if (!confirm) {

      return;

    }

    try {

      await ApiService.put(

        "api/vacate-tenant/$assignmentId/",

        {},

      );

      await loadAssignments();

      showMessage(

        "Tenant Vacated",

      );

    }

    catch (e) {

      debugPrint(e.toString());

      showMessage(

        "Vacate Failed",

      );

    }

  }

  //////////////////////////////////////////////////////
  /// DELETE ASSIGNMENT
  //////////////////////////////////////////////////////

  Future<void> deleteAssignment(

    String assignmentId,

  ) async {

    final confirm =

        await showDialog<bool>(

              context: context,

              builder: (_) {

                return AlertDialog(

                  title:

                      const Text(

                    "Delete Assignment",

                  ),

                  content:

                      const Text(

                    "Are you sure?",

                  ),

                  actions: [

                    TextButton(

                      onPressed: () {

                        Navigator.pop(

                          context,

                          false,

                        );

                      },

                      child:

                          const Text(

                        "Cancel",

                      ),

                    ),

                    ElevatedButton(

                      onPressed: () {

                        Navigator.pop(

                          context,

                          true,

                        );

                      },

                      child:

                          const Text(

                        "Delete",

                      ),

                    ),

                  ],

                );

              },

            ) ??

            false;

    if (!confirm) {

      return;

    }

    try {

      await ApiService.delete(

        "api/delete-assignment/$assignmentId/",

      );

      await loadAssignments();

      showMessage(

        "Deleted Successfully",

      );

    }

    catch (e) {

      debugPrint(e.toString());

      showMessage(

        "Delete Failed",

      );

    }

  }
    //////////////////////////////////////////////////////
  /// TEXT FIELD
  //////////////////////////////////////////////////////

  Widget buildField(
    String label,
    TextEditingController controller,
  ) {

    return Padding(

      padding: const EdgeInsets.only(
        bottom: 12,
      ),

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Text(

            label,

            style: const TextStyle(

              fontWeight:
                  FontWeight.w600,

            ),

          ),

          const SizedBox(
            height: 6,
          ),

          TextField(

            controller:
                controller,

            decoration:
                InputDecoration(

              filled: true,

              fillColor:

                  Colors.grey.shade100,

              border:

                  OutlineInputBorder(

                borderRadius:

                    BorderRadius.circular(
                  12,
                ),

              ),

            ),

          ),

        ],

      ),

    );

  }

  //////////////////////////////////////////////////////
  /// ADD / EDIT DIALOG
  //////////////////////////////////////////////////////

  void showAssignmentDialog({

    Map? assignment,

  }) {

    clearForm();

    ////////////////////////////////////////////////////
    /// EDIT MODE
    ////////////////////////////////////////////////////

    if (assignment != null) {

      isEdit = true;

      editId =

          assignment["id"]

                  ?.toString() ??

              "";

      selectedTenant =

          assignment["tenant_id"]

              ?.toString();

      selectedRentalUnit =

          assignment["rental_unit_id"]

              ?.toString();

      securityDepositController.text =

          assignment["security_deposit"]

                  ?.toString() ??

              "0";

      discountController.text =

          assignment["discount_percent"]

                  ?.toString() ??

              "0";

      finalRentController.text =

          assignment["final_rent"]

                  ?.toString() ??

              "0";

      startDateController.text =

          assignment["rent_start_date"]

                  ?.toString() ??

              "";

      exclusiveOccupancy =

          assignment[
                  "exclusive_occupancy"]

              ==

              true;

    }

    ////////////////////////////////////////////////////
    /// SHOW DIALOG
    ////////////////////////////////////////////////////

    showDialog(

      context: context,

      builder: (_) {

        return StatefulBuilder(

          builder:

              (

                context,

                setDialogState,

              ) {

            return AlertDialog(

              title: Text(

                isEdit

                    ?

                    "Edit Assignment"

                    :

                    "Assign Tenant",

              ),

              content:

                  SizedBox(

                width: 500,

                child:

                    SingleChildScrollView(

                  child:

                      Column(

                    mainAxisSize:

                        MainAxisSize.min,

                    children: [

                      //////////////////////////////////////////////////
                      /// TENANT
                      //////////////////////////////////////////////////

                      DropdownButtonFormField<
                          String>(

                        value:

                            selectedTenant,

                        decoration:

                            const InputDecoration(

                          labelText:

                              "Tenant",

                          border:

                              OutlineInputBorder(),

                        ),

                        items:

                            tenants.map(

                          (tenant) {

                            return DropdownMenuItem<
                                String>(

                              value:

                                  tenant["id"]
                                      .toString(),

                              child: Text(

                                "${tenant["name"]}"

                                " (${tenant["phone"]})",

                              ),

                            );

                          },

                        ).toList(),

                        onChanged:

                            isEdit

                                ?

                                null

                                :

                                (value) {

                                    setDialogState(

                                      () {

                                        selectedTenant =
                                            value;

                                      },

                                    );

                                  },

                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      //////////////////////////////////////////////////
                      /// RENTAL UNIT
                      //////////////////////////////////////////////////

                      DropdownButtonFormField<
                          String>(

                        value:

                            selectedRentalUnit,

                        decoration:

                            const InputDecoration(

                          labelText:

                              "Rental Unit",

                          border:

                              OutlineInputBorder(),

                        ),

                        items:

                            rentalUnits.map(

                          (unit) {

                            return DropdownMenuItem<
                                String>(

                              value:

                                  unit["id"]
                                      .toString(),

                              child: Text(

                                "${unit["unit_type"]}"

                                " | "

                                "₹${unit["rent"]}",

                              ),

                            );

                          },

                        ).toList(),
                            onChanged:

                            isEdit

                                ?

                                null

                                :

                                (value) {

                                  setDialogState(() {

                                    selectedRentalUnit =
                                        value;

                                    final selected =

                                        rentalUnits.firstWhere(

                                      (e) =>

                                          e["id"]
                                                  .toString()

                                              ==

                                              value,

                                      orElse:

                                          () =>

                                              {},

                                    );

                                    if (selected
                                        .isNotEmpty) {

                                      finalRentController
                                              .text =

                                          selected["rent"]
                                              .toString();

                                    }

                                  });

                                },

                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      //////////////////////////////////////////////////
                      /// SECURITY DEPOSIT
                      //////////////////////////////////////////////////

                      buildField(

                        "Security Deposit",

                        securityDepositController,

                      ),

                      //////////////////////////////////////////////////
                      /// DISCOUNT
                      //////////////////////////////////////////////////

                      buildField(

                        "Discount %",

                        discountController,

                      ),

                      //////////////////////////////////////////////////
                      /// FINAL RENT
                      //////////////////////////////////////////////////

                      buildField(

                        "Final Rent",

                        finalRentController,

                      ),

                      //////////////////////////////////////////////////
                      /// START DATE
                      //////////////////////////////////////////////////

                      TextField(

                        controller:

                            startDateController,

                        readOnly: true,

                        decoration:

                            InputDecoration(

                          labelText:

                              "Start Date",

                          border:

                              const OutlineInputBorder(),

                          suffixIcon:

                              IconButton(

                            icon:

                                const Icon(

                              Icons.calendar_month,

                            ),

                            onPressed:

                                pickStartDate,

                          ),

                        ),

                        onTap:

                            pickStartDate,

                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      //////////////////////////////////////////////////
                      /// EXCLUSIVE OCCUPANCY
                      //////////////////////////////////////////////////

                      SwitchListTile(

                        contentPadding:

                            EdgeInsets.zero,

                        title:

                            const Text(

                          "Exclusive Occupancy",

                        ),

                        subtitle:

                            const Text(

                          "Tenant occupies entire unit",

                        ),

                        value:

                            exclusiveOccupancy,

                        onChanged:

                            (value) {

                          setDialogState(

                            () {

                              exclusiveOccupancy =
                                  value;

                            },

                          );

                        },

                      ),

                    ],

                  ),

                ),

              ),

              //////////////////////////////////////////////////////
              /// ACTIONS
              //////////////////////////////////////////////////////

              actions: [

                TextButton(

                  onPressed: () {

                    Navigator.pop(
                      context,
                    );

                  },

                  child: const Text(
                    "Cancel",
                  ),

                ),

                ElevatedButton(

                  onPressed:

                      isSaving

                          ?

                          null

                          :

                          () {

                            if (isEdit) {

                              updateAssignment();

                            }

                            else {

                              addAssignment();

                            }

                          },

                  child:

                      isSaving

                          ?

                          const SizedBox(

                              width: 18,

                              height: 18,

                              child:

                                  CircularProgressIndicator(

                                strokeWidth: 2,

                              ),

                            )

                          :

                          Text(

                            isEdit

                                ?

                                "Update"

                                :

                                "Assign",

                          ),

                ),

              ],

            );

          },

        );

      },

    );

  }
    //////////////////////////////////////////////////////
  /// ASSIGNMENT CARD
  //////////////////////////////////////////////////////

  Widget buildAssignmentCard(
    Map assignment,
  ) {

    final status =
        assignment["status"] ?? "";

    Color statusColor =
        Colors.orange;

    if (status == "active") {

      statusColor = Colors.green;

    }

    else if (status == "vacated") {

      statusColor = Colors.red;

    }

    //////////////////////////////////////////////////////
    /// UNIT NAME
    //////////////////////////////////////////////////////

    String unitName = "";

    if ((assignment["bed_number"] ?? "")
        .toString()
        .isNotEmpty) {

      unitName =

          "${assignment["building_name"]} > "

          "${assignment["floor_name"]} > "

          "${assignment["flat_number"]} > "

          "${assignment["room_number"]} > "

          "${assignment["bed_number"]}";

    }

    else if ((assignment["room_number"] ?? "")
        .toString()
        .isNotEmpty) {
      final flatPart = (assignment["flat_number"] ?? "").toString().isNotEmpty
          ? "${assignment["flat_number"]} > "
          : "";

      unitName =

          "${assignment["building_name"]} > "

          "${assignment["floor_name"]} > "

          "$flatPart"

          "${assignment["room_number"]}";

    }

    else if ((assignment["flat_number"] ?? "")
        .toString()
        .isNotEmpty) {

      unitName =

          "${assignment["building_name"]} > "

          "${assignment["floor_name"]} > "

          "${assignment["flat_number"]}";

    }

    else {

      unitName =
          assignment["building_name"] ?? "";

    }

    return Card(

      elevation: 2,

      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      child: Padding(

        padding:
            const EdgeInsets.all(
          16,
        ),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            //////////////////////////////////////////////////////
            /// HEADER
            //////////////////////////////////////////////////////

            Row(

              children: [

                const CircleAvatar(

                  child:
                      Icon(Icons.person),

                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(

                  child: Column(

                    crossAxisAlignment:

                        CrossAxisAlignment
                            .start,

                    children: [

                      Text(

                        assignment[
                                "tenant_name"] ??

                            "",

                        style:

                            const TextStyle(

                          fontWeight:

                              FontWeight
                                  .bold,

                          fontSize: 16,

                        ),

                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(

                        assignment[
                                "tenant_phone"] ??

                            "",

                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Text(

                        unitName,

                        style:

                            TextStyle(

                          color:

                              Colors.grey
                                  .shade700,

                        ),

                      ),

                    ],

                  ),

                ),

                //////////////////////////////////////////////////////
                /// STATUS
                //////////////////////////////////////////////////////

                Container(

                  padding:

                      const EdgeInsets.symmetric(

                    horizontal: 10,

                    vertical: 4,

                  ),

                  decoration:

                      BoxDecoration(

                    color:

                        statusColor
                            .withOpacity(
                      0.15,
                    ),

                    borderRadius:

                        BorderRadius
                            .circular(
                      20,
                    ),

                  ),

                  child: Text(

                    status
                        .toUpperCase(),

                    style:

                        TextStyle(

                      color:

                          statusColor,

                      fontWeight:

                          FontWeight
                              .bold,

                    ),

                  ),

                ),

              ],

            ),

            const SizedBox(
              height: 16,
            ),

            //////////////////////////////////////////////////////
            /// RENT DETAILS
            //////////////////////////////////////////////////////

            Wrap(

              spacing: 20,

              runSpacing: 10,

              children: [

                Text(

                  "Rent : ₹"

                  "${assignment["final_rent"]}",

                ),

                Text(

                  "Deposit : ₹"

                  "${assignment["security_deposit"]}",

                ),

                Text(

                  "Discount : "

                  "${assignment["discount_percent"]}%",

                ),

              ],

            ),

            const SizedBox(
              height: 10,
            ),

            //////////////////////////////////////////////////////
            /// DATES
            //////////////////////////////////////////////////////

            Text(

              "Start Date : "

              "${assignment["rent_start_date"]}",

            ),

            if (assignment[
                    "rent_end_date"] !=
                null)

              Text(

                "End Date : "

                "${assignment["rent_end_date"]}",

              ),

            const SizedBox(
              height: 12,
            ),

            //////////////////////////////////////////////////////
            /// OCCUPANCY
            //////////////////////////////////////////////////////

            Row(

              children: [

                Icon(

                  assignment[
                          "exclusive_occupancy"]

                      ==

                      true

                      ?

                      Icons.lock

                      :

                      Icons.groups,

                  color:

                      assignment[
                              "exclusive_occupancy"]

                          ==

                          true

                          ?

                          Colors.red

                          :

                          Colors.green,

                ),

                const SizedBox(
                  width: 8,
                ),

                Text(

                  assignment[
                          "exclusive_occupancy"]

                      ==

                      true

                      ?

                      "Exclusive Occupancy"

                      :

                      "Shared Occupancy",

                ),

              ],

            ),

            //////////////////////////////////////////////////////
            /// ACTIONS
            //////////////////////////////////////////////////////

            if (

            widget.role == "owner"

                ||

                widget.role == "manager")

              Row(

                mainAxisAlignment:

                    MainAxisAlignment.end,

                children: [

                  IconButton(

                    icon:
                        const Icon(

                      Icons.edit,

                      color:
                          Colors.blue,

                    ),

                    onPressed: () {

                      showAssignmentDialog(

                        assignment:

                            assignment,

                      );

                    },

                  ),

                  if (status ==
                      "active")

                    IconButton(

                      icon:
                          const Icon(

                        Icons.logout,

                        color:

                            Colors.orange,

                      ),

                      onPressed: () {

                        vacateTenant(

                          assignment["id"]
                              .toString(),

                        );

                      },

                    ),

                  IconButton(

                    icon:
                        const Icon(

                      Icons.delete,

                      color:
                          Colors.red,

                    ),

                    onPressed: () {

                      deleteAssignment(

                        assignment["id"]
                            .toString(),

                      );

                    },

                  ),

                ],

              ),

          ],

        ),

      ),

    );

  }
    //////////////////////////////////////////////////////
  /// BUILD
  //////////////////////////////////////////////////////

  @override
  Widget build(
    BuildContext context,
  ) {

    final isDesktop =

        MediaQuery.of(context)
                .size
                .width >

            900;

    return MainLayout(

      role: widget.role,

      userName:
          widget.userName,
      renterId: widget.renterId,
      currentIndex: 8,

      child: Stack(

        children: [

          //////////////////////////////////////////////////////
          /// BODY
          //////////////////////////////////////////////////////

          isLoading

              ? const Center(

                  child:

                      CircularProgressIndicator(),

                )

              : Column(

                  children: [

                    //////////////////////////////////////////////////////
                    /// SEARCH
                    //////////////////////////////////////////////////////

                    TextField(

                      controller:

                          searchController,

                      onChanged:

                          (_) {

                        applyFilters();

                      },

                      decoration:

                          InputDecoration(

                        hintText:

                            "Search Tenant / Phone / Room",

                        prefixIcon:

                            const Icon(

                          Icons.search,

                        ),

                        border:

                            OutlineInputBorder(

                          borderRadius:

                              BorderRadius.circular(

                            12,

                          ),

                        ),

                      ),

                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    //////////////////////////////////////////////////////
                    /// FILTER
                    //////////////////////////////////////////////////////

                    Row(

                      children: [

                        Expanded(

                          child:

                              DropdownButtonFormField<String>(

                            value:

                                filterStatus,

                            decoration:

                                const InputDecoration(

                              labelText:

                                  "Status",

                              border:

                                  OutlineInputBorder(),

                            ),

                            items: const [

                              DropdownMenuItem(

                                value:

                                    "active",

                                child:

                                    Text(

                                  "Active",

                                ),

                              ),

                              DropdownMenuItem(

                                value:

                                    "pending",

                                child:

                                    Text(

                                  "Pending",

                                ),

                              ),

                              DropdownMenuItem(

                                value:

                                    "vacated",

                                child:

                                    Text(

                                  "Vacated",

                                ),

                              ),

                            ],

                            onChanged:

                                (value) {

                              setState(() {

                                filterStatus =

                                    value;

                              });

                              applyFilters();

                            },

                          ),

                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        OutlinedButton.icon(

                          onPressed:

                              resetFilters,

                          icon:

                              const Icon(

                            Icons.refresh,

                          ),

                          label:

                              const Text(

                            "Reset",

                          ),

                        ),

                      ],

                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    //////////////////////////////////////////////////////
                    /// LIST
                    //////////////////////////////////////////////////////

                    Expanded(

                      child:

                          filteredAssignments
                                  .isEmpty

                              ? const Center(

                                  child:

                                      Text(

                                    "No Assignments Found",

                                  ),

                                )

                              : RefreshIndicator(

                                  onRefresh:

                                      loadAssignments,

                                  child:

                                      ListView.builder(

                                    physics:

                                        const AlwaysScrollableScrollPhysics(),

                                    itemCount:

                                        filteredAssignments.length,

                                    itemBuilder:

                                        (

                                      context,

                                      index,

                                    ) {

                                      return buildAssignmentCard(

                                        filteredAssignments[
                                            index],

                                      );

                                    },

                                  ),

                                ),

                    ),

                  ],

                ),

          //////////////////////////////////////////////////////
          /// FAB
          //////////////////////////////////////////////////////

          if (

          widget.role ==

                  "owner"

              ||

              widget.role ==

                  "manager")

            Positioned(

              bottom: 20,

              right: 20,

              child:

                  FloatingActionButton.extended(

                onPressed: () {

                  showAssignmentDialog();

                },

                icon:

                    const Icon(

                  Icons.add,

                ),

                label:

                    const Text(

                  "Assign",

                ),

              ),

            ),

        ],

      ),

    );

  }

}