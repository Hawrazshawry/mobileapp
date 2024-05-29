import 'dart:async';

import 'package:connectschool/main.dart';
//import 'package:firebase_messaging/firebase_messaging.dart';
//import 'package:flutter/material.dart' as material;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_search_bar/flutter_search_bar.dart' as SearchBar; // Import the package

class ParentSearchScreen extends StatefulWidget {
  @override
  _ParentSearchScreenState createState() => _ParentSearchScreenState();
}

class Profile {
  final String role;
  final String email;
  final String schoolLocation;
  final String schoolName;

  Profile(this.role, this.email, this.schoolLocation, this.schoolName);

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        map['role'] as String,
        map['email'] as String,
        map['schoolLocation']?.toString() ?? '',
        map['schoolName']?.toString() ?? '',
      );

  Map<String, dynamic> toMap() => {
        'role': role,
        'email': email,
        'schoolLocation': schoolLocation,
        'schoolName': schoolName,
      };
}

class _ParentSearchScreenState extends State<ParentSearchScreen> {
  final _firestore = FirebaseFirestore.instance;
  List<Profile> _profiles = [];
  bool _isLoading = true;
  late SearchBar.SearchBar searchBar; // Declare SearchBar
  late StreamSubscription<QuerySnapshot> _subscription;

  @override
  void initState() {
    super.initState();
    _subscribeToProfiles();
    // Initialize SearchBar
    searchBar = SearchBar.SearchBar(
      inBar: true,
      buildDefaultAppBar: buildAppBar,
      setState: setState,
      onChanged: onSearchChanged,
      onClosed: () {
        onSearchChanged('');
      },
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _subscribeToProfiles() {
    _subscription = _firestore.collection('users').where('role', isEqualTo: 'School').snapshots().listen((snapshot) {
      setState(() {
        _profiles = snapshot.docs.map((doc) => Profile.fromMap(doc.data() as Map<String, dynamic>)).toList();
        _isLoading = false;
      });
    }, onError: (error) {
      print(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profiles: $error')),
      );
      setState(() {
        _isLoading = false;
      });
    });
  }

  // Search logic
  void onSearchChanged(String value) {
    setState(() {
      _profiles = _profiles.where((profile) => profile.schoolLocation.toLowerCase().contains(value.toLowerCase())).toList();
      if (value.isEmpty) {
        _subscribeToProfiles();
      }
    });
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Color.fromRGBO(75, 198, 250, 0.957),
      title: Text('List Of School'),
      actions: <Widget>[
        searchBar.getSearchAction(context), // Use searchBar methods with correct class
        IconButton(
          icon: Icon(Icons.notifications),
          onPressed: () {
            // _showNotification();
          },
        ),
        IconButton(
          icon: Icon(Icons.logout),
          onPressed: () {
            _logout(context);
          },
        ),
      ],
    );
  }


  Future<void> _loadProfiles() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('users').get();
      final profiles = snapshot.docs.map((doc) => Profile.fromMap(doc.data() as Map<String, dynamic>)).toList();
      final schoolProfiles = profiles.where((profile) => profile.role == 'School').toList();
      setState(() {
        _profiles = schoolProfiles;
        _isLoading = false;
      });
    } catch (error) {
      print(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profiles: $error')),
      );
      setState(() {
        _isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(255, 255, 255, 1),
      appBar: searchBar.build(context), // Use searchBar instead of AppBar
      body: _isLoading
          ? Center(child: SpinKitFadingCircle(color: Color.fromARGB(255, 5, 133, 239)))
          : _profiles.isEmpty
              ? Center(child: Text('No school profiles found'))
              : ListView.builder(
                  itemCount: _profiles.length,
                  itemBuilder: (context, index) {
                    final profile = _profiles[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: ListTile(
                          tileColor: Color.fromRGBO(236, 236, 236, 0.957),
                          contentPadding: EdgeInsets.all(16.0),
                          title: Text(
                            profile.schoolName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 3, 136, 244),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 8),
                              Text(
                                'Location: ${profile.schoolLocation}',
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Email: ${profile.email}',
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SchoolProfilePage(profile.email)),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class SchoolProfilePage extends StatelessWidget {
  final String schoolEmail; // Email address for filtering

  SchoolProfilePage(this.schoolEmail);

  Future<DocumentSnapshot> getAccountDataByEmail(String email) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get(); // Limit to 1 document

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first;
    } else {
      throw Exception('No user found with the provided email');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(253, 253, 253, 0.957),
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(148, 215, 241, 0.957),
        title: Text('School Profile'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: getAccountDataByEmail(schoolEmail),
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: Text('No user found with the provided email.'),
            );
          }

          final userData= snapshot.data!.data() as Map<String, dynamic>;
          final userId = userData['userId'];

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('posts').where('userId', isEqualTo: userId).snapshots(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text('No posts found for this user.'),
                );
              }

              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final docSnapshot = snapshot.data!.docs[index];
                  if (docSnapshot.exists) {
                    final postData = docSnapshot.data() as Map<String, dynamic>; // corrected the closing bracket
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: ListTile(
                          tileColor: Color.fromRGBO(101, 114, 118, 0.98),
                          title: Text(
                            postData['title'],
                            style: TextStyle(color: Color.fromRGBO(255, 254, 254, 1)),
                          ),
                          subtitle: Text(
                            postData['content'],
                            style: TextStyle(color: Color.fromRGBO(29, 194, 249, 0.969)),
                          ),
                        ),
                      ),
                    );
                  } else {
                    return Text('Error: Document not found.');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

