import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AppointmentDetailsPage extends StatelessWidget {
  static String doctorName = '';
  static DateTime? appointmentDate;
  static TimeOfDay? appointmentTime;
  static String meetingID = '';

  const AppointmentDetailsPage({super.key});

  void joinMeeting() async {
    String jitsiMeetingUrl = "https://meet.jit.si/$meetingID";
    Uri meetingUri = Uri.parse(jitsiMeetingUrl);

    if (await canLaunchUrl(meetingUri)) {
      await launchUrl(meetingUri, mode: LaunchMode.externalApplication);
    } else {
      throw "Could not launch $jitsiMeetingUrl";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text("Appointment Details"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue[100],
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Dr. $doctorName",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (appointmentDate != null && appointmentTime != null)
                    Column(
                      children: [
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.calendar_today, color: Colors.blueAccent),
                          title: Text(
                            "Date: ${appointmentDate!.day}/${appointmentDate!.month}/${appointmentDate!.year}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.access_time, color: Colors.blueAccent),
                          title: Text(
                            "Time: ${appointmentTime!.format(context)}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const Divider(),
                      ],
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: joinMeeting,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.blueAccent,
                    ),
                    child: const Text(
                      "Join Now",
                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DoctorAppointmentPage extends StatefulWidget {
  const DoctorAppointmentPage({super.key});

  @override
  State<DoctorAppointmentPage> createState() => _DoctorAppointmentPageState();
}

class _DoctorAppointmentPageState extends State<DoctorAppointmentPage> {
  final List<String> _specializations = [
    'Cardiologist',
    'General Physician',
    'Dentist',
    'Neurologist',
    'Dermatologist',
  ];

  String? _selectedSpecialization;
  String? _selectedHospital;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  List<String> _suggestedHospitals = [];
  bool _isLoadingHospitals = false;
  List<Marker> _hospitalMarkers = [];
  LatLng? _currentLocation;
  final MapController _mapController = MapController();

  final TextEditingController _hospitalSearchController = TextEditingController();
  Timer? _debounce;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _initializeNotification();
    _getCurrentLocation();
  }

  Future<void> _requestPermissions() async {
    await perm.Permission.notification.request();
    await perm.Permission.location.request();
  }

  void _initializeNotification() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showReminderNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your_channel_id',
      'Appointment Reminder',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(0, title, body, platformChannelSpecifics);
  }

  void _pickDate() async {
    FocusScope.of(context).unfocus();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _pickTime() async {
    FocusScope.of(context).unfocus();
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _confirmBooking() async {
    if (_selectedSpecialization != null &&
        _selectedHospital != null &&
        _selectedDate != null &&
        _selectedTime != null) {
      try {
        final appointmentData = {
          'hospital': _selectedHospital,
          'location': {
            'latitude': _currentLocation?.latitude,
            'longitude': _currentLocation?.longitude,
          },
          'specialization': _selectedSpecialization,
          'status': 'pending',
          'time': '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
          'date': Timestamp.fromDate(_selectedDate!),
          'createdAt': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('appointments').add(appointmentData);

        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Appointment Confirmed'),
              content: Text(
                'Your appointment at $_selectedHospital ($_selectedSpecialization) is set for\n${DateFormat.yMMMd().format(_selectedDate!)} at ${_selectedTime!.format(context)}.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                )
              ],
            ),
          );
        }

        Timer(const Duration(seconds: 5), () {
          _showReminderNotification(
            'Doctor Appointment Reminder',
            'Appointment at $_selectedHospital on ${DateFormat.yMMMd().format(_selectedDate!)} at ${_selectedTime!.format(context)}',
          );
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving appointment: $e')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all the details.')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _loadHospitals([String? query]) async {
    if (_currentLocation == null) return;

    final searchTerm = query ?? 'hospital ${_selectedSpecialization ?? ''}';
    setState(() {
      _isLoadingHospitals = true;
      _suggestedHospitals.clear();
      _hospitalMarkers.clear();
    });

    final url =
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(searchTerm)}&limit=20&bounded=1&viewbox=${_currentLocation!.longitude - 0.05},${_currentLocation!.latitude + 0.05},${_currentLocation!.longitude + 0.05},${_currentLocation!.latitude - 0.05}';

    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent': 'Flutter App',
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        _suggestedHospitals = data.map((doc) => doc['display_name'] ?? 'Unnamed Hospital').cast<String>().toList();
        _hospitalMarkers = data
            .map((doc) => Marker(
          point: LatLng(double.parse(doc['lat']), double.parse(doc['lon'])),
          width: 80,
          height: 80,
          child: const Icon(Icons.local_hospital, color: Colors.red, size: 40),
        ))
            .toList();
        _mapController.move(_currentLocation!, 13);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading hospitals: ${response.statusCode}')),
      );
    }

    setState(() => _isLoadingHospitals = false);
  }

  void _onHospitalTextChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (value.isNotEmpty) {
        _loadHospitals(value);
      }
    });
  }

  @override
  void dispose() {
    _hospitalSearchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple[50],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Book Doctor Appointment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('Choose Specialization:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedSpecialization,
              hint: const Text('Select Specialization'),
              items: _specializations.map((spec) => DropdownMenuItem(value: spec, child: Text(spec))).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSpecialization = value;
                  _selectedHospital = null;
                  _suggestedHospitals.clear();
                  _hospitalMarkers.clear();
                });
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _hospitalSearchController,
              onChanged: _onHospitalTextChanged,
              decoration: InputDecoration(
                labelText: 'Search Hospital by Name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                _loadHospitals(_hospitalSearchController.text);
              },
              child: const Text('Search Nearby Hospitals'),
            ),
            const SizedBox(height: 10),
            _isLoadingHospitals
                ? const Center(child: CircularProgressIndicator())
                : _selectedHospital == null
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _suggestedHospitals.map((hospital) {
                return ListTile(
                  title: Text(hospital),
                  leading: const Icon(Icons.local_hospital),
                  onTap: () {
                    setState(() {
                      _selectedHospital = hospital;
                      _hospitalSearchController.clear();
                      _suggestedHospitals.clear();
                    });
                    FocusScope.of(context).unfocus();
                  },
                );
              }).toList(),
            )
                : const SizedBox.shrink(),
            if (_selectedHospital != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Selected Hospital:\n$_selectedHospital',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: _currentLocation == null
                  ? const Center(child: CircularProgressIndicator())
                  : FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLocation!,
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
                  ),
                  MarkerLayer(markers: _hospitalMarkers),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentLocation!,
                        width: 80,
                        height: 80,
                        child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Choose Date:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: _pickDate,
              child: Text(_selectedDate == null ? 'Pick a date' : DateFormat.yMMMd().format(_selectedDate!)),
            ),
            const SizedBox(height: 20),
            const Text('Choose Time:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: _pickTime,
              child: Text(_selectedTime == null ? 'Pick a time' : _selectedTime!.format(context)),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _confirmBooking,
              icon: const Icon(Icons.check_circle),
              label: const Text('Confirm Appointment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }
}
