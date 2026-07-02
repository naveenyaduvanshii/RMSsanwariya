import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../layout/main_layout.dart';

class DocumentsPage extends StatefulWidget {
  final String role;
  final String userName;
  final String renterId;

  const DocumentsPage({
    super.key,
    required this.role,
    required this.userName,
    required this.renterId,
  });

  @override
  State<DocumentsPage> createState() =>
      _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final String baseUrl = "http://127.0.0.1:8000";

  List documents = [];
  bool isLoading = true;

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController urlController =
      TextEditingController();

  final TextEditingController typeController =
      TextEditingController();

  String? selectedTenantId;
  String? selectedAssignmentId;

  bool isEdit = false;
  String editId = "";

  @override
  void initState() {
    super.initState();
    fetchDocuments();
  }

  ////////////////////////////////////////////////////////////
  /// FETCH DOCUMENTS
  ////////////////////////////////////////////////////////////
  Future<void> fetchDocuments() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/documents/"),
      );

      if (res.statusCode == 200) {
        setState(() {
          documents = jsonDecode(res.body)["data"];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
      setState(() => isLoading = false);
    }
  }

  ////////////////////////////////////////////////////////////
  /// CREATE DOCUMENT
  ////////////////////////////////////////////////////////////
  Future<void> saveDocument() async {
    try {
      final body = {
        "tenant_id": selectedTenantId,
        "assignment_id": selectedAssignmentId,
        "document_type": typeController.text,
        "document_name": nameController.text,
        "document_url": urlController.text,
      };

      final url = isEdit
          ? "$baseUrl/api/update-document/$editId/"
          : "$baseUrl/api/create-document/";

      final res = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        Navigator.pop(context);
        clear();
        fetchDocuments();
        msg("Saved Successfully", Colors.green);
      }
    } catch (e) {
      msg(e.toString(), Colors.red);
    }
  }

  ////////////////////////////////////////////////////////////
  /// DELETE
  ////////////////////////////////////////////////////////////
  Future<void> deleteDoc(String id) async {
    await http.delete(
      Uri.parse("$baseUrl/api/delete-document/$id/"),
    );
    fetchDocuments();
  }

  ////////////////////////////////////////////////////////////
  /// CLEAR
  ////////////////////////////////////////////////////////////
  void clear() {
    nameController.clear();
    urlController.clear();
    typeController.clear();
    selectedTenantId = null;
    selectedAssignmentId = null;
    isEdit = false;
    editId = "";
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
  void openForm({Map? doc}) {
    if (doc != null) {
      isEdit = true;
      editId = doc["id"];
      nameController.text = doc["document_name"] ?? "";
      urlController.text = doc["document_url"] ?? "";
      typeController.text = doc["document_type"] ?? "";
    } else {
      clear();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? "Edit Document" : "Add Document"),
        content: SingleChildScrollView(
          child: Column(
            children: [

              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: "Document Name"),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: typeController,
                decoration: const InputDecoration(
                    labelText: "Document Type"),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                    labelText: "Document URL"),
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
            onPressed: saveDocument,
            child: const Text("Save"),
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
      currentIndex: 14,
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
                          Color(0xFF6366F1),
                          Color(0xFF1E1B4B),
                        ],
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Documents",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              "Tenant & Rental documents management",
                              style: TextStyle(color: Colors.white70),
                            ),
                            if (isMobile) const SizedBox(height: 16),
                            SizedBox(
                              width: isMobile ? double.infinity : null,
                              child: ElevatedButton.icon(
                                onPressed: () => openForm(),
                                icon: const Icon(Icons.upload_file),
                                label: const Text("Add Document"),
                              ),
                            )
                          ],
                        );
                      }
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
                    itemCount: documents.length,
                    itemBuilder: (context, i) {
                      final d = documents[i];

                      return Card(
                        margin:
                            const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.file_copy),
                          title: Text(d["document_name"]),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text("Type: ${d["document_type"]}"),
                              Text("Tenant: ${d["tenant_name"]}"),
                              Text("Uploaded: ${d["uploaded_at"]}"),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [

                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blue),
                                onPressed: () =>
                                    openForm(doc: d),
                              ),

                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () =>
                                    deleteDoc(d["id"]),
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