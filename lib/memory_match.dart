import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flip_card/flip_card.dart';

class MemoryMatchGame extends StatefulWidget {
  @override
  _MemoryMatchGameState createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<MemoryMatchGame> {
  List<String> _allEmojis = ["🍎", "🍌", "🍇", "🍉", "🍊", "🍒", "🍍", "🥭", "🥝", "🍓", "🍈", "🍋"];
  List<String> _gameGrid = [];
  List<GlobalKey<FlipCardState>> _cardKeys = [];
  List<bool> _revealed = [];
  int? _firstSelected;
  int? _secondSelected;
  bool _isProcessing = false;
  FlutterTts _flutterTts = FlutterTts();
  int _level = 1;

  @override
  void initState() {
    super.initState();
    _speak("Welcome to Memory Match! Try to match all the pairs.");
    _initializeGame();
  }

  void _initializeGame() {
    int pairsCount = 4 + (_level - 1) * 2;
    List<String> levelEmojis = _allEmojis.sublist(0, pairsCount);

    _gameGrid = List.from(levelEmojis)..addAll(levelEmojis);
    _gameGrid.shuffle();
    _revealed = List.filled(_gameGrid.length, false);
    _cardKeys = List.generate(_gameGrid.length, (index) => GlobalKey<FlipCardState>());
    _firstSelected = null;
    _secondSelected = null;

    setState(() {});
  }

  void _handleCardTap(int index) {
    if (_isProcessing || _revealed[index]) return;
    _cardKeys[index].currentState?.toggleCard();

    setState(() {
      if (_firstSelected == null) {
        _firstSelected = index;
      } else if (_secondSelected == null) {
        _secondSelected = index;
        _isProcessing = true;

        if (_gameGrid[_firstSelected!] == _gameGrid[_secondSelected!]) {
          Future.delayed(Duration(milliseconds: 500), () {
            setState(() {
              _revealed[_firstSelected!] = true;
              _revealed[_secondSelected!] = true;
              _resetSelection();
              if (_revealed.every((element) => element)) {
                _speak("🎉 Congratulations! Level $_level completed.");
                _showNextLevelDialog();
              }
            });
          });
        } else {
          Future.delayed(Duration(milliseconds: 700), () {
            _cardKeys[_firstSelected!].currentState?.toggleCard();
            _cardKeys[_secondSelected!].currentState?.toggleCard();
            setState(() {
              _resetSelection();
            });
          });
        }
      }
    });
  }

  void _resetSelection() {
    _firstSelected = null;
    _secondSelected = null;
    _isProcessing = false;
  }

  void _resetGame() {
    _speak("Game restarted! Try again.");
    _level = 1;
    _initializeGame();
  }

  void _nextLevel() {
    _level++;
    _speak("Welcome to Level $_level! Now there are more cards.");
    _initializeGame();
  }

  void _showNextLevelDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Color(0xFF7AB2D3),
        title: Text("🎉 Level $_level Completed! 🎉", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Do you want to continue to the next level?", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18)),
            SizedBox(height: 10),
            Text("🎊 🎈 🎂", style: TextStyle(fontSize: 30)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _nextLevel();
            },
            child: Text("Next Level", style: TextStyle(color: Colors.yellow, fontSize: 18)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            child: Text("Restart", style: TextStyle(color: Colors.red, fontSize: 18)),
          ),
        ],
      ),
    );
  }

  void _speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Memory Match - Level $_level", style: TextStyle(color: Color(0xFF05385C))),
        backgroundColor: Color(0xFF7AB2D3),
        iconTheme: IconThemeData(color: Color(0xFF05385C)),
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Text("Match all the pairs!", style: TextStyle(fontSize: 22, color: Color(0xFF05385C))),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: (_level < 4) ? 4 : 6,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _gameGrid.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _handleCardTap(index),
                    child: FlipCard(
                      key: _cardKeys[index],
                      direction: FlipDirection.HORIZONTAL,
                      flipOnTouch: false,
                      front: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: AssetImage("assets/mystery_box.png"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      back: Container(
                        decoration: BoxDecoration(
                          color: _revealed[index] ? Colors.green : Color(0xFF83C5EC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            _gameGrid[index],
                            style: TextStyle(fontSize: 30, color: _revealed[index] ? Colors.white : Colors.black),
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
            onPressed: _resetGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF7AB2D3),
              foregroundColor: Color(0xFF05385C),
            ),
            child: Text("Restart Game", style: TextStyle(fontSize: 16)),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
