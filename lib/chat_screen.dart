import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'message.dart';
import 'package:firebase_core/firebase_core.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverEmail;

  ChatScreen({
    required this.receiverId,
    required this.receiverName,
    required this.receiverEmail,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late String chatRoomId;

  @override
  void initState() {
    super.initState();
    // Create a unique chat room ID by combining sender and receiver IDs
    List<String> ids = [_auth.currentUser!.uid, widget.receiverId];
    ids.sort(); // Sort to ensure same chat room ID regardless of who initiates
    chatRoomId = ids.join('_');
  }

  void sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final user = _auth.currentUser!;
    final message = Message(
      senderId: user.uid,
      senderName: user.displayName ?? 'Unknown',
      senderEmail: user.email ?? '',
      receiverId: widget.receiverId,
      receiverName: widget.receiverName,
      receiverEmail: widget.receiverEmail,
      content: _messageController.text.trim(),
      timestamp: DateTime.now(),
    );

    // Store message in the chat room
    await _database
        .child('chats')
        .child(chatRoomId)
        .child('messages')
        .push()
        .set(message.toMap());

    // Update chat list for both users
    final chatListData = {
      'lastMessage': message.content,
      'timestamp': message.timestamp.millisecondsSinceEpoch,
      'participants': {
        user.uid: {
          'name': user.displayName,
          'email': user.email,
        },
        widget.receiverId: {
          'name': widget.receiverName,
          'email': widget.receiverEmail,
        },
      },
    };

    await _database
        .child('chatList')
        .child(user.uid)
        .child(chatRoomId)
        .update(chatListData);

    await _database
        .child('chatList')
        .child(widget.receiverId)
        .child(chatRoomId)
        .update(chatListData);

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _database
                  .child('chats')
                  .child(chatRoomId)
                  .child('messages')
                  .onValue,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData ||
                    snapshot.data?.snapshot.value == null) {
                  return Center(child: Text('No messages yet'));
                }

                final messagesData = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map);
                final messages = messagesData.values
                    .map((msg) =>
                        Message.fromMap(Map<String, dynamic>.from(msg)))
                    .toList()
                  ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _auth.currentUser!.uid;

                    return MessageBubble(
                      message: message.content,
                      isMe: isMe,
                      senderName: message.senderName,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String senderName;

  MessageBubble({
    required this.message,
    required this.isMe,
    required this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            senderName,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
