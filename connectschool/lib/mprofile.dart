// Add performance optimizations to code
// performance optimizations
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectschool/main.dart';
class mProfile extends StatefulWidget {
  @override
  _ProfileManagerState createState() => _ProfileManagerState();
}

Profile _profile = Profile('', '', '', '');
class _ProfileManagerState extends State<mProfile> {
  

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _profile = Profile.fromMap(doc.data() as Map<String, dynamic>);
        });
      } else { return ;
        // Handle case where user profile document doesn't exist
       // print('User profile document does not exist');
      }
    }
  }

  void _handleUpdate(Profile updatedProfile) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updatedProfile.toMap());
      setState(() {
        _profile = updatedProfile;
      });
    }
  }

  Future<void> _addNewPost() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('posts').add({
        'title': _titleController.text,
        'content': _contentController.text,
        'timestamp': DateTime.now(),
        'SchoolId': user.uid,
      });

      _titleController.clear();
      _contentController.clear();
    }
  }

  Future<void> _deletePost(String postId) async {
    await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
  }

  Future<void> _updatePost(String postId, String title, String content) async {
    await FirebaseFirestore.instance.collection('posts').doc(postId).update({
      'title': title,
      'content': content,
    });
  }
void _logout(BuildContext context) async {
  try {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => WelcomePage()), // Replace HomeScreen() with your main page widget
    );
  } catch (e) {
    print("Error signing out: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error signing out. Please try again later.')),
    );
  }
}
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( backgroundColor: Color.fromRGBO(188, 227, 243, 0.957),
        title: Text('School Account'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _logout(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          GestureDetector(
            onTap: () => _showUpdateDialog(context),
            // ignore: unnecessary_null_comparison
            child: _profile != null ? _buildProfileBody() : const Center(child: CircularProgressIndicator()),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (BuildContext context, int index) {const Color.fromARGB(255, 89, 103, 121);
                    DocumentSnapshot doc = snapshot.data!.docs[index];
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    String postId = doc.id;
                    return Card(
                      
                      color:Color.fromARGB(255, 117, 178, 243),
                      child: ListTile(
                        title: Text(data['title']),
                        subtitle: Text(data['content']),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Delete Post'),
                                  content: Text('Are you sure you want to delete this post?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _deletePost(postId);
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('Delete'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Edit Post'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: TextEditingController(text: data['title']),
                                      onChanged: (value) {
                                        setState(() {
                                          data['title'] = value;
                                        });
                                      },
                                      decoration: InputDecoration(labelText: 'Title'),
                                    ),
                                    TextField(
                                      controller: TextEditingController(text: data['content']),
                                      onChanged: (value) {
                                        setState(() {
                                          data['content'] = value;
                                        });
                                      },
                                      decoration: InputDecoration(labelText: 'Content'),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _updatePost(postId, data['title'], data['content']);
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Update'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Add New Post'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _titleController,
                            decoration: InputDecoration(labelText: 'Title'),
                          ),
                          TextField(
                            controller: _contentController,
                            decoration: InputDecoration(labelText: 'Content'),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            _addNewPost();
                            Navigator.of(context).pop();
                          },
                          child: Text('Save'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('Add Post'),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildProfileBody() {
  return GestureDetector(
    onTap: () => _showUpdateDialog(context),
    child: Padding(
      padding: EdgeInsets.all(20.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50, // Adjust as needed
           backgroundImage: AssetImage('schoollogo.png'), // Replace with your logo image name
          ),
          SizedBox(height: 20), // Add spacing between profile image and text
          Text(
            _profile.schoolName,
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          ),
          Text(_profile.email),
          Text(_profile.schoolLocation),
        ],
      ),
    ),
  );
}


  void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => UpdateProfileDialog(
        initialProfile: _profile,
        onUpdate: _handleUpdate,
      ),
    );
  }
}

// Data model for profile information
class Profile {
  final String role;
  final String email;
  final String schoolLocation;
  final String schoolName;

  Profile(this.role, this.email, this.schoolLocation, this.schoolName);

  // Factory constructor for creating Profile from Map (can be used for data storage)
  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        map['role'] as String,
        map['email'] as String,
        map['schoolLocation'] as String,
        map['schoolName'] as String,
      );

  // Create a method to convert Profile to Map for easier storage
  Map<String, dynamic> toMap() => {
        'role': role,
        'email': email,
        'schoolLocation': schoolLocation,
        'schoolName': schoolName,
      };
}

// Optional: Separate widget for Update Profile dialog (can be further customized)
class UpdateProfileDialog extends StatefulWidget {
  final Profile initialProfile;
  final Function(Profile) onUpdate;

  UpdateProfileDialog({required this.initialProfile, required this.onUpdate});

  @override
  _UpdateProfileDialogState createState() => _UpdateProfileDialogState();
}

class _UpdateProfileDialogState extends State<UpdateProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _schoolNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialProfile.email;
    _locationController.text = widget.initialProfile.schoolLocation;
    _schoolNameController.text = widget.initialProfile.schoolName;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update Profile'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min, // Prevent excessive dialog height
          children: [
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              validator: (value) => value!.isEmpty ? 'Please enter your email' : null,
            ),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(labelText: 'School Location'),
              validator: (value) => value!.isEmpty ? 'Please enter your school location' : null,
            ),
            TextFormField(
              controller: _schoolNameController,
              decoration: InputDecoration(labelText: 'School Name'),
              validator: (value) => value!.isEmpty ? 'Please enter your school name' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final updatedProfile = Profile(
                widget.initialProfile.role,
                _emailController.text,
                _locationController.text,
                _schoolNameController.text,
              );
              widget.onUpdate(updatedProfile);
              Navigator.pop(context); // Close dialog after successful update
            }
          },
          child: Text('Update'),
        ),
      ],
    );
  }
}

