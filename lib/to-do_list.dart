import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class VoiceTodoScreen extends StatefulWidget {
  @override
  _VoiceTodoScreenState createState() => _VoiceTodoScreenState();
}

class _VoiceTodoScreenState extends State<VoiceTodoScreen> {
  final List<Map<String, dynamic>> tasks = [];
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastWords = "";
  FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _lastWords = result.recognizedWords;
          });
        },
        listenFor: Duration(seconds: 5),
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);

    if (_lastWords.isNotEmpty) {
      setState(() {
        tasks.add({"task": _lastWords, "completed": false});
      });
    }
  }

  Future<void> _speakTasks() async {
    if (tasks.isEmpty) {
      await _flutterTts.speak("No tasks found.");
    } else {
      List pendingTasks = tasks.where((task) => !task["completed"]).map((task) => task["task"]).toList();
      if (pendingTasks.isEmpty) {
        await _flutterTts.speak("All tasks are completed.");
      } else {
        await _flutterTts.speak("Your pending tasks are: ${pendingTasks.join(', ')}");
      }
    }
  }

  void _toggleTaskCompletion(int index) {
    setState(() {
      tasks[index]["completed"] = !tasks[index]["completed"];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice To-Do List', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF05385C))),
        backgroundColor: Color(0xFF7AB2D3),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                child: Text(
                  "No tasks added yet",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 4,
                    color: Color(0xFF7AB2D3),
                    child: ListTile(
                      leading: Checkbox(
                        value: tasks[index]["completed"],
                        onChanged: (bool? value) {
                          _toggleTaskCompletion(index);
                        },
                        activeColor: Color(0xFF7AB2D3),
                      ),
                      title: Text(
                        tasks[index]["task"],
                        style: TextStyle(
                          fontSize: 18,
                          decoration: tasks[index]["completed"] ? TextDecoration.lineThrough : null,
                          color: tasks[index]["completed"] ? Colors.grey[800] : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  onPressed: _isListening ? _stopListening : _startListening,
                  backgroundColor: Color(0xFF7AB2D3),
                  child: Icon(_isListening ? Icons.mic : Icons.mic_off, color: Colors.white),
                ),
                FloatingActionButton(
                  onPressed: _speakTasks,
                  backgroundColor: Color(0xFF7AB2D3),
                  child: Icon(Icons.volume_up, color: Colors.white),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
