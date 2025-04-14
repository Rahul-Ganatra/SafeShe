import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_core/firebase_core.dart';
import 'package:women_safety/matchem.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:women_safety/chat_list_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:women_safety/chat_screen.dart';

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
  final String? email;

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
    this.email,
  });

  factory User.fromFirestore(firestore.DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      name: data['name'] ?? '',
      gender: data['gender'] ?? '',
      age: data['age'] ?? 0,
      destination: data['destination'],
      currentLocation: data['currentLocation'],
      travelTime: data['travelTime'] != null
          ? (data['travelTime'] as firestore.Timestamp).toDate()
          : null,
      preferredGender: data['preferredGender'] != null
          ? List<String>.from(data['preferredGender'])
          : null,
      minPreferredAge: data['minPreferredAge'],
      maxPreferredAge: data['maxPreferredAge'],
      isVerified: data['isVerified'] ?? false,
      email: data['email'],
    );
  }
}

class MatchScreen extends StatefulWidget {
  @override
  _MatchScreenState createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  List<User> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTravelProfiles();
  }

  Future<void> _fetchTravelProfiles() async {
    setState(() {
      isLoading = true;
    });

    try {
      final firestore.QuerySnapshot travelSnapshot = await firestore
          .FirebaseFirestore.instance
          .collection('travelProfiles')
          .get();

      List<User> verifiedUsers = [];

      // Fetch verification status for each user
      for (var doc in travelSnapshot.docs) {
        try {
          // Use the document ID as the user ID
          final userDoc = await firestore.FirebaseFirestore.instance
              .collection('users')
              .doc(doc
                  .id) // Using document ID instead of trying to get userId field
              .get();

          final travelData = doc.data() as Map<String, dynamic>;
          final userData = userDoc.data() as Map<String, dynamic>?;

          verifiedUsers.add(User(
            id: doc.id,
            name: travelData['name'] ?? '',
            gender: travelData['gender'] ?? '',
            age: travelData['age'] ?? 0,
            destination: travelData['destination'],
            currentLocation: travelData['currentLocation'],
            travelTime: travelData['travelTime'] != null
                ? (travelData['travelTime'] as firestore.Timestamp).toDate()
                : null,
            preferredGender: travelData['preferredGender'] != null
                ? List<String>.from(travelData['preferredGender'])
                : null,
            minPreferredAge: travelData['minPreferredAge'],
            maxPreferredAge: travelData['maxPreferredAge'],
            isVerified: userData?['isVerified'] ?? false,
            email: userData?['email'],
          ));
        } catch (userError) {
          // If we can't fetch the user document, still add the travel profile
          // but mark as unverified
          final travelData = doc.data() as Map<String, dynamic>;
          verifiedUsers.add(User(
            id: doc.id,
            name: travelData['name'] ?? '',
            gender: travelData['gender'] ?? '',
            age: travelData['age'] ?? 0,
            destination: travelData['destination'],
            currentLocation: travelData['currentLocation'],
            travelTime: travelData['travelTime'] != null
                ? (travelData['travelTime'] as firestore.Timestamp).toDate()
                : null,
            preferredGender: travelData['preferredGender'] != null
                ? List<String>.from(travelData['preferredGender'])
                : null,
            minPreferredAge: travelData['minPreferredAge'],
            maxPreferredAge: travelData['maxPreferredAge'],
            isVerified:
                false, // Default to unverified if user document not found
            email: null,
          ));
        }
      }

      setState(() {
        users = verifiedUsers;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching travel profiles: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Travel Matches'),
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
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF507DBC)),
                ),
              )
            : RefreshIndicator(
                onRefresh: _fetchTravelProfiles,
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.white.withOpacity(0.9),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          user.name,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2A2D34),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      if (user.isVerified)
                                        Tooltip(
                                          message: 'Verified User',
                                          child: Icon(
                                            Icons.verified,
                                            color: Colors.blue,
                                            size: 20,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF56C2A6).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${user.age} yrs',
                                    style: TextStyle(
                                      color: Color(0xFF56C2A6),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.chat_bubble_outline),
                                  color: Color(0xFF507DBC),
                                  onPressed: () => _openChat(user),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            _buildInfoRow(
                                Icons.person, 'Gender: ${user.gender}'),
                            _buildInfoRow(
                              Icons.location_on,
                              'From: ${user.currentLocation ?? 'Not specified'}',
                            ),
                            _buildInfoRow(
                              Icons.location_city,
                              'To: ${user.destination ?? 'Not specified'}',
                            ),
                            if (user.travelTime != null)
                              _buildInfoRow(
                                Icons.access_time,
                                'Time: ${_formatTime(user.travelTime!)}',
                              ),
                            _buildInfoRow(
                              Icons.verified_user,
                              'Status: ${user.isVerified ? 'Verified User' : 'Not Verified'}',
                              iconColor:
                                  user.isVerified ? Colors.blue : Colors.grey,
                            ),
                            if (user.isVerified)
                              _buildInfoRow(
                                Icons.verified_user,
                                'Verified User',
                                iconColor: Colors.blue,
                              ),
                            Divider(height: 16),
                            Text(
                              'Preferences:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2A2D34),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Gender: ${user.preferredGender?.join(", ") ?? 'Not specified'}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            Text(
                              'Age: ${user.minPreferredAge != null && user.maxPreferredAge != null ? "${user.minPreferredAge}-${user.maxPreferredAge} years" : "Not specified"}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchTravelProfiles,
        child: Icon(Icons.refresh),
        backgroundColor: Color(0xFFFF6B6B),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text,
      {Color? iconColor, Color? textColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor ?? Color(0xFF507DBC)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor ?? Colors.grey[700],
                fontWeight:
                    textColor != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _openChat(User otherUser) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please login to chat')),
        );
        return;
      }

      // Get current user's Firestore data
      final currentUserDoc = await firestore.FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final currentUserData = currentUserDoc.data() ?? {};

      // Create chat room ID
      final chatId = [currentUser.uid, otherUser.id]..sort();
      final chatRoomId = chatId.join('_');

      // Create chat room data
      final chatRoomData = {
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'lastMessage': '',
        'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
        'participants': {
          currentUser.uid: {
            'name':
                currentUserData['name'] ?? currentUser.displayName ?? 'Unknown',
            'email': currentUser.email ?? '',
            'uid': currentUser.uid,
          },
          otherUser.id: {
            'name': otherUser.name,
            'email': otherUser.email ?? '',
            'uid': otherUser.id,
          },
        }
      };

      // Save chat room data
      await FirebaseDatabase.instance
          .ref()
          .child('chatRooms')
          .child(chatRoomId)
          .set(chatRoomData);

      // Create user chat data
      final userChatData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'chatRoomId': chatRoomId,
        'unreadCount': 0,
        'lastMessage': '',
        'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
      };

      // Save to current user's chats
      await FirebaseDatabase.instance
          .ref()
          .child('userChats')
          .child(currentUser.uid)
          .child(chatRoomId)
          .set(userChatData);

      // Save to other user's chats
      await FirebaseDatabase.instance
          .ref()
          .child('userChats')
          .child(otherUser.id)
          .child(chatRoomId)
          .set(userChatData);

      print('Chat room created: $chatRoomId'); // Debug print

      // Navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            receiverId: otherUser.id,
            receiverName: otherUser.name,
            receiverEmail: otherUser.email ?? '',
          ),
        ),
      );
    } catch (e) {
      print('Error creating chat room: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating chat room. Please try again.')),
      );
    }
  }
}

