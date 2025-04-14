import 'package:flutter/material.dart';

void main() {
  runApp(LawyerRecommendationApp());
}

class LawyerRecommendationApp extends StatelessWidget {
  const LawyerRecommendationApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LawyerRecommendationPage(),
    );
  }
}

class LawyerRecommendationPage extends StatefulWidget {
  @override
  _LawyerRecommendationPageState createState() =>
      _LawyerRecommendationPageState();
}

class _LawyerRecommendationPageState extends State<LawyerRecommendationPage> {
  int? _selectedIndex;

  final List<Map<String, String>> lawyers = [
    {
      'name': 'John Doe',
      'specialty': 'Criminal Lawyer',
      'experience': '10 years',
      'whatsapp': '+1 123 456 7890',
      'email': 'john.doe@example.com',
      'address': '123 Main St, City, Country'
    },
    {
      'name': 'Jane Smith',
      'specialty': 'Family Lawyer',
      'experience': '8 years',
      'whatsapp': '+1 987 654 3210',
      'email': 'jane.smith@example.com',
      'address': '456 Oak Ave, City, Country'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Find Lawyer',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: lawyers.length,
                itemBuilder: (context, index) {
                  final lawyer = lawyers[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                      Future.delayed(Duration(milliseconds: 200), () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FindLawyerInfoPage(
                              lawyer: lawyer,
                            ),
                          ),
                        );
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: _selectedIndex == index
                            ? LinearGradient(
                                colors: [Colors.red, Colors.yellow],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: _selectedIndex == index ? null : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blueGrey,
                            child: Text(
                              lawyer['name']![0],
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                            radius: 30,
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lawyer['name']!,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedIndex == index
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  lawyer['specialty']!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _selectedIndex == index
                                        ? Colors.white70
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: _selectedIndex == index
                                ? Colors.white
                                : Colors.blueGrey,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FindLawyerInfoPage extends StatefulWidget {
  final Map<String, String> lawyer;

  FindLawyerInfoPage({required this.lawyer});

  @override
  _FindLawyerInfoPageState createState() => _FindLawyerInfoPageState();
}

class _FindLawyerInfoPageState extends State<FindLawyerInfoPage> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  List<TimeOfDay> _availableTimeSlots = [
    TimeOfDay(hour: 9, minute: 0),
    TimeOfDay(hour: 10, minute: 0),
    TimeOfDay(hour: 11, minute: 0),
    TimeOfDay(hour: 14, minute: 0),
    TimeOfDay(hour: 15, minute: 0),
    TimeOfDay(hour: 16, minute: 0),
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF00C08D), // Teal Green (calm and balanced)
              onPrimary: Colors.white, // Text color for header (white)
              surface: Color(0xFF000000), // Calendar background (black)
              onSurface: Color(0xFFFFFFFF), // Date text color (white)
            ),
            dialogBackgroundColor: Colors.black, // Dialog background (black)
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Background color (black)
      appBar: AppBar(
        title: Text('Lawyer Info'),
        backgroundColor: Colors.black,
        foregroundColor: Color(0xFFFFD700), // Golden Yellow for app bar text
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Color(0xFFFFD700), // Golden Yellow container background
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        Color(0xFF00C08D), // Teal Green avatar background
                    radius: 40,
                    child: Text(
                      widget.lawyer['name']![0],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.lawyer['name']!,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          widget.lawyer['specialty']!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(
                                0xFF3CB371), // Sea Green for specialty text
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Experience: ${widget.lawyer['experience']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(
                                0xFF00C08D), // Teal Green for experience text
                          ),
                        ),
                        SizedBox(height: 10),
                        Text('WhatsApp: ${widget.lawyer['whatsapp']}',
                            style:
                                TextStyle(fontSize: 14, color: Colors.black)),
                        Text('Email: ${widget.lawyer['email']}',
                            style:
                                TextStyle(fontSize: 14, color: Colors.black)),
                        Text('Address: ${widget.lawyer['address']}',
                            style:
                                TextStyle(fontSize: 14, color: Colors.black)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color:
                    Color(0xFFFFD700), // Golden Yellow for the second container
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Date & Time',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Text("Date: ",
                          style: TextStyle(fontSize: 16, color: Colors.black)),
                      SizedBox(width: 10),
                      TextButton(
                        onPressed: () => _selectDate(context),
                        child: Text(
                          "${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}",
                          style: TextStyle(
                              color: Colors.black), // Black for button text
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text("Time: ",
                      style: TextStyle(fontSize: 16, color: Colors.black)),
                  Wrap(
                    spacing: 8.0, // gap between adjacent buttons
                    runSpacing: 4.0, // gap between lines
                    children: _availableTimeSlots.map((slot) {
                      bool isSelected = _selectedTime == slot;
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected
                              ? Color(
                                  0xFF00C08D) // Teal Green for selected time
                              : Colors.black, // Black for unselected time
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedTime = slot;
                          });
                        },
                        child: Text(
                          slot.format(context),
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
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
