import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../layout/main_layout.dart';

class VacatePipelinePage extends StatefulWidget {
  final String role;
  final String userName;
  final String renterId;

  const VacatePipelinePage({
    super.key,
    required this.role,
    required this.userName,
    required this.renterId,
  });

  @override
  State<VacatePipelinePage> createState() =>
      _VacatePipelinePageState();
}

class _VacatePipelinePageState
    extends State<VacatePipelinePage> {

  final String baseUrl = "http://127.0.0.1:8000";

  List notices = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchNotices();
  }

  Future<void> fetchNotices() async {
    final res = await http.get(
      Uri.parse("$baseUrl/api/vacate-notices/"),
    );

    if (res.statusCode == 200) {
      setState(() {
        notices = jsonDecode(res.body);
        loading = false;
      });
    }
  }

  ////////////////////////////////////////////////////////////
  /// ACTIONS
  ////////////////////////////////////////////////////////////

  Future<void> approve(String id) async {
    await http.post(
      Uri.parse("$baseUrl/api/vacate-approve/$id/"),
    );
    fetchNotices();
  }

  Future<void> reject(String id) async {
    await http.post(
      Uri.parse("$baseUrl/api/vacate-reject/$id/"),
    );
    fetchNotices();
  }

  Future<void> complete(String id) async {
    await http.post(
      Uri.parse("$baseUrl/api/vacate-complete/$id/"),
    );
    fetchNotices();
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
      currentIndex: 15,
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: notices.length,
              itemBuilder: (context, index) {

                final n = notices[index];

                return _pipelineCard(n);
              },
            ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// PIPELINE CARD (ALL IN ONE)
  ////////////////////////////////////////////////////////////

  Widget _pipelineCard(Map n) {

    bool isPending = n["status"] == "pending";
    bool isApproved = n["status"] == "approved";
    bool isRejected = n["status"] == "rejected";
    bool isCompleted = n["status"] == "completed";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),

      padding: const EdgeInsets.all(20),

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
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          //////////////////////////////////////////////////////
          /// HEADER
          //////////////////////////////////////////////////////

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Tenant: ${n['tenant']}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(n["status"]),
            ],
          ),

          const SizedBox(height: 15),

          Text("Vacate Date: ${n['vacate_date']}"),
          Text("Reason: ${n['reason'] ?? ''}"),

          const SizedBox(height: 20),

          //////////////////////////////////////////////////////
          /// PIPELINE TIMELINE (SINGLE VIEW)
          //////////////////////////////////////////////////////

          _step("1. Request Submitted", true),

          _step("2. Owner Review",
              !isPending),

          _step("3. Approval Decision",
              isApproved || isRejected),

          _step("4. Checkout Check",
              isApproved),

          _step("5. Room Release",
              isCompleted),

          const SizedBox(height: 20),

          //////////////////////////////////////////////////////
          /// ACTIONS (ROLE BASED)
          //////////////////////////////////////////////////////

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ////////////////////////////////////////////////////
              /// OWNER ACTIONS
              ////////////////////////////////////////////////////
              if (widget.role == "owner" && isPending) ...[
                ElevatedButton.icon(
                  onPressed: () => approve(n["id"]),
                  icon: const Icon(Icons.check),
                  label: const Text("Approve"),
                ),
                OutlinedButton.icon(
                  onPressed: () => reject(n["id"]),
                  icon: const Icon(Icons.close),
                  label: const Text("Reject"),
                ),
              ],

              ////////////////////////////////////////////////////
              /// FINAL CHECKOUT
              ////////////////////////////////////////////////////
              if (widget.role == "owner" && isApproved) ...[
                ElevatedButton.icon(
                  onPressed: () => complete(n["id"]),
                  icon: const Icon(Icons.logout),
                  label: const Text("Complete Checkout"),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// STATUS BADGE
  ////////////////////////////////////////////////////////////

  Widget _statusBadge(String status) {

    Color color = Colors.grey;

    if (status == "approved") color = Colors.green;
    if (status == "rejected") color = Colors.red;
    if (status == "completed") color = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),

      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// STEP UI
  ////////////////////////////////////////////////////////////

  Widget _step(String title, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),

      child: Row(
        children: [

          Icon(
            done
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: done ? Colors.green : Colors.grey,
            size: 20,
          ),

          const SizedBox(width: 10),

          Text(title),
        ],
      ),
    );
  }
}