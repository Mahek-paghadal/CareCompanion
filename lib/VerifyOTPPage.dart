import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'homepage.dart'; // Ensure this path is correct

class VerifyOTPPage extends StatefulWidget {
  final String phoneNumber;

  const VerifyOTPPage({super.key, required this.phoneNumber});

  @override
  _VerifyOTPPageState createState() => _VerifyOTPPageState();
}

class _VerifyOTPPageState extends State<VerifyOTPPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _otpController = TextEditingController();

  String _verificationId = '';
  bool _codeSent = false;
  bool _isOTPValid = true;
  bool _isLoading = false; // To show loading indicator

  @override
  void initState() {
    super.initState();
    _sendOTP(widget.phoneNumber);
  }

  Future<void> _sendOTP(String phoneNumber) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber.trim(),
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (!mounted) return;

          setState(() {
            _isLoading = false;
          });
          await _auth.signInWithCredential(credential);
          _navigateToHomePage();
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;

          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification failed: ${e.message}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;

          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!mounted) return;

          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending OTP: $e')),
      );
    }
  }

  Future<void> _verifyOTP() async {
    if (_verificationId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification ID not found. Please resend OTP.')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );

      await _auth.signInWithCredential(credential);
      setState(() {
        _isLoading = false;
      });
      _navigateToHomePage();
    } catch (e) {
      setState(() {
        _isOTPValid = false;
        _isLoading = false;
      });
    }
  }

  void _resendOTP() {
    _sendOTP(widget.phoneNumber);
  }

  void _navigateToHomePage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7AB2D3),
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/Logo.jpg', // Replace with your actual logo path
              height: 50,
              width: 50,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Text(
              'Care Companion',
              style: GoogleFonts.carattere(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF123c5c),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    'assets/elder people.png', // Replace with your actual image path
                    height: 180,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Verify your phone number',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF123c5c)),
                ),
                const SizedBox(height: 10),
                Text(
                  'We have sent an OTP to ${widget.phoneNumber}. Please enter it below to verify.',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  obscureText: false,
                  animationType: AnimationType.fade,
                  cursorColor: Colors.black,
                  keyboardType: TextInputType.number,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF123c5c),
                    fontWeight: FontWeight.bold,
                  ),
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(8),
                    fieldHeight: 50,
                    fieldWidth: 45,
                    activeFillColor: Colors.white,
                    inactiveFillColor: Colors.grey.shade200,
                    selectedFillColor: Colors.grey.shade300,
                    activeColor: const Color(0xFF7AB2D3),
                    inactiveColor: Colors.grey,
                    selectedColor: const Color(0xFF123c5c),
                  ),
                  controller: _otpController,
                  onChanged: (value) {
                    setState(() {
                      _isOTPValid = true;
                    });
                  },
                ),
                if (!_isOTPValid)
                  const Padding(
                    padding: EdgeInsets.only(top: 5, left: 10),
                    child: Text(
                      "Incorrect OTP. Please try again.",
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7AB2D3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'VERIFY OTP',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Center(
                  child: GestureDetector(
                    onTap: _resendOTP,
                    child: Text(
                      "Resend OTP to ${widget.phoneNumber}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}