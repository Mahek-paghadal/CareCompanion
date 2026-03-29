import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class RelaxingPainting extends StatefulWidget {
  @override
  _RelaxingPaintingState createState() => _RelaxingPaintingState();
}

class _RelaxingPaintingState extends State<RelaxingPainting> {
  List<Offset?> _points = [];
  Color _selectedColor = Colors.blueAccent;
  double _brushSize = 5.0;
  FlutterTts _flutterTts = FlutterTts();
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speak("Welcome to Relaxing Painting. Say 'clear' to erase or 'change color' to pick a new color.");
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
        print("Speech Recognition Error: $error");
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
      if (command.contains("clear")) {
        setState(() {
          _points.clear();
        });
        _speak("Canvas cleared.");
      } else if (command.contains("change color")) {
        _changeColor();
      }
    });
  }

  void _changeColor() {
    List<Color> colors = [Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple];
    setState(() {
      _selectedColor = colors[(colors.indexOf(_selectedColor) + 1) % colors.length];
    });
    _speak("Color changed.");
  }

  void _clearCanvas() {
    setState(() {
      _points.clear();
    });
    _speak("Canvas cleared.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Relaxing Painting" , style: TextStyle(color: Color(0xFF05385C))),
        backgroundColor: Color(0xFF7AB2D3),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                _points.add(renderBox?.globalToLocal(details.globalPosition));
              });
            },
            onPanEnd: (_) {
              _points.add(null);
            },
            child: CustomPaint(
              painter: _PaintingPainter(_points, _selectedColor, _brushSize),
              size: Size.infinite,
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            child: Row(
              children: [
                FloatingActionButton(
                  backgroundColor: Colors.redAccent,
                  onPressed: _clearCanvas,
                  child: Icon(Icons.delete),
                ),
                SizedBox(width: 15),
                FloatingActionButton(
                  backgroundColor: Colors.blue,
                  onPressed: _changeColor,
                  child: Icon(Icons.palette),
                ),
                SizedBox(width: 15),
                FloatingActionButton(
                  backgroundColor: _isListening ? Colors.green : Colors.grey,
                  onPressed: _listenForCommands,
                  child: Icon(Icons.mic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaintingPainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;
  final double brushSize;

  _PaintingPainter(this.points, this.color, this.brushSize);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = brushSize;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
