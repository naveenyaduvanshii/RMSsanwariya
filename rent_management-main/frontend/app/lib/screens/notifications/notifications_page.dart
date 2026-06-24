import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../layout/main_layout.dart';

class NotificationsPage extends StatefulWidget {
  final String role;
  final String userName;
  final String renterId;

  const NotificationsPage({
    super.key,
    required this.role,
    required this.userName,
    required this.renterId,
  });

  @override
  State<NotificationsPage> createState() =>
      _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final String baseUrl = "http://127.0.0.1:8000";

  List notifications = [];
  bool isLoading = true;

  final TextEditingController titleController =
      TextEditingController();

  final TextEditingController messageController =
      TextEditingController();

  String? selectedRole;

  bool isSending = false;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  ////////////////////////////////////////////////////////////
  /// FETCH NOTIFICATIONS
  ////////////////////////////////////////////////////////////
  Future<void> fetchNotifications() async {
    try {
      final url =
          "$baseUrl/api/notifications/?user_id=${widget.renterId}&role=${widget.role}";

      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        setState(() {
          notifications = jsonDecode(res.body);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
      setState(() => isLoading = false);
    }
  }

  ////////////////////////////////////////////////////////////
  /// CREATE SINGLE NOTIFICATION (OPTIONAL ADMIN TOOL)
  ////////////////////////////////////////////////////////////
  Future<void> sendNotification() async {
    if (titleController.text.isEmpty) return;

    setState(() => isSending = true);

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/create-notification/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user": widget.renterId,
          "title": titleController.text,
          "message": messageController.text,
        }),
      );

      if (res.statusCode == 200) {
        Navigator.pop(context);
        clear();
        fetchNotifications();
        msg("Notification sent", Colors.green);
      }
    } catch (e) {
      msg(e.toString(), Colors.red);
    }

    setState(() => isSending = false);
  }

  ////////////////////////////////////////////////////////////
  /// BULK NOTIFICATION (OWNER / MANAGER)
  ////////////////////////////////////////////////////////////
  Future<void> sendBulk() async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/create-bulk-notifications/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "title": titleController.text,
          "message": messageController.text,
          "role": selectedRole, // owner / manager / tenant
        }),
      );

      if (res.statusCode == 200) {
        Navigator.pop(context);
        clear();
        fetchNotifications();
        msg("Bulk notification sent", Colors.green);
      }
    } catch (e) {
      msg(e.toString(), Colors.red);
    }
  }

  ////////////////////////////////////////////////////////////
  /// MARK AS READ
  ////////////////////////////////////////////////////////////
  Future<void> markRead(String id) async {
    await http.post(
      Uri.parse("$baseUrl/api/mark-as-read/$id/"),
    );
    fetchNotifications();
  }

  ////////////////////////////////////////////////////////////
  /// DELETE
  ////////////////////////////////////////////////////////////
  Future<void> deleteNotif(String id) async {
    await http.delete(
      Uri.parse("$baseUrl/api/delete-notification/$id/"),
    );
    fetchNotifications();
  }

  ////////////////////////////////////////////////////////////
  /// CLEAR
  ////////////////////////////////////////////////////////////
  void clear() {
    titleController.clear();
    messageController.clear();
    selectedRole = null;
  }

  ////////////////////////////////////////////////////////////
  /// MESSAGE
  ////////////////////////////////////////////////////////////
  void msg(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Text(text),
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// OPEN FORM
  ////////////////////////////////////////////////////////////
  void openForm({bool bulk = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
            bulk ? "Send Bulk Notification" : "Send Notification"),
        content: SingleChildScrollView(
          child: Column(
            children: [

              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                    labelText: "Title"),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                    labelText: "Message"),
              ),

              const SizedBox(height: 10),

              if (bulk)
                DropdownButtonFormField(
                  value: selectedRole,
                  items: const [
                    DropdownMenuItem(
                        value: "owner", child: Text("Owner")),
                    DropdownMenuItem(
                        value: "manager", child: Text("Manager")),
                    DropdownMenuItem(
                        value: "tenant", child: Text("Tenant")),
                  ],
                  onChanged: (v) {
                    selectedRole = v.toString();
                  },
                  decoration: const InputDecoration(
                    labelText: "Role Target",
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: bulk ? sendBulk : sendNotification,
            child: Text(bulk ? "Send Bulk" : "Send"),
          )
        ],
      ),
    );
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
      currentIndex: 16,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [

                  //////////////////////////////////////////////////
                  /// HEADER
                  //////////////////////////////////////////////////
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF59E0B),
                          Color(0xFF92400E),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Notifications",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "System alerts & updates",
                              style: TextStyle(
                                  color: Colors.white70),
                            ),
                          ],
                        ),

                        Row(
                          children: [

                            if (widget.role == "owner")
                              ElevatedButton.icon(
                                onPressed: () => openForm(bulk: true),
                                icon: const Icon(Icons.campaign),
                                label: const Text("Broadcast"),
                              ),

                            const SizedBox(width: 10),

                            ElevatedButton.icon(
                              onPressed: () => openForm(),
                              icon: const Icon(Icons.send),
                              label: const Text("Send"),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  //////////////////////////////////////////////////
                  /// LIST
                  //////////////////////////////////////////////////
                  ListView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount: notifications.length,
                    itemBuilder: (context, i) {
                      final n = notifications[i];

                      return Card(
                        child: ListTile(
                          leading: Icon(
                            n["is_read"]
                                ? Icons.notifications_none
                                : Icons.notifications_active,
                            color: n["is_read"]
                                ? Colors.grey
                                : Colors.orange,
                          ),
                          title: Text(n["title"]),
                          subtitle: Text(n["message"]),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [

                              if (!n["is_read"])
                                IconButton(
                                  icon: const Icon(Icons.mark_email_read,
                                      color: Colors.green),
                                  onPressed: () =>
                                      markRead(n["id"]),
                                ),

                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () =>
                                    deleteNotif(n["id"]),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
    );
  }
}