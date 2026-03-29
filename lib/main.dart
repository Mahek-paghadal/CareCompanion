import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'loginpage.dart';
import 'signuppage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Care Companion',
      theme: ThemeData(
        primaryColor: const Color(0xFF7AB2D3),
        scaffoldBackgroundColor: const Color(0xFF7AB2D3),
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7AB2D3),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/welcome_page.png',
            height: 320,
            width: 370,
          ),
          const SizedBox(height: 30),
          Text(
            "Let's Care Together",
            style: GoogleFonts.poppins(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF05385C),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Because Every Moment Matters.",
            style: GoogleFonts.poppins(
              fontSize: 20,
              color: const Color(0xFF05385C),
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildButton(
                text: "LOGIN",
                color: const Color(0xFF7AB2D3),
                textColor: const Color(0xFF05385C),
                borderColor: const Color(0xFF05385C),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
              ),
              const SizedBox(width: 20),
              _buildButton(
                text: "SIGNUP",
                color: const Color(0xFF05385C),
                textColor: const Color(0xFF7AB2D3),
                borderColor: Colors.transparent,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignupPage()), // Changed SignUpPage to SignupPage
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 30), // Adjust bottom spacing
        ],
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required Color color,
    required Color textColor,
    required Color borderColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 145,
      height: 45,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: borderColor),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}