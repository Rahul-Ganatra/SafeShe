import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data'; // For handling Uint8List

class ReportPageApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true,
      home: ReportPage(),
    );
  }
}

class ReportPage extends StatefulWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  bool isAnonymous = false;
  TextEditingController storyController = TextEditingController();
  List<String> _imageUrls = []; // Use a list to store image URLs from Firebase
  User? user;

  @override
  void initState() {
    super.initState();
    // Get the current user from Firebase Auth
    user = FirebaseAuth.instance.currentUser;
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? selectedImages = await picker.pickMultiImage();

    if (selectedImages != null) {
      for (XFile image in selectedImages) {
        // Get the URL after uploading the image
        String url = await _uploadImage(image);
        setState(() {
          _imageUrls.add(url); // Add uploaded image URLs to the list
        });
      }
    }
  }

  Future<String> _uploadImage(XFile image) async {
    // Convert XFile to Uint8List for web compatibility
    Uint8List data = await image.readAsBytes();
    String fileName =
        DateTime.now().millisecondsSinceEpoch.toString() + '_' + image.name;
    Reference ref =
        FirebaseStorage.instance.ref().child('report_images/$fileName');

    try {
      // Upload the file to Firebase Storage
      await ref.putData(data); // Use putData for Uint8List
      String imageUrl = await ref.getDownloadURL();
      print("Uploaded image: $imageUrl");
      return imageUrl; // Return the image URL
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
      return ''; // Return empty string in case of failure
    }
  }

  Future<void> _submitStory() async {
    String story = storyController.text.trim();

    if (story.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please write your story')),
      );
      return;
    }

    // Prepare data to save
    Map<String, dynamic> data = {
      'story': story,
      'timestamp': FieldValue.serverTimestamp(),
      'images': _imageUrls, // Use image URLs from Firebase
    };

    if (!isAnonymous && user != null) {
      String userId = user!.uid;

      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        String userName = userDoc.exists && userDoc['firstName'] != null
            ? "${userDoc['firstName']} ${userDoc['lastName'] ?? ''}".trim()
            : 'Anonymous';

        data['userId'] = userId;
        data['userName'] = userName;
      } catch (e) {
        print("Error fetching user data: $e");
        data['userId'] = userId;
        data['userName'] = 'Anonymous';
      }
    }

    try {
      await FirebaseFirestore.instance.collection('reports').add(data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Story submitted successfully')),
      );
      storyController.clear();
      setState(() {
        _imageUrls.clear(); // Clear the list of image URLs
      });
    } catch (e) {
      print("Error saving story: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit story')),
      );
    }
  }

  Future<void> _saveDraft() async {
    String story = storyController.text.trim();

    if (story.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please write your story')),
      );
      return;
    }

    // Prepare draft data to save
    Map<String, dynamic> draftData = {
      'story': story,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'draft',
      'images': _imageUrls, // Use image URLs from Firebase
    };

    if (!isAnonymous && user != null) {
      String userId = user!.uid;

      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        String userName = userDoc.exists && userDoc['firstName'] != null
            ? "${userDoc['firstName']} ${userDoc['lastName'] ?? ''}".trim()
            : 'Anonymous';

        draftData['userId'] = userId;
        draftData['userName'] = userName;
      } catch (e) {
        print("Error fetching user data: $e");
        draftData['userId'] = userId;
        draftData['userName'] = 'Anonymous';
      }
    }

    try {
      await FirebaseFirestore.instance.collection('drafts').add(draftData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Draft saved successfully')),
      );
      storyController.clear();
      setState(() {
        _imageUrls.clear(); // Clear the list of image URLs
      });
    } catch (e) {
      print("Error saving draft: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save draft')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Report Your Story',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Voice, Your Power',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Report Anonymously',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Switch(
                    value: isAnonymous,
                    onChanged: (value) {
                      setState(() {
                        isAnonymous = value;
                      });
                    },
                    activeColor: Colors.orangeAccent,
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextField(
                controller: storyController,
                maxLines: 8,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Write your story here...',
                  hintStyle: TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Upload Evidence (Optional)',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _pickImages,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                        ),
                        child: Text(
                          'Pick Images',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _submitStory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: Text(
                          'Submit Report',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _saveDraft,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                        ),
                        child: Text(
                          'Save Draft',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              _imageUrls.isNotEmpty
                  ? GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1,
                      ),
                      itemCount: _imageUrls.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Image.network(
                              _imageUrls[index], // Use Image.network for web
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              right: 0,
                              child: IconButton(
                                icon: Icon(
                                  Icons.remove_circle,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _imageUrls.removeAt(index);
                                  });
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ReportPageApp());
}
