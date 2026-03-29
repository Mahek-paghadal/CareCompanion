import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

class MedicineListPage extends StatefulWidget {
  const MedicineListPage({super.key});

  @override
  _MedicineListPageState createState() => _MedicineListPageState();
}

class _MedicineListPageState extends State<MedicineListPage> {
  final List<Map<String, dynamic>> _medicines = [];
  final Set<int> _selectedIndexes = {};
  bool _isSelectionMode = false;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _spokenText = "";

  final TextEditingController _medicineController = TextEditingController();
  String? _selectedTime;
  List<String> _selectedDays = [];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    requestPermission();
  }

  void _initializeNotifications() {
    AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'medicine_channel',
          channelName: 'Medicine Reminders',
          channelDescription: 'Notification channel for medicine reminders',
          defaultColor: const Color(0xFF7AB2D3),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
        )
      ],
    );
  }

  /// Show notification instantly (instead of scheduling)
  Future<void> _showInstantNotification(String medicineName) async {
    int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: 'medicine_channel',
        title: 'Medicine Reminder',
        body: 'Time to take your medicine: $medicineName',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndexes.contains(index)) {
        _selectedIndexes.remove(index);
      } else {
        _selectedIndexes.add(index);
      }
      _isSelectionMode = _selectedIndexes.isNotEmpty;
    });
  }

  void _deleteSelectedItems() {
    setState(() {
      _medicines.removeWhere((item) => _selectedIndexes.contains(_medicines.indexOf(item)));
      _selectedIndexes.clear();
      _isSelectionMode = false;
    });
  }

  void _showAddMedicineDialog() {
    _selectedTime = null;
    _selectedDays = [];
    _medicineController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text("Add Medicine"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _medicineController,
                      decoration: const InputDecoration(labelText: "Medicine Name"),
                    ),
                    const SizedBox(height: 10),
                    const Text("Select Time"),
                    Wrap(
                      spacing: 8.0,
                      children: ["Morning", "Afternoon", "Night"].map(
                            (time) => ChoiceChip(
                          label: Text(time),
                          selected: _selectedTime == time,
                          onSelected: (isSelected) {
                            setDialogState(() {
                              _selectedTime = isSelected ? time : null;
                            });
                          },
                        ),
                      ).toList(),
                    ),
                    const SizedBox(height: 10),
                    const Text("Select Days"),
                    Wrap(
                      spacing: 8.0,
                      children: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map(
                            (day) => FilterChip(
                          label: Text(day),
                          selected: _selectedDays.contains(day),
                          onSelected: (isSelected) {
                            setDialogState(() {
                              isSelected ? _selectedDays.add(day) : _selectedDays.remove(day);
                            });
                          },
                        ),
                      ).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7AB2D3)),
                  onPressed: () async {
                    if (_medicineController.text.isNotEmpty && _selectedTime != null) {
                      setState(() {
                        _medicines.add({
                          "name": _medicineController.text,
                          "time": _selectedTime!,
                          "days": _selectedDays.isNotEmpty ? _selectedDays : ["Everyday"],
                        });
                      });

                      // Show notification immediately
                      await _showInstantNotification(_medicineController.text);

                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter details properly!")),
                      );
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == "notListening") {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        setState(() => _isListening = false);
      },
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (result) {
        setState(() {
          _spokenText = result.recognizedWords;
        });

        if (_spokenText.isNotEmpty) {
          setState(() {
            _medicines.add({
              "name": _spokenText,
              "time": "Morning",
              "days": ["Everyday"],
            });
          });

          _showInstantNotification(_spokenText);
        }
      });
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7AB2D3),
        title: const Text('Medicine List', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF05385C))),
        actions: _isSelectionMode
            ? [
          IconButton(
            icon: const Icon(Icons.delete, color: Color(0xFF05385C)),
            onPressed: _deleteSelectedItems,
          ),
        ]
            : [],
      ),
      body: ListView.builder(
        itemCount: _medicines.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedIndexes.contains(index);
          return GestureDetector(
            onLongPress: () => _toggleSelection(index),
            child: Card(
              elevation: 6,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: isSelected ? const BorderSide(color: Colors.blue, width: 2) : BorderSide.none,
              ),
              child: ListTile(
                tileColor: isSelected ? Colors.blue.shade100 : Colors.white,
                leading: Icon(
                  Icons.medical_services,
                  color: const Color(0xFF7AB2D3),
                ),
                title: Text(
                  _medicines[index]["name"],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Time: ${_medicines[index]["time"]}\nDays: ${_medicines[index]["days"].join(", ")}",
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleSelection(index);
                  }
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            backgroundColor: const Color(0xFF7AB2D3),
            onPressed: _isListening ? _stopListening : _startListening,
            child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
          ),
          FloatingActionButton(
            backgroundColor: const Color(0xFF7AB2D3),
            onPressed: _showAddMedicineDialog,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
