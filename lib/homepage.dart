import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'medicine_list.dart';
import 'to-do_list.dart';
import 'news.dart';
import 'games.dart';
import 'doctor_appointment.dart';
import 'chatbot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'sosbutton.dart';

void main() {
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
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showSettings = false;
  int _selectedIndex = 0;

  stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  String _spokenText = "";

  void _toggleSettings() {
    setState(() {
      _showSettings = !_showSettings;
    });
  }

  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 2) {
        _toggleSettings();
      }
    });
  }

  void _startListening() async {
    bool available = await _speechToText.initialize();
    if (available) {
      setState(() {
        _isListening = true;
      });
      _speechToText.listen(onResult: (result) {
        setState(() {
          _spokenText = result.recognizedWords;
        });
        if (_spokenText.contains('medicine')) {
          _navigateTo(MedicineListPage());
        } else if (_spokenText.contains('list')) {
          _navigateTo(VoiceTodoScreen());
        } else if (_spokenText.contains('games')) {
          _navigateTo(GameScreen());
        } else if (_spokenText.contains('news')) {
          _navigateTo(NewsScreen());
        } else if (_spokenText.contains('doctor')) {
          _navigateTo(DoctorAppointmentPage());
        } else if (_spokenText.contains('chatbot')) {
          _navigateTo(ChatScreen());
        }
      });
    }
  }

  void _stopListening() {
    setState(() {
      _isListening = false;
    });
    _speechToText.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7AB2D3),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/Logo.jpg',
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7AB2D3), Color(0xFF123c5c)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, Elders! 👋",
                      style: GoogleFonts.lato(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.health_and_safety, color: Colors.white, size: 28),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Stay hydrated and drink at least 8 glasses of water daily!",
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1,
                ),
                itemCount: 6, // updated from 5 to 6
                itemBuilder: (context, index) {
                  List<String> images = [
                    'assets/medicine.png',
                    'assets/to-do_list.png',
                    'assets/mind_games.png',
                    'assets/news.png',
                    'assets/doctor_appointment.png',
                    'assets/chatbot.png', // New ChatBot asset
                  ];
                  List<String> titles = [
                    "Medicine List",
                    "To-Do List",
                    "Mind Games",
                    "News",
                    "Doctor Appointment",
                    "ChatBot" // New title
                  ];
                  List<Widget> pages = [
                    MedicineListPage(),
                    VoiceTodoScreen(),
                    GameScreen(),
                    NewsScreen(),
                    DoctorAppointmentPage(),
                    ChatScreen() // New page
                  ];

                  return GestureDetector(
                    onTap: () => _navigateTo(pages[index]),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(images[index], height: 80),
                          const SizedBox(height: 10),
                          Text(titles[index], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF7AB2D3),
        selectedItemColor: const Color(0xFF123c5c),
        unselectedItemColor: const Color(0xFF123c5c),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home, color: Color(0xFF123c5c)), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications, color: Color(0xFF123c5c)), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.settings, color: Color(0xFF123c5c)), label: 'Settings'),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 80),
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SOSButton()),
                );
              },
              backgroundColor: Colors.red,
              child: const Text(
                'SOS',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20, bottom: 80),
            child: FloatingActionButton(
              onPressed: _isListening ? _stopListening : _startListening,
              backgroundColor: const Color(0xFF7AB2D3),
              child: Icon(_isListening ? Icons.mic : Icons.mic_off, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBotScreen extends StatelessWidget {
  const ChatBotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ChatBot')),
      body: const Center(
        child: Text('ChatBot interface coming soon...', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Care Companion'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SOSButton()),
            );
          },
          child: const Text(
            'SOS',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }