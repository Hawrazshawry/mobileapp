import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:connectschool/login.dart';

class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> with SingleTickerProviderStateMixin {
  bool showProgress = false;
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmpassController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController teacherNameController = TextEditingController();
  final TextEditingController schoolLocationController = TextEditingController();

  String _currentItemSelected = 'Parent';

  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB3E5FC), Color(0xFF0288D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Column(
        children: [
          Expanded( // Use Expanded to make the SingleChildScrollView take all available space
            child: SingleChildScrollView(
              child: FadeTransition(
                opacity: _fadeInAnimation,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 80),
                        _buildHeader(),
                        const SizedBox(height: 50),
                        _buildEmailField(),
                        const SizedBox(height: 20),
                        _buildPasswordField(passwordController, 'Password'),
                        const SizedBox(height: 20),
                        _buildPasswordField(confirmpassController, 'Confirm Password', true),
                        const SizedBox(height: 20),
                        _buildRoleButtons(),
                        if (_currentItemSelected == 'School') _buildSchoolFields(),
                        const SizedBox(height: 20),
                        _buildButtons(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


  Widget _buildHeader() {
    return const Text(
      "Register Now",
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontSize: 40,
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: emailController,
      decoration: _buildInputDecoration('Email'),
      validator: (value) {
        if (value!.isEmpty) {
          return "Email cannot be empty";
        }
        if (!RegExp(r'^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+\.[a-z]+$').hasMatch(value)) {
          return "Please enter a valid email";
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String hintText, [bool isConfirm = false]) {
    return TextFormField(
      obscureText: true,
      controller: controller,
      decoration: _buildInputDecoration(hintText, true),
      validator: (value) {
        if (value!.isEmpty) {
          return "$hintText cannot be empty";
        }
        if (!isConfirm && value.length < 6) {
          return "$hintText must be at least 6 characters long";
        }
        if (isConfirm && value != passwordController.text) {
          return "Passwords do not match";
        }
        return null;
      },
    );
  }

  InputDecoration _buildInputDecoration(String hintText, [bool hasSuffixIcon = false]) {
    return InputDecoration(
      suffixIcon: hasSuffixIcon ? IconButton(icon: const Icon(Icons.visibility), onPressed: () {}) : null,
      filled: true,
      fillColor: Colors.white,
      hintText: hintText,
      enabled: true,
      contentPadding: const EdgeInsets.only(left: 14.0, bottom: 8.0, top: 8.0),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white),
        borderRadius: BorderRadius.circular(20),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: const BorderSide(color: Colors.white),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildRoleButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildRoleButton('Parent', _currentItemSelected == 'Parent'),
        const SizedBox(width: 20),
        _buildRoleButton('School', _currentItemSelected == 'School'),
      ],
    );
  }

  Widget _buildRoleButton(String role, bool isSelected) {
    return MaterialButton(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 5.0,
      height: 40,
      color: isSelected ? Colors.blue[900] : Colors.white,
      onPressed: () {
        setState(() {
          _currentItemSelected = role;
        });
      },
      child: Text(
        role,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.blue[900],
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildSchoolFields() {
    return Column(
      children: [
        const SizedBox(height: 20),
        _buildTextFormField(teacherNameController, "School's Name"),
        const SizedBox(height: 20),
        _buildTextFormField(schoolLocationController, 'School Location'),
      ],
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String hintText) {
    return TextFormField(
      controller: controller,
      decoration: _buildInputDecoration(hintText),
      validator: (value) {
        if (value!.isEmpty) {
          return "$hintText cannot be empty";
        }
        return null;
      },
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildButton('Login', () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
        }),
        _buildButton('Register', () {
          setState(() {
            showProgress = true;
          });
          signUp(emailController.text, passwordController.text);
        }),
      ],
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return MaterialButton(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
      ),
      elevation: 5.0,
      height: 40,
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
        ),
      ),
      color: Colors.white,
    );
  }

  void signUp(String email, String password) async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        await userCredential.user!.sendEmailVerification();
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'role': _currentItemSelected,
          'schoolName': _currentItemSelected == 'School' ? teacherNameController.text : null,
          'schoolLocation': _currentItemSelected == 'School' ? schoolLocationController.text : null,
        });
        _showDialog("Success", "An email has been sent to $email for verification. Please verify your email address to continue.");
      } catch (e) {
        print('Error signing up: $e');
        if (e is FirebaseAuthException) {
          String errorMessage = e.code == 'email-already-in-use'
              ? "The email address is already in use by another account."
              : "An error occurred while signing up. Please try again later.";
          _showDialog("Error", errorMessage);
        }
      }
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _isEmailVerified() async {
    await _auth.currentUser!.reload();
    return _auth.currentUser!.emailVerified;
  }
}
