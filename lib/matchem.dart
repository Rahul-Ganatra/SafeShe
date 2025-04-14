import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:women_safety/matchy.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'chat_screen.dart';
import 'chat_list_screen.dart';

// User Model
class User {
  final String id;
  final String name;
  final String gender;
  final int age;
  final String? destination;
  final String? currentLocation;
  final DateTime? travelTime;
  final List<String>? preferredGender;
  final int? minPreferredAge;
  final int? maxPreferredAge;
  final bool isVerified;
  bool metGroup;
  bool reachedDestination;

  User({
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    this.destination,
    this.currentLocation,
    this.travelTime,
    this.preferredGender,
    this.minPreferredAge,
    this.maxPreferredAge,
    this.isVerified = false,
    this.reachedDestination = false,
    this.metGroup = false,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      name: data['name'] ?? '',
      gender: data['gender'] ?? '',
      age: data['age'] ?? 0,
      destination: data['destination'],
      currentLocation: data['currentLocation'],
      travelTime: data['travelTime'] != null
          ? (data['travelTime'] as Timestamp).toDate()
          : null,
      preferredGender: data['preferredGender'] != null
          ? List<String>.from(data['preferredGender'])
          : null,
      minPreferredAge: data['minPreferredAge'],
      maxPreferredAge: data['maxPreferredAge'],
      isVerified: data['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'gender': gender,
      'age': age,
      'currentLocation': currentLocation,
      'destination': destination,
      'travelTime': travelTime != null ? Timestamp.fromDate(travelTime!) : null,
      'preferredGender': preferredGender,
      'minPreferredAge': minPreferredAge,
      'maxPreferredAge': maxPreferredAge,
      'isVerified': isVerified,
    };
  }
}

// Registration Screen
class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _nameController = TextEditingController();
  final _genderController = TextEditingController();
  final _ageController = TextEditingController();
  final _destinationController = TextEditingController();
  final _preferredGenderController = TextEditingController();
  final _minPreferredAgeController = TextEditingController();
  final _maxPreferredAgeController = TextEditingController();
  final _currentLocationController = TextEditingController();
  bool _isLoadingLocation = false;

  TimeOfDay? _selectedTravelTime;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) {
          throw Exception('Location permissions are permanently denied');
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = "${place.street}, ${place.locality}, ${place.country}";
        setState(() {
          _currentLocationController.text = address;
        });
      }
    } catch (e) {
      print("Error getting location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting current location: $e')),
      );
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _selectTravelTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTravelTime) {
      setState(() {
        _selectedTravelTime = picked;
      });
    }
  }

  void _registerUser() async {
    if (_selectedTravelTime == null) {
      print("Please select a travel time.");
      return;
    }

    try {
      final now = DateTime.now();
      final travelDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTravelTime!.hour,
        _selectedTravelTime!.minute,
      );

      final minPreferredAge = int.tryParse(_minPreferredAgeController.text);
      final maxPreferredAge = int.tryParse(_maxPreferredAgeController.text);

      if (minPreferredAge == null || maxPreferredAge == null) {
        print("Please enter valid age range values.");
        return;
      }

      final newUser = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        gender: _genderController.text,
        age: int.parse(_ageController.text),
        currentLocation: _currentLocationController.text,
        destination: _destinationController.text,
        travelTime: travelDateTime,
        preferredGender: _preferredGenderController.text.split(','),
        minPreferredAge: minPreferredAge,
        maxPreferredAge: maxPreferredAge,
        isVerified: false,
      );

      await FirebaseFirestore.instance
          .collection('travelProfiles')
          .doc(newUser.id)
          .set(newUser.toFirestore());

      _clearForm();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MatchScreen(),
        ),
      );
    } catch (e) {
      print("Error during registration: $e");
    }
  }

  void _clearForm() {
    _nameController.clear();
    _genderController.clear();
    _ageController.clear();
    _destinationController.clear();
    _preferredGenderController.clear();
    _minPreferredAgeController.clear();
    _maxPreferredAgeController.clear();
    setState(() {
      _selectedTravelTime = null;
    });
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      {bool isNumeric = false}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.grey[800],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Register"),
        actions: [
          IconButton(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            onPressed: () => _openChat(context),
            tooltip: 'Chats',
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2A2D34), Color(0xFF507DBC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFA3D5FF), Color(0xFF56C2A6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(_nameController, "Name"),
                  SizedBox(height: 20),
                  _buildTextField(_genderController, "Gender"),
                  SizedBox(height: 20),
                  _buildTextField(_ageController, "Age", isNumeric: true),
                  SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      children: [
                        TextField(
                          controller: _currentLocationController,
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: "Current Location",
                            labelStyle: TextStyle(color: Colors.white),
                            filled: true,
                            fillColor: Colors.transparent,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: _isLoadingLocation
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : IconButton(
                                    icon: Icon(Icons.refresh,
                                        color: Colors.white),
                                    onPressed: _getCurrentLocation,
                                  ),
                          ),
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildTextField(_destinationController, "Destination"),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedTravelTime == null
                              ? 'Select Travel Time'
                              : 'Travel Time: ${_selectedTravelTime!.format(context)}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _selectTravelTime(context),
                        child: Text("Choose Time"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF6B6B), // Coral button
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildTextField(_preferredGenderController,
                      "Preferred Gender (comma-separated)"),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                            _minPreferredAgeController, "Min Preferred Age",
                            isNumeric: true),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: _buildTextField(
                            _maxPreferredAgeController, "Max Preferred Age",
                            isNumeric: true),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _registerUser,
                    child: Text("Register"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF6B6B), // Coral button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _openChat(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChatListScreen(),
    ),
  );
}
