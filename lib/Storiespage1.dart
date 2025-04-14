import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(StoriesApp());
}

class StoriesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StoriesPage(),
    );
  }
}

class StoriesPage extends StatefulWidget {
  const StoriesPage({Key? key}) : super(key: key);

  @override
  _StoriesPageState createState() => _StoriesPageState();
}

class _StoriesPageState extends State<StoriesPage> {
  List<Story> stories = [];
  String currentUserId = '';
  String currentUserName = ''; // Variable to hold the user's name

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    _fetchStories();
  }

  Future<void> _fetchCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser; // Get the current user
    if (user != null) {
      setState(() {
        currentUserId = user.uid; // Set the current user's ID
      });
      // Fetch the user's name
      currentUserName = await _fetchUserName(currentUserId);
    } else {
      print("No user is currently logged in.");
    }
  }

  Future<void> _fetchStories() async {
    try {
      print("Fetching stories...");
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('reports').get();
      print("Fetched ${snapshot.docs.length} stories.");

      List<Story> fetchedStories = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        if (data != null) {
          String storyContent = data['story'] ?? '';
          String userName = data['userName'] ?? '';
          bool isAnonymous = userName.isEmpty;

          List<Comment> comments = await _fetchComments(doc.id);

          fetchedStories.add(Story(
            id: doc.id,
            content: storyContent,
            isAnonymous: isAnonymous,
            reporterName: isAnonymous ? 'Anonymous' : userName,
            comments: comments,
          ));
        } else {
          print("Document data is null for ID: ${doc.id}");
        }
      }

      setState(() {
        stories = fetchedStories;
      });
    } catch (e) {
      print("Error fetching stories: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch stories: $e')),
      );
    }
  }

  Future<List<Comment>> _fetchComments(String storyId) async {
    List<Comment> comments = [];
    try {
      final QuerySnapshot commentSnapshot = await FirebaseFirestore.instance
          .collection('reports')
          .doc(storyId)
          .collection('comments')
          .get();

      for (var doc in commentSnapshot.docs) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        String userId = data?['userId'] ?? ''; // userId field in comments

        // Fetch user's real name from "users" collection if not anonymous
        String commenterName = 'Anonymous';
        if (userId.isNotEmpty) {
          commenterName =
              await _fetchUserName(userId); // Fetch the name based on userId
        }

        comments.add(Comment(
          text: data?['text'] ?? '',
          isAnonymous: data?['isAnonymous'] ?? true,
          commenterName: commenterName,
        ));
      }
    } catch (e) {
      print("Error fetching comments for story $storyId: $e");
    }
    return comments;
  }

  Future<String> _fetchUserName(String userId) async {
    try {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;

        return userData?['firstName'] ??
            'Anonymous'; // Return the user's firstName or 'Anonymous' if not found
      }
    } catch (e) {
      print("Error fetching user name for user $userId: $e");
    }
    return 'Anonymous'; // Default to 'Anonymous' if an error occurs
  }

  void _addComment(String storyId, Comment comment) async {
    try {
      // Use the legitimate user ID from authentication
      String userId = comment.isAnonymous ? '' : currentUserId;
      String commenterName = 'Anonymous';

      // Only fetch the name if the comment is not anonymous
      if (!comment.isAnonymous && userId.isNotEmpty) {
        commenterName = currentUserName; // Use the current user's name directly
      }

      // Add comment data, including userId and commenterName if not anonymous
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(storyId)
          .collection('comments')
          .add({
        'text': comment.text,
        'isAnonymous': comment.isAnonymous,
        'userId': userId,
        'commenterName': commenterName,
      });

      // Update the local state with the new comment
      setState(() {
        stories.firstWhere((story) => story.id == storyId).comments.add(
              Comment(
                text: comment.text,
                isAnonymous: comment.isAnonymous,
                commenterName: commenterName,
              ),
            );
      });
    } catch (e) {
      print("Error adding comment to story $storyId: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Stories of Bravery',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushNamed(context,
                '/womenSafety'); // Assuming you have a route named '/womenSafety'
          },
        ),
      ),
      backgroundColor: Colors.black, // Moved this inside the Scaffold
      body: stories.isEmpty
          ? Center(
              child:
                  CircularProgressIndicator()) // Show a loading spinner if the list is empty
          : ListView.builder(
              itemCount: stories.length,
              itemBuilder: (context, index) {
                return StoryCard(
                  story: stories[index],
                  addComment: _addComment,
                  currentUserId: currentUserId, // Pass user ID to StoryCard
                );
              },
            ),
    );
  }
}

class StoryCard extends StatefulWidget {
  final Story story;
  final Function(String, Comment) addComment;
  final String currentUserId;

  StoryCard(
      {required this.story,
      required this.addComment,
      required this.currentUserId});

  @override
  _StoryCardState createState() => _StoryCardState();
}

class _StoryCardState extends State<StoryCard> {
  TextEditingController commentController = TextEditingController();
  bool isAnonymous = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.story.isAnonymous
                  ? 'Anonymous Reporter'
                  : widget.story.reporterName,
              style: TextStyle(
                  color: Colors.lightBlueAccent, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              widget.story.content,
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 20),
            Text(
              'Comments of Support:',
              style: TextStyle(
                  color: Colors.lightBlueAccent, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: widget.story.comments.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${widget.story.comments[index].isAnonymous ? "Anonymous" : widget.story.comments[index].commenterName}: ${widget.story.comments[index].text}',
                    style: TextStyle(color: Colors.lightGreenAccent),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Leave an encouraging message...',
                      hintStyle: TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    final newComment = Comment(
                      text: commentController.text,
                      isAnonymous: isAnonymous,
                      commenterName: isAnonymous ? 'Anonymous' : '',
                    );

                    widget.addComment(widget.story.id, newComment);
                    commentController.clear();
                  },
                  child: Text('Submit'),
                ),
              ],
            ),
            Row(
              children: [
                Checkbox(
                  value: isAnonymous,
                  onChanged: (bool? value) {
                    setState(() {
                      isAnonymous = value ?? true;
                    });
                  },
                ),
                Text(
                  'Post anonymously',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Story {
  final String id;
  final String content;
  final String reporterName;
  final bool isAnonymous;
  final List<Comment> comments;

  Story({
    required this.id,
    required this.content,
    required this.reporterName,
    required this.isAnonymous,
    required this.comments,
  });
}

class Comment {
  final String text;
  final bool isAnonymous;
  final String commenterName;

  Comment({
    required this.text,
    required this.isAnonymous,
    required this.commenterName,
  });
}
