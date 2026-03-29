// pubspec.yaml dependencies:
// http: ^0.13.4
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const ChatApp());

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _controller.clear();

    final reply = await DeepSeekService.sendMessage(text);

    setState(() {
      _messages.add({'role': 'bot', 'content': reply});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final suggested = [
      "I need help with my medication",
      "Call my family",
      "What should I eat today?",
      "Remind me to take a walk",
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Elderly Helper Chatbot')),
      body: Column(
        children: [
          Wrap(
            children: suggested.map((msg) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ActionChip(
                  label: Text(msg),
                  onPressed: () => _sendMessage(msg),
                ),
              );
            }).toList(),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(msg['content']!),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ask something...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _sendMessage(_controller.text),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class DeepSeekService {
  static const String _apiKey = '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';
  static const String _url = 'https://openrouter.ai/api/v1/chat/completions'; // ✅ FIXED

  static Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://yourapp.com', // Optional but recommended by OpenRouter
          'X-Title': 'Elderly Helper Chatbot'     // Optional: Your app name
        },
        body: jsonEncode({
          "model": "deepseek/deepseek-chat",
          "messages": [
            {"role": "user", "content": message}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        return "Error: ${response.statusCode}\n${response.body}";
      }
    } catch (e) {
      return "Failed to connect: $e";
    }
  }
}
