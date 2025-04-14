import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(MaterialApp(
    home: PanVerificationPage(),
    debugShowCheckedModeBanner: false,
  ));
}

class PanVerificationPage extends StatefulWidget {
  @override
  _PanVerificationPageState createState() => _PanVerificationPageState();
}

class _PanVerificationPageState extends State<PanVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController panController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  // Hardcoded constants for task ID and group ID
  static const String taskId = "your_task_id";
  static const String groupId = "your_group_id";

  DateTime selectedDate = DateTime(2000, 1, 1);
  String verificationStatus = '';
  bool isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1950, 1),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E4E8C), // Deep blue
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E4E8C),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
      });
  }

  Future<void> verifyPan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      verificationStatus = 'Verifying...';
    });

    String formattedDate =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    // For physical device, use your computer's IP address
    var url = Uri.parse(
        "http://192.168.1.10:5000/verify-pan"); // Replace x.x with your computer's IP

    Map<String, dynamic> data = {
      'task_id': taskId,
      'group_id': groupId,
      'pan_number': panController.text,
      'full_name': nameController.text,
      'dob': formattedDate
    };

    try {
      var response = await http.post(url,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
          body: json.encode(data));
      if (response.statusCode == 200) {
        var result = json.decode(response.body);
        setState(() {
          if (result['status'] == 'success' ||
              (result['details'] != null &&
                  result['details']
                      .toString()
                      .contains("Existing and Valid"))) {
            verificationStatus =
                "✓ PAN Verified Successfully\nYour PAN is valid and active";

            // Update user verification status in Firestore
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                'isVerified': true,
              }, SetOptions(merge: true));
            }
          } else {
            verificationStatus =
                "${result['message']}\n${result['details'] ?? ''}";
          }
        });
      } else {
        setState(() {
          verificationStatus = "Error: " + response.body;
        });
      }
    } catch (e) {
      setState(() {
        verificationStatus = "Exception: " + e.toString();
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    panController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E4E8C),
        title: Text(
          "PAN Verification",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top curved container with icon
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E4E8C),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_user_outlined,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Verify Your Identity",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),

            // Form content
            Container(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Please enter your details",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 24),

                    // PAN Card field
                    _buildTextField(
                      controller: panController,
                      label: "PAN Number",
                      hintText: "Enter 10-digit PAN",
                      icon: Icons.credit_card,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter PAN number';
                        }
                        if (value.length != 10) {
                          return 'PAN number must be 10 characters';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.characters,
                    ),
                    SizedBox(height: 20),

                    // Full Name field
                    _buildTextField(
                      controller: nameController,
                      label: "Full Name",
                      hintText: "Enter name as per PAN card",
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter full name';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                    ),
                    SizedBox(height: 20),

                    // Date of Birth field
                    Text(
                      "Date of Birth",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: const Color(0xFF1E4E8C),
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text(
                              DateFormat('dd MMM, yyyy').format(selectedDate),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                            Spacer(),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 30),

                    // Verify button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : verifyPan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E4E8C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                "Verify PAN",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    // Status message
                    if (verificationStatus.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(top: 24),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: verificationStatus.contains("Error") ||
                                  verificationStatus.contains("Exception")
                              ? Colors.red[50]
                              : Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: verificationStatus.contains("Error") ||
                                    verificationStatus.contains("Exception")
                                ? Colors.red[200]!
                                : Colors.green[200]!,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              verificationStatus.contains("Error") ||
                                      verificationStatus.contains("Exception")
                                  ? Icons.error_outline
                                  : Icons.check_circle_outline,
                              color: verificationStatus.contains("Error") ||
                                      verificationStatus.contains("Exception")
                                  ? Colors.red[700]
                                  : Colors.green[700],
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                verificationStatus,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: verificationStatus.contains("Error") ||
                                          verificationStatus
                                              .contains("Exception")
                                      ? Colors.red[700]
                                      : Colors.green[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    required String? Function(String?) validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          textCapitalization: textCapitalization,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: const Color(0xFF1E4E8C)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: const Color(0xFF1E4E8C), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[400]!, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
