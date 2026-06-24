
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../layout/main_layout.dart';
import '../../services/api_service.dart';

class ProfilePage extends StatefulWidget {
  final String role;
  final String userName;
  final String renterId;

  const ProfilePage({
    super.key,
    required this.role,
    required this.userName,
    required this.renterId,
  });

  @override
  State<ProfilePage> createState() =>
      _ProfilePageState();
}

class _ProfilePageState
    extends State<ProfilePage> {

  final String baseUrl =
      ApiService.baseUrl;

  bool isLoading = true;
  bool isSaving = false;

  final nameController =
      TextEditingController();

  final emailController =
      TextEditingController();

  final phoneController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  @override
  void didUpdateWidget(
      covariant ProfilePage oldWidget) {

    super.didUpdateWidget(oldWidget);

    if (widget.renterId !=
            oldWidget.renterId &&
        widget.renterId.isNotEmpty) {

      setState(() {
        isLoading = true;
      });

      fetchProfile();
    }
  }

  @override
  void dispose() {

    nameController.dispose();

    emailController.dispose();

    phoneController.dispose();

    super.dispose();
  }

  //////////////////////////////////////////////////////
  // FETCH PROFILE
  //////////////////////////////////////////////////////

  Future<void> fetchProfile() async {

    if (widget.renterId.isEmpty) {

      setState(() {
        isLoading = false;
      });

      return;
    }

    try {

      final response =
          await http.get(

        Uri.parse(
          "$baseUrl/api/profile/?user_id=${widget.renterId}",
        ),
      );

      if (!mounted) return;

      final data =
          jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data["success"] == true) {

        final user = data["data"];

        setState(() {

          nameController.text =
              user["name"] ?? "";

          emailController.text =
              user["email"] ?? "";

          phoneController.text =
              user["phone"] ?? "";

          isLoading = false;
        });

      } else {

        setState(() {
          isLoading = false;
        });
      }

    } catch (e) {

      debugPrint(e.toString());

      if (mounted) {

        setState(() {
          isLoading = false;
        });
      }
    }
  }

  //////////////////////////////////////////////////////
  // UPDATE PROFILE
  //////////////////////////////////////////////////////

  Future<void> updateProfile() async {

    setState(() {
      isSaving = true;
    });

    try {

      final response =
          await http.put(

        Uri.parse(
          "$baseUrl/api/profile/?user_id=${widget.renterId}",
        ),

        headers: {

          "Content-Type":
              "application/json",
        },

        body: jsonEncode({

          "name":
              nameController.text.trim(),

          "phone":
              phoneController.text.trim(),
        }),
      );

      if (!mounted) return;

      final data =
          jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data["success"] == true) {

        ScaffoldMessenger.of(context)
            .showSnackBar(

          const SnackBar(
            content: Text(
              "Profile Updated",
            ),
          ),
        );

        fetchProfile();

      } else {

        ScaffoldMessenger.of(context)
            .showSnackBar(

          SnackBar(

            content: Text(

              data["error"] ??
                  "Update failed",
            ),
          ),
        );
      }

    } catch (e) {

      debugPrint(e.toString());
    }

    if (mounted) {

      setState(() {

        isSaving = false;
      });
    }
  }

  //////////////////////////////////////////////////////
  // UI
  //////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {

    return MainLayout(

      role: widget.role,

      userName: widget.userName,

      renterId: widget.renterId,

      currentIndex: 1,

      child:

          isLoading

              ? const Center(
                  child:
                      CircularProgressIndicator(),
                )

              : Center(

                  child:

                      SingleChildScrollView(

                    padding:
                        const EdgeInsets.all(20),

                    child:

                        ConstrainedBox(

                      constraints:

                          const BoxConstraints(
                        maxWidth: 600,
                      ),

                      child:

                          Card(

                        elevation: 2,

                        shape:

                            RoundedRectangleBorder(

                          borderRadius:
                              BorderRadius.circular(
                                  16),
                        ),

                        child:

                            Padding(

                          padding:
                              const EdgeInsets.all(
                                  24),

                          child:

                              Column(

                            children: [

                              CircleAvatar(

                                radius: 50,

                                child: Text(

                                  nameController
                                          .text
                                          .isEmpty

                                      ? "U"

                                      : nameController
                                          .text[0]
                                          .toUpperCase(),

                                  style:
                                      const TextStyle(

                                    fontSize: 34,

                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                  height: 15),

                              Text(

                                widget.role
                                    .toUpperCase(),

                                style:
                                    TextStyle(

                                  color:
                                      Colors.grey
                                          .shade700,

                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),

                              const SizedBox(
                                  height: 30),

                              TextField(

                                controller:
                                    nameController,

                                decoration:
                                    const InputDecoration(

                                  labelText:
                                      "Name",

                                  border:
                                      OutlineInputBorder(),
                                ),
                              ),

                              const SizedBox(
                                  height: 16),

                              TextField(

                                controller:
                                    emailController,

                                enabled:
                                    false,

                                decoration:
                                    const InputDecoration(

                                  labelText:
                                      "Email",

                                  border:
                                      OutlineInputBorder(),
                                ),
                              ),

                              const SizedBox(
                                  height: 16),

                              TextField(

                                controller:
                                    phoneController,

                                keyboardType:
                                    TextInputType
                                        .phone,

                                decoration:
                                    const InputDecoration(

                                  labelText:
                                      "Phone",

                                  border:
                                      OutlineInputBorder(),
                                ),
                              ),

                              const SizedBox(
                                  height: 30),

                              SizedBox(

                                width:
                                    double.infinity,

                                height: 50,

                                child:

                                    ElevatedButton(

                                  onPressed:

                                      isSaving

                                          ? null

                                          : updateProfile,

                                  child:

                                      Text(

                                    isSaving

                                        ? "Saving..."

                                        : "Update Profile",
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
