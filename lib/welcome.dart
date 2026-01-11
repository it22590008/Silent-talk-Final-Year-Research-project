import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_research_2026/dashboard.dart';

import 'login.dart';

class WelcomeScreen extends StatefulWidget {
  static const String idScreen = "welcomeScreen";

  @override
  _WelcomeScreen createState() => _WelcomeScreen();
}

class _WelcomeScreen extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    navigateScreen(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.sign_language, color: Colors.white, size: 50),
            ),
            const SizedBox(height: 24),
            Text(
              "App Name",
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Description",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 50),
            const SizedBox(
              height: 50,
              width: 50,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                strokeWidth: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void navigateScreen(BuildContext context) async {
    var d = const Duration(seconds: 3);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Future.delayed(d, () {
      if (prefs.getString('email') != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => LoginScreen()));
      }
    });
  }
}
