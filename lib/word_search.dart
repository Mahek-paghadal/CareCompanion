import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class WordSearchGame extends StatefulWidget {
  @override
  _WordSearchGameState createState() => _WordSearchGameState();
}

class _WordSearchGameState extends State<WordSearchGame> {
  final List<String> words = ["FLUTTER", "DART", "MOBILE", "GAME", "WIDGET"];
  List<List<String>> grid = [];
  List<List<bool>> highlighted = [];
  FlutterTts _flutterTts = FlutterTts();
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String lastSpokenWord = "";

  @override
  void initState() {
    super.initState();
    _speak("Welcome to Word Search. Say a word to highlight or 'restart' to reset.");
    _generateGrid();
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
      String command = result.recognizedWords.toUpperCase();
      if (words.contains(command)) {
        _highlightWord(command);
        _speak("$command highlighted.");
      } else if (command.contains("RESTART")) {
        _resetGame();
        _speak("Game restarted.");
      }
    });
  }

  void _generateGrid() {
    grid = List.generate(8, (_) => List.generate(8, (_) => _randomLetter()));
    highlighted = List.generate(8, (_) => List.generate(8, (_) => false));

    for (String word in words) {
      _placeWord(word);
    }
    setState(() {});
  }

  void _placeWord(String word) {
    Random random = Random();
    int row = random.nextInt(8);
    int col = random.nextInt(8 - word.length);

    for (int i = 0; i < word.length; i++) {
      grid[row][col + i] = word[i];
    }
  }

  String _randomLetter() {
    return String.fromCharCode(Random().nextInt(26) + 65);
  }

  void _highlightWord(String word) {
    for (int r = 0; r < grid.length; r++) {
      for (int c = 0; c < grid[r].length - word.length + 1; c++) {
        if (grid[r].sublist(c, c + word.length).join() == word) {
          for (int i = 0; i < word.length; i++) {
            highlighted[r][c + i] = true;
          }
        }
      }
    }
    setState(() {});
  }

  void _resetGame() {
    _generateGrid();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Word Search Game" , style: TextStyle(color: Color(0xFF05385C))),
        backgroundColor: Color(0xFF7AB2D3),
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
              ),
              itemCount: 64,
              itemBuilder: (context, index) {
                int row = index ~/ 8;
                int col = index % 8;
                return Container(
                  decoration: BoxDecoration(
                    color: highlighted[row][col] ? Colors.green : Colors.blueGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      grid[row][col],
                      style: TextStyle(fontSize: 22, color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                backgroundColor: Colors.redAccent,
                onPressed: _resetGame,
                child: Icon(Icons.restart_alt),
              ),
              SizedBox(width: 15),
              FloatingActionButton(
                backgroundColor: _isListening ? Colors.green : Color(0xFF7AB2D3),
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
