import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../layout/main_layout.dart';

class SettingsPage extends StatefulWidget {
  final String role;
  final String userName;
  final String renterId;

  const SettingsPage({
    super.key,
    required this.role,
    required this.userName,
    required this.renterId,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final String baseUrl = "http://127.0.0.1:8000";

  bool isLoading = true;
  bool isSaving = false;

  String? settingId;

  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController noticeDaysController = TextEditingController();
  final TextEditingController electricityRateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchSettings();
  }

  Future<void> fetchSettings() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/settings/"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          settingId = data["id"];
          companyNameController.text = data["company_name"] ?? "";
          phoneController.text = data["company_phone"] ?? "";
          emailController.text = data["company_email"] ?? "";
          addressController.text = data["company_address"] ?? "";
          noticeDaysController.text =
              data["default_notice_days"].toString();
          electricityRateController.text =
              data["default_electricity_rate"].toString();

          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint(e.toString());
      setState(() => isLoading = false);
    }
  }

  Future<void> updateSettings() async {
    if (companyNameController.text.isEmpty) return;

    setState(() => isSaving = true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/settings/update/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": settingId,
          "company_name": companyNameController.text.trim(),
          "company_phone": phoneController.text.trim(),
          "company_email": emailController.text.trim(),
          "company_address": addressController.text.trim(),
          "default_notice_days": int.tryParse(noticeDaysController.text) ?? 30,
          "default_electricity_rate":
              double.tryParse(electricityRateController.text) ?? 10.0,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("Settings Updated Successfully"),
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      role: widget.role,
      userName: widget.userName,
      renterId: widget.renterId,
      currentIndex: 18,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _header(),

                  const SizedBox(height: 20),

                  _formCard(),
                ],
              ),
            ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "System Settings",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Manage company configuration & defaults",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
          )
        ],
      ),
      child: Column(
        children: [
          _field("Company Name", companyNameController),
          const SizedBox(height: 15),
          _field("Phone", phoneController),
          const SizedBox(height: 15),
          _field("Email", emailController),
          const SizedBox(height: 15),
          _field("Address", addressController),
          const SizedBox(height: 15),
          _field("Default Notice Days", noticeDaysController),
          const SizedBox(height: 15),
          _field("Electricity Rate / Unit", electricityRateController),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isSaving ? null : updateSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                isSaving ? "Saving..." : "Update Settings",
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}