class StatusPage extends StatefulWidget {
  final User currentUser;
  final List<User> allUsers;

  StatusPage({required this.currentUser, required this.allUsers});

  @override
  _StatusPageState createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  bool adritaStatusReached = false;
  bool adritaStatusMeeting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.currentUser.name}'s Status",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF507DBC),
        elevation: 5,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                itemCount: widget.allUsers.length,
                itemBuilder: (context, index) {
                  final user = widget.allUsers[index];
                  bool isAdrita = user.id == widget.currentUser.id;

                  return Card(
                    color: Color(0xFF2A2D34),
                    margin:
                        EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    shadowColor: Colors.black.withOpacity(0.3),
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  user.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Reached Destination: ${isAdrita ? adritaStatusReached : false}",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  "Meeting Others: ${isAdrita ? adritaStatusMeeting : false}",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          if (isAdrita)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  activeColor: Color(0xFF56C2A6),
                                  value: adritaStatusReached,
                                  onChanged: (value) {
                                    setState(() {
                                      adritaStatusReached = value ?? false;
                                    });
                                  },
                                ),
                                Checkbox(
                                  activeColor: Color(0xFF56C2A6),
                                  value: adritaStatusMeeting,
                                  onChanged: (value) {
                                    setState(() {
                                      adritaStatusMeeting = value ?? false;
                                    });
                                  },
                                ),
                              ],
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
