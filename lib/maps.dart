import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:women_safety/mapscreen.dart';
import 'package:women_safety/LawyerRecommend.dart';
import 'package:women_safety/Report.dart';
import 'package:women_safety/Storiespage1.dart';
import 'package:women_safety/register_user.dart';
import 'package:women_safety/userprofile.dart';
import 'package:women_safety/chatbot.dart';
import 'package:women_safety/matchem.dart';

class WomenSafetyApp extends StatelessWidget {
  const WomenSafetyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SafeShe', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.black,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.red,
                ),
                child: Text(
                  'Navigation Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.book, color: Colors.white),
                title: Text('Stories', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => StoriesApp()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.book, color: Colors.white),
                title: Text('Register User',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PanVerificationPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.gavel, color: Colors.white),
                title: Text('MatchSafe', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => RegistrationScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.report, color: Colors.white),
                title: Text('Report', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ReportPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.map, color: Colors.white),
                title: Text('Maps', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(
                      context); // Close the drawer, already on Maps page
                },
              ),
              ListTile(
                leading: Icon(Icons.chat, color: Colors.white),
                title: Text('Chatbot', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WebPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.verified_user_rounded, color: Colors.white),
                title:
                    Text('UserProfile', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UserProfilePage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.black,
      body: Container(
        height: MediaQuery.of(context).size.height,
        margin: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 54, 108, 179), // Blue color
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red,
              blurRadius: 8.0,
              spreadRadius: 2.0,
            ),
          ],
        ),
        child: MapScreen(), // Only the MapScreen remains
      ),
    );
  }
}
