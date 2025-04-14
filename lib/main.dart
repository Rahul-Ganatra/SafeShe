import 'package:flutter/material.dart';
import 'package:women_safety/Login.dart';
import 'package:women_safety/Storiespage1.dart';
import 'package:women_safety/LawyerRecommend.dart';
import 'package:women_safety/Report.dart';
import 'package:women_safety/SignUp.dart'; // Import the SignUp page
import 'package:women_safety/chatbot.dart';
import 'package:women_safety/mapscreen.dart';
import 'maps.dart'; // Import the maps.dart file
import 'package:firebase_core/firebase_core.dart';
import 'matchem.dart';
import 'package:women_safety/register_user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyA0f8QeJovJsiOtQnIHUY6dciYWzBHn2iY",
      appId: "1:409806951976:web:06f13fb4d98036a075071d",
      messagingSenderId: "409806951976",
      projectId: "mubh-16ab0",
      databaseURL: "https://mubh-16ab0-default-rtdb.firebaseio.com",
    ),
  );

  runApp(const MyApp()); // No need to pass initialization here
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SheSafe',
      theme: ThemeData(
        primaryColor: Color(0xFFFF6B81), // Soft pink
        scaffoldBackgroundColor:
            Color(0xFFFFF5F6), // Very light pink background
        colorScheme: ColorScheme.light(
          primary: Color(0xFFFF6B81),
          secondary: Color(0xFF7E57C2), // Purple accent
          surface: Colors.white,
          background: Color(0xFFFFF5F6),
        ),
        textTheme: TextTheme(
          displayLarge: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(color: Color(0xFF2C3E50)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFF6B81),
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/signup': (context) => SignUpPage(),
        '/login': (context) => LoginPage(),
        '/stories': (context) => StoriesPage(),
        '/lawyerrecommend': (context) => LawyerRecommendationApp(),
        '/report': (context) => ReportPage(),
        '/maps': (context) => WomenSafetyApp(),
        '/maps1': (context) => MapScreen(),
        '/chatbot': (context) => WebPage(),
        '/register': (context) => PanVerificationPage(),
      },
    );
  }
}
