import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:math';

class NumberPuzzle extends StatefulWidget {
  @override
  _NumberPuzzleState createState() => _NumberPuzzleState();
}

class _NumberPuzzleState extends State<NumberPuzzle> {
  List<int> _numbers = [];
  FlutterTts _flutterTts = FlutterTts();
  stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speak("Welcome to Number Puzzle. Say 'Start' to begin the game.");
    _shuffleNumbers();
    _initSpeech();
  }

  void _initSpeech() async {
    bool available = await _speechToText.initialize();
    if (available) {
      _startListening();
    }
  }

  void _startListening() {
    _speechToText.listen(
      onResult: (result) {
        if (result.recognizedWords.toLowerCase() == "start") {
          _shuffleNumbers();
          _speak("Game Started. Arrange the numbers in order.");
        } else if (result.recognizedWords.toLowerCase() == "reset") {
          _shuffleNumbers();
          _speak("Game Reset. Try again.");
        }
      },
    );
  }

  void _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _shuffleNumbers() {
    setState(() {
      _numbers = List.generate(15, (index) => index + 1)..shuffle();
      _numbers.add(0); // Empty space
    });
  }

  bool _checkWin() {
    for (int i = 0; i < 15; i++) {
      if (_numbers[i] != i + 1) return false;
    }
    _speak("Congratulations! You solved the puzzle.");
    return true;
  }

  void _moveTile(int index) {
    int emptyIndex = _numbers.indexOf(0);
    List<int> validMoves = [
      emptyIndex - 1,
      emptyIndex + 1,
      emptyIndex - 4,
      emptyIndex + 4
    ];

    if (validMoves.contains(index)) {
      setState(() {
        _numbers[emptyIndex] = _numbers[index];
        _numbers[index] = 0;
      });

      if (_checkWin()) {
        _speak("You won! Say 'Reset' to play again.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Number Puzzle" , style: TextStyle(color: Color(0xFF05385C))),
        backgroundColor: Color(0xFF7AB2D3),
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Text(
            "Arrange the numbers in order",
            style: TextStyle(fontSize: 22, color: Color(0xFF05385C)),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _numbers.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _moveTile(index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _numbers[index] == 0
                            ? Colors.white
                            : Color(0xFF7AB2D3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          _numbers[index] == 0 ? "" : "${_numbers[index]}",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _shuffleNumbers();
              _speak("Game Reset. Try again.");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF7AB2D3),
              foregroundColor: Color(0xFF05385C),
            ),
            child: Text("Restart Game"),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
