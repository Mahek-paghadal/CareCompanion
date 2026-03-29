import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'memory_match.dart';
import 'number_puzzle.dart';
import 'relaxing_painting.dart';
import 'word_search.dart';
import 'story_puzzle.dart';

void main() {
  runApp(ElderlyGameApp());
}

class ElderlyGameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Elderly Game Hub',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 18),
        ),
      ),
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText speech = stt.SpeechToText();
  bool isListening = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _speak('Welcome to Elderly Game Hub. Say a game name to start.');
  }

  Future<void> _initializeSpeech() async {
    bool available = await speech.initialize();
    if (!available) {
      _speak('Speech recognition not available.');
    }
  }

  void _speak(String text) async {
    await flutterTts.speak(text);
  }

  void _listen() async {
    if (!isListening) {
      bool available = await speech.initialize(
        onStatus: (status) => print('Status: $status'),
        onError: (error) => print('Error: $error'),
      );

      if (available) {
        setState(() => isListening = true);
        speech.listen(onResult: (result) {
          if (result.finalResult) {
            _processCommand(result.recognizedWords.toLowerCase());
          }
        });
      }
    } else {
      setState(() => isListening = false);
      speech.stop();
    }
  }

  void _processCommand(String command) {
    if (command.contains('memory match')) {
      _navigateToGame(MemoryMatchGame(), 'Memory Match');
    } else if (command.contains('number puzzle')) {
      _navigateToGame(NumberPuzzle(), 'Number Puzzle');
    } else if (command.contains('relaxing painting')) {
      _navigateToGame(RelaxingPainting(), 'Relaxing Painting');
    } else if (command.contains('word search')) {
      _navigateToGame(WordSearchGame(), 'Word Search');
    } else if (command.contains('story puzzle')) {
      _navigateToGame(StoryPuzzleGame(), 'Story Puzzle');
    } else {
      _speak('Sorry, I did not understand that.');
    }
  }

  void _navigateToGame(Widget gameScreen, String gameName) {
    _speak('Opening $gameName');
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => gameScreen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Elderly Game Hub', style: TextStyle(
            fontWeight: FontWeight.bold, color: Color(0xFF05385C))),
        backgroundColor: Color(0xFF7AB2D3),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _listen,
        backgroundColor: Color(0xFF7AB2D3),
        child: Icon(
            isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemCount: 5,
          itemBuilder: (context, index) {
            List<Map<String, dynamic>> games = [
              {
                'title': 'Memory Match',
                'image': 'assets/memory_match.png',
                'widget': MemoryMatchGame()
              },
              {
                'title': 'Number Puzzle',
                'image': 'assets/number_puzzle.png',
                'widget': NumberPuzzle()
              },
              {
                'title': 'Relaxing Painting',
                'image': 'assets/relaxing_painting.png',
                'widget': RelaxingPainting()
              },
              {
                'title': 'Word Search',
                'image': 'assets/word_search.png',
                'widget': WordSearchGame()
              },
              {
                'title': 'Story Puzzle',
                'image': 'assets/story_puzzle.png',
                'widget': StoryPuzzleGame()
              },
            ];
            return _gameCard(games[index]['title'], games[index]['image'],
                games[index]['widget']);
          },
        ),
      ),
    );
  }

  Widget _gameCard(String title, String imagePath, Widget gameScreen) {
    return GestureDetector(
      onTap: () => _navigateToGame(gameScreen, title),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        // Apply border radius to all edges
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                // Ensure all edges are rounded
                child: Image.asset(
                  imagePath,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(
                      15)), // Ensure bottom edges are rounded
                ),
                padding: EdgeInsets.all(10),
                alignment: Alignment.center,
                child: Text(
                  title,
                  style: TextStyle(fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF05385C)),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}