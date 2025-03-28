import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Text Toxicity Detector',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        primaryColor: Colors.blue,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
          surface: const Color(0xFF1E1E1E),
          background: Colors.black,
        ),
      ),
      home: const ToxicityDetector(),
    );
  }
}

class ToxicityDetector extends StatefulWidget {
  const ToxicityDetector({super.key});

  @override
  State<ToxicityDetector> createState() => _ToxicityDetectorState();
}

class _ToxicityDetectorState extends State<ToxicityDetector> {
  final TextEditingController _textController = TextEditingController();
  String _result = '';
  bool _isCheckingToxicity = false;
  bool _isFetchingPost = false;
  double _safetyThreshold = 0.005; // Default value as per the example

  Future<void> _fetchRandomPost() async {
    setState(() {
      _isFetchingPost = true;
    });

    try {
      final random = Random();
      final source = random.nextInt(3); // Choose between 3 different sources

      String content = '';

      switch (source) {
        case 0:
          content = await _fetchFromReddit();
          break;
        case 1:
          content = await _fetchFromQuotes();
          break;
        case 2:
          content = await _fetchFromRandomText();
          break;
      }

      if (content.isNotEmpty) {
        setState(() {
          _textController.text = content;
          _isFetchingPost = false;
        });
      } else {
        throw Exception('No content found from any source');
      }
    } catch (e) {
      setState(() {
        _textController.text = 'Error fetching random content: $e';
        _isFetchingPost = false;
      });
    }
  }

  Future<String> _fetchFromReddit() async {
    final subreddits = [
      'AskReddit',
      'worldnews',
      'funny',
      'gaming',
      'pics',
      'science',
      'technology',
      'news',
      'todayilearned',
      'aww',
      'CasualConversation',
      'Showerthoughts',
      'explainlikeimfive',
      'NoStupidQuestions',
      'relationship_advice',
    ];

    final random = Random();
    final subreddit = subreddits[random.nextInt(subreddits.length)];

    final response = await http.get(
      Uri.parse('https://www.reddit.com/r/$subreddit/hot.json?limit=25'),
      headers: {'User-Agent': 'Flutter/1.0'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final posts = data['data']['children'] as List;

      final textPosts =
          posts.where((post) {
            final postData = post['data'];
            return postData['selftext'] != null &&
                postData['selftext'].toString().isNotEmpty &&
                postData['selftext'].toString().length < 500;
          }).toList();

      if (textPosts.isNotEmpty) {
        final randomPost = textPosts[random.nextInt(textPosts.length)];
        final postData = randomPost['data'];
        final title = postData['title'] as String;
        final text = postData['selftext'] as String;
        return '$title\n\n$text';
      }
    }
    return '';
  }

  Future<String> _fetchFromQuotes() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.quotable.io/random'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['content'] as String;
        final author = data['author'] as String;
        return '"$content"\n\n- $author';
      }
    } catch (e) {
      // If quotes API fails, try backup quotes
      final backupQuotes = [
        '"The only way to do great work is to love what you do." - Steve Jobs',
        '"Be the change you wish to see in the world." - Mahatma Gandhi',
        '"The best way to predict the future is to create it." - Peter Drucker',
        '"Success is not final, failure is not fatal." - Winston Churchill',
        '"The journey of a thousand miles begins with one step." - Lao Tzu',
      ];
      return backupQuotes[Random().nextInt(backupQuotes.length)];
    }
    return '';
  }

  Future<String> _fetchFromRandomText() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.quotable.io/random?tags=technology,history,science',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['content'] as String;
        final author = data['author'] as String;
        return '"$content"\n\n- $author';
      }
    } catch (e) {
      // If random text API fails, use backup content
      final backupContent = [
        'The quick brown fox jumps over the lazy dog.',
        'To be, or not to be, that is the question.',
        'All that glitters is not gold.',
        'A journey of a thousand miles begins with a single step.',
        'The early bird catches the worm.',
      ];
      return backupContent[Random().nextInt(backupContent.length)];
    }
    return '';
  }

  Future<void> _checkToxicity() async {
    if (_textController.text.isEmpty) return;

    setState(() {
      _isCheckingToxicity = true;
      _result = '';
    });

    try {
      // Step 1: Initial request to get event ID
      final initialResponse = await http.post(
        Uri.parse(
          'https://duchaba-friendly-text-moderation.hf.space/call/fetch_toxicity_level',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'data': [_textController.text, _safetyThreshold],
        }),
      );

      if (initialResponse.statusCode != 200) {
        throw Exception(
          'Failed to initiate toxicity check: ${initialResponse.statusCode}',
        );
      }

      final initialData = json.decode(initialResponse.body);
      final eventId = initialData['event_id'];

      // Step 2: Poll for results
      String result = '';
      bool isComplete = false;
      int attempts = 0;
      const maxAttempts = 10;

      while (!isComplete && attempts < maxAttempts) {
        await Future.delayed(const Duration(seconds: 1));

        final resultResponse = await http.get(
          Uri.parse(
            'https://duchaba-friendly-text-moderation.hf.space/call/fetch_toxicity_level/$eventId',
          ),
        );

        if (resultResponse.statusCode == 200) {
          // Parse SSE format
          final lines = resultResponse.body.split('\n');
          for (var line in lines) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6); // Remove 'data: ' prefix
              if (data.startsWith('[')) {
                final jsonData = json.decode(data);
                if (jsonData is List && jsonData.length > 1) {
                  final jsonString = jsonData[1];
                  if (jsonString is String) {
                    final analysis = json.decode(jsonString);
                    final maxValue = analysis['max_value'] as double;
                    final maxKey = analysis['max_key'] as String;
                    final toxicityPercentage = (maxValue * 100).toStringAsFixed(
                      1,
                    );
                    result =
                        'Toxicity Level: $toxicityPercentage%\nType: $maxKey';
                    isComplete = true;
                    break;
                  }
                }
              }
            }
          }
        }
        attempts++;
      }

      if (!isComplete) {
        throw Exception('Timeout waiting for results');
      }

      setState(() {
        _result = result;
        _isCheckingToxicity = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
        _isCheckingToxicity = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Text Toxicity Detector')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textController,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: 'Enter text to check for toxicity...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Safety Threshold: '),
                Expanded(
                  child: Slider(
                    value: _safetyThreshold,
                    min: 0.001,
                    max: 0.1,
                    divisions: 99,
                    label: _safetyThreshold.toStringAsFixed(3),
                    onChanged: (value) {
                      setState(() {
                        _safetyThreshold = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        (_isCheckingToxicity || _isFetchingPost)
                            ? null
                            : _checkToxicity,
                    child:
                        _isCheckingToxicity
                            ? const CircularProgressIndicator()
                            : const Text('Check Toxicity'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        (_isCheckingToxicity || _isFetchingPost)
                            ? null
                            : _fetchRandomPost,
                    child:
                        _isFetchingPost
                            ? const CircularProgressIndicator()
                            : const Text('Random Post'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_result.isNotEmpty) ...[
              const Text(
                'Result:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_result, style: const TextStyle(fontSize: 16)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
