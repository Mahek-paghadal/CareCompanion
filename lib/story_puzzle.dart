import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:math';

class StoryPuzzleGame extends StatefulWidget {
  @override
  _StoryPuzzleGameState createState() => _StoryPuzzleGameState();
}

class _StoryPuzzleGameState extends State<StoryPuzzleGame> {
  List<String> storyParts = [
    "Once upon a time,",
    "in a faraway land,",
    "there lived a brave warrior.",
    "He set out on an adventure",
    "to find a hidden treasure.",
    "After many challenges,",
    "he finally found the treasure",
    "and returned home as a hero!"
  ];

  List<String> shuffledParts = [];
  FlutterTts _flutterTts = FlutterTts();
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speak("Welcome to Story Puzzle. Drag and drop to arrange the story, or say 'shuffle' to mix.");
    _shufflePuzzle();
    _initSpeechRecognition();
  }

  void _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _initSpeechRecognition() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == "notListening") {
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (error) {
        print("Speech Error: $error");
      },
    );
    if (available) {
      _listenForCommands();
    }
  }

  void _listenForCommands() async {
    _isListening = true;
    await _speech.listen(onResult: (result) {
      String command = result.recognizedWords.toLowerCase();
      if (command.contains("shuffle")) {
        _shufflePuzzle();
        _speak("Puzzle shuffled.");
      } else if (command.contains("solve")) {
        _solvePuzzle();
        _speak("Story solved!");
      }
    });
  }

  void _shufflePuzzle() {
    shuffledParts = List.from(storyParts);
    shuffledParts.shuffle(Random());
    setState(() {});
  }

  void _solvePuzzle() {
    shuffledParts = List.from(storyParts);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Story Puzzle" , style: TextStyle(color: Color(0xFF05385C))),
        backgroundColor: Color(0xFF7AB2D3),
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Expanded(
            child: ReorderableListView(
              padding: EdgeInsets.all(10),
              children: shuffledParts.map((part) {
                return Card(
                  key: ValueKey(part),
                  color: Colors.blueGrey,
                  child: ListTile(
                    title: Text(
                      part,
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                );
              }).toList(),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = shuffledParts.removeAt(oldIndex);
                  shuffledParts.insert(newIndex, item);
                });
              },
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                backgroundColor: Color(0xFF7AB2D3),
                onPressed: _shufflePuzzle,
                child: Icon(Icons.shuffle),
              ),
              SizedBox(width: 15),
              FloatingActionButton(
                backgroundColor: Colors.greenAccent,
                onPressed: _solvePuzzle,
                child: Icon(Icons.check),
              ),
              SizedBox(width: 15),
              FloatingActionButton(
                backgroundColor: _isListening ? Colors.green : Colors.grey,
                onPressed: _listenForCommands,
                child: Icon(Icons.mic),
              ),
            ],
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}
