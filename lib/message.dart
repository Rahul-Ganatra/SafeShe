class Message {
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String receiverId;
  final String receiverName;
  final String receiverEmail;
  final String content;
  final DateTime timestamp;

  Message({
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.receiverId,
    required this.receiverName,
    required this.receiverEmail,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverEmail': receiverEmail,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderId: map['senderId'],
      senderName: map['senderName'],
      senderEmail: map['senderEmail'],
      receiverId: map['receiverId'],
      receiverName: map['receiverName'],
      receiverEmail: map['receiverEmail'],
      content: map['content'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}
