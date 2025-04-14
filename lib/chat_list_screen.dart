import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'chat_screen.dart';
import 'message.dart';
import 'package:firebase_core/firebase_core.dart';

class ChatListScreen extends StatelessWidget {
  final currentUser = FirebaseAuth.instance.currentUser;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        body: Center(child: Text('Please login to view chats')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Chats'),
      ),
      body: StreamBuilder(
        // Listen to current user's chat list
        stream: _database.child('userChats').child(currentUser!.uid).onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasError) {
            print('Error fetching chats: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          print('Snapshot value: ${snapshot.data?.snapshot.value}');

          final value = snapshot.data?.snapshot.value;
          if (value == null) {
            return Center(child: Text('No chats yet'));
          }

          Map<String, dynamic> chats;
          if (value is Map) {
            chats = Map<String, dynamic>.from(value);
          } else {
            return Center(child: Text('Invalid chat data format'));
          }

          if (chats.isEmpty) {
            return Center(child: Text('No chats yet'));
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chatRoomId = chats.keys.elementAt(index);

              return StreamBuilder(
                stream: _database.child('chatRooms').child(chatRoomId).onValue,
                builder: (context, AsyncSnapshot<DatabaseEvent> roomSnapshot) {
                  if (!roomSnapshot.hasData ||
                      roomSnapshot.data?.snapshot.value == null) {
                    return SizedBox.shrink();
                  }

                  final roomData = Map<String, dynamic>.from(
                      roomSnapshot.data!.snapshot.value as Map);
                  final participants = Map<String, dynamic>.from(
                      roomData['participants'] as Map);

                  // Get the other participant's info
                  final otherParticipantId = participants.keys
                      .firstWhere((id) => id != currentUser!.uid);
                  final otherParticipant = participants[otherParticipantId];

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        otherParticipant['name'][0].toUpperCase(),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(otherParticipant['name']),
                    subtitle: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: [
                          TextSpan(
                            text: '${otherParticipant['email'] ?? ''}\n',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          TextSpan(
                            text: roomData['lastMessage'] ?? 'No messages yet',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            receiverId: otherParticipantId,
                            receiverName: otherParticipant['name'],
                            receiverEmail: otherParticipant['email'],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
