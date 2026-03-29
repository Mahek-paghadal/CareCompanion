import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MaterialApp(home: Scaffold(body: Center(child: SOSButton()))));
}

class SOSButton extends StatefulWidget {
  @override
  _SOSButtonState createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton> {
  List<String> savedNumbers = [];
  bool isSOSActivated = false;

  @override
  void initState() {
    super.initState();
    _loadSavedNumbers();
    _requestSMSPermission();
  }

  Future<void> _requestSMSPermission() async {
    final status = await Permission.sms.request();
    if (status.isDenied) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Permission Required"),
        content: Text("This app needs SMS permission to send emergency alerts."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSavedNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedNumbers = prefs.getStringList('sosNumbers') ?? [];
      isSOSActivated = savedNumbers.isNotEmpty;
    });
  }

  Future<void> _saveNumbers(List<String> numbers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('sosNumbers', numbers);
    setState(() {
      savedNumbers = numbers;
      isSOSActivated = true;
    });
  }

  void _openNumberScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddContactsScreen(initialContacts: savedNumbers),
      ),
    );
    if (result != null && result is List<String>) {
      _saveNumbers(result);
    }
  }

  void _sendSOSMessage() async {
    final status = await Permission.sms.status;
    if (!status.isGranted) {
      _requestSMSPermission();
      return;
    }

    bool isCancelled = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        Future.delayed(Duration(seconds: 5), () {
          if (!isCancelled) {
            Navigator.of(dialogContext).pop();
            _sendSMS();
          }
        });

        return AlertDialog(
          title: Text("SOS Alert"),
          content: Text("Message will be sent in 5 seconds. Cancel if not needed."),
          actions: [
            TextButton(
              onPressed: () {
                isCancelled = true;
                Navigator.of(dialogContext).pop();
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  void _sendSMS() async {
    const message = "Your elder is in trouble! 🔴";

    for (String number in savedNumbers) {
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: number,
        queryParameters: <String, String>{'body': message},
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        print("❌ Could not launch SMS app for $number");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        if (isSOSActivated) {
          _sendSOSMessage();
        } else {
          _openNumberScreen();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
      ),
      child: Text(
        "SOS",
        style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class AddContactsScreen extends StatefulWidget {
  final List<String> initialContacts;

  const AddContactsScreen({Key? key, this.initialContacts = const []}) : super(key: key);

  @override
  _AddContactsScreenState createState() => _AddContactsScreenState();
}

class _AddContactsScreenState extends State<AddContactsScreen> {
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    for (var contact in widget.initialContacts) {
      _controllers.add(TextEditingController(text: contact));
    }
    while (_controllers.length < 2) {
      _controllers.add(TextEditingController());
    }
  }

  void _addField() {
    if (_controllers.length < 3) {
      setState(() {
        _controllers.add(TextEditingController());
      });
    }
  }

  void _submitContacts() {
    final contacts = _controllers
        .map((controller) => controller.text.trim())
        .where((contact) => contact.isNotEmpty)
        .toList();

    if (contacts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter at least 2 emergency contacts.")),
      );
    } else {
      Navigator.pop(context, contacts);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Emergency Contacts")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ..._controllers.map(
                  (controller) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Phone Number",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            if (_controllers.length < 3)
              TextButton(onPressed: _addField, child: Text("Add Another Contact")),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitContacts,
              child: Text("Save Contacts"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
