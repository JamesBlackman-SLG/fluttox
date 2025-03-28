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
  double _safetyThreshold = 0.005;
  List<List<GridCell>> _grid = [];
  bool _gameInitialized = false;

  // Static list of phrases for the game (64 total)
  final List<String> _gamePhrases = [
    // Toxic phrases (20% = 13 phrases)
    "FUCK OFF AND DIE!!!!!",
    "I HATE YOU SO MUCH!!!!",
    "YOU'RE A WORTHLESS PIECE OF S**T!!!!",
    "GO TO HELL AND DIE!!!!",
    "YOU MAKE ME SICK!!!!",
    "I WISH YOU WERE DEAD!!!!",
    "YOU'RE A DISGUSTING HUMAN!!!!",
    "I HOPE YOU SUFFER!!!!",
    "YOU DESERVE TO DIE!!!!",
    "YOU'RE A WASTE OF LIFE!!!!",
    "I WANT YOU TO DIE!!!!",
    "YOU'RE PATHETIC!!!!",
    "YOU'RE A HORRIBLE PERSON!!!!",
    // Non-toxic phrases (80% = 51 phrases)
    "The sun is shining brightly today.",
    "I love spending time with my family.",
    "Learning new things is exciting!",
    "Music makes everything better.",
    "Nature is beautiful and peaceful.",
    "Friendship is a precious gift.",
    "Smiling can brighten someone's day.",
    "Kindness goes a long way.",
    "Dreams give us hope for tomorrow.",
    "Laughter is the best medicine.",
    "Reading opens new worlds.",
    "Art expresses the soul.",
    "Science helps us understand life.",
    "Travel broadens our horizons.",
    "Exercise keeps us healthy.",
    "Good food brings people together.",
    "Pets bring joy to our lives.",
    "Books are windows to the world.",
    "Gardening is therapeutic.",
    "Photography captures moments.",
    "The weather is changing.",
    "Time flies when you're busy.",
    "Change is inevitable.",
    "Life goes on.",
    "Every day is different.",
    "The world keeps turning.",
    "Seasons come and go.",
    "Time waits for no one.",
    "Change is constant.",
    "Life has its ups and downs.",
    "The future is uncertain.",
    "Time marches on.",
    "Change brings growth.",
    "Life is unpredictable.",
    "The world is vast.",
    "Time heals all wounds.",
    "Change is necessary.",
    "Life is what you make it.",
    "The world is complex.",
    "Time tells all.",
    "Learning is a lifelong journey.",
    "Success comes with effort.",
    "Patience is a virtue.",
    "Wisdom comes with age.",
    "Experience teaches lessons.",
    "Growth takes time.",
    "Understanding brings peace.",
    "Knowledge is power.",
    "Effort leads to results.",
    "Time reveals truth.",
  ];

  @override
  void initState() {
    super.initState();
    _initializeGrid();
  }

  void _initializeGrid() {
    _grid = List.generate(8, (i) => List.generate(8, (j) => GridCell()));
    _gameInitialized = false;
  }

  Future<void> _startGame() async {
    setState(() {
      _isFetchingPost = true;
    });

    try {
      // Create a list of indices for toxic phrases (5 ships: 4, 3, 3, 2, 2 blocks)
      final toxicIndices = <int>[];

      // Ship 1: 4 blocks (horizontal)
      final ship1Start = Random().nextInt(8) * 8 + Random().nextInt(5);
      for (int i = 0; i < 4; i++) {
        toxicIndices.add(ship1Start + i);
      }

      // Ship 2: 3 blocks (vertical)
      int ship2Start;
      do {
        ship2Start = Random().nextInt(6) * 8 + Random().nextInt(8);
      } while (toxicIndices.contains(ship2Start) ||
          toxicIndices.contains(ship2Start + 8) ||
          toxicIndices.contains(ship2Start + 16));
      toxicIndices.addAll([ship2Start, ship2Start + 8, ship2Start + 16]);

      // Ship 3: 3 blocks (horizontal)
      int ship3Start;
      do {
        ship3Start = Random().nextInt(8) * 8 + Random().nextInt(6);
      } while (toxicIndices.contains(ship3Start) ||
          toxicIndices.contains(ship3Start + 1) ||
          toxicIndices.contains(ship3Start + 2));
      toxicIndices.addAll([ship3Start, ship3Start + 1, ship3Start + 2]);

      // Ship 4: 2 blocks (vertical)
      int ship4Start;
      do {
        ship4Start = Random().nextInt(7) * 8 + Random().nextInt(8);
      } while (toxicIndices.contains(ship4Start) ||
          toxicIndices.contains(ship4Start + 8));
      toxicIndices.addAll([ship4Start, ship4Start + 8]);

      // Ship 5: 2 blocks (horizontal)
      int ship5Start;
      do {
        ship5Start = Random().nextInt(8) * 8 + Random().nextInt(7);
      } while (toxicIndices.contains(ship5Start) ||
          toxicIndices.contains(ship5Start + 1));
      toxicIndices.addAll([ship5Start, ship5Start + 1]);

      // Create a list of non-toxic indices
      final nonToxicIndices =
          List.generate(
            64,
            (i) => i,
          ).where((i) => !toxicIndices.contains(i)).toList();

      // Shuffle both lists
      nonToxicIndices.shuffle(Random());

      // Place phrases on the grid
      for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) {
          final index = i * 8 + j;
          final isToxic = toxicIndices.contains(index);
          final content =
              isToxic
                  ? _gamePhrases[toxicIndices.indexOf(index)]
                  : _gamePhrases[13 + nonToxicIndices.indexOf(index)];

          setState(() {
            _grid[i][j] = GridCell(
              content: content,
              toxicity:
                  isToxic
                      ? 1.0
                      : 0.0, // Set initial toxicity based on placement
              isRevealed: false,
            );
          });
        }
      }

      setState(() {
        _gameInitialized = true;
        _isFetchingPost = false;
      });
    } catch (e) {
      setState(() {
        _isFetchingPost = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error initializing game: $e')));
    }
  }

  Future<double> _checkToxicityForContent(String content) async {
    try {
      final initialResponse = await http.post(
        Uri.parse(
          'https://duchaba-friendly-text-moderation.hf.space/call/fetch_toxicity_level',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'data': [content, _safetyThreshold],
        }),
      );

      if (initialResponse.statusCode != 200) {
        throw Exception(
          'Failed to check toxicity: ${initialResponse.statusCode}',
        );
      }

      final initialData = json.decode(initialResponse.body);
      final eventId = initialData['event_id'];

      int attempts = 0;
      while (attempts < 10) {
        await Future.delayed(const Duration(seconds: 1));

        final resultResponse = await http.get(
          Uri.parse(
            'https://duchaba-friendly-text-moderation.hf.space/call/fetch_toxicity_level/$eventId',
          ),
        );

        if (resultResponse.statusCode == 200) {
          final lines = resultResponse.body.split('\n');
          for (var line in lines) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6);
              if (data.startsWith('[')) {
                final jsonData = json.decode(data);
                if (jsonData is List && jsonData.length > 1) {
                  final jsonString = jsonData[1];
                  if (jsonString is String) {
                    final analysis = json.decode(jsonString);
                    return analysis['max_value'] as double;
                  }
                }
              }
            }
          }
        }
        attempts++;
      }
      throw Exception('Timeout checking toxicity');
    } catch (e) {
      return 0.0; // Default to non-toxic on error
    }
  }

  void _revealCell(int row, int col) async {
    if (!_gameInitialized) return;

    // First reveal the content and show loading state
    setState(() {
      _grid[row][col] = _grid[row][col].copyWith(
        isRevealed: true,
        isChecking: true,
      );
    });

    try {
      // Check toxicity using API
      final toxicity = await _checkToxicityForContent(_grid[row][col].content);

      setState(() {
        _grid[row][col] = _grid[row][col].copyWith(
          toxicity: toxicity,
          isChecking: false,
        );
      });
    } catch (e) {
      setState(() {
        _grid[row][col] = _grid[row][col].copyWith(
          toxicity: 0.0, // Default to non-toxic on error
          isChecking: false,
        );
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error checking toxicity: $e')));
    }
  }

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
      appBar: AppBar(
        title: const Text('Text Toxicity Detector'),
        actions:
            _gameInitialized
                ? [
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () {
                      // Reveal all unrevealed cells
                      for (int i = 0; i < 8; i++) {
                        for (int j = 0; j < 8; j++) {
                          if (!_grid[i][j].isRevealed) {
                            _revealCell(i, j);
                          }
                        }
                      }
                    },
                    tooltip: 'Reveal All',
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      setState(() {
                        _gameInitialized = false;
                        _initializeGrid();
                      });
                    },
                    tooltip: 'New Game',
                  ),
                ]
                : null,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_gameInitialized) ...[
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
                const SizedBox(height: 32),
              ],
              const Text(
                'Toxic Text Battleship',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (!_gameInitialized)
                ElevatedButton(
                  onPressed: _isFetchingPost ? null : _startGame,
                  child:
                      _isFetchingPost
                          ? const CircularProgressIndicator()
                          : const Text('Start Game'),
                ),
              const SizedBox(height: 16),
              if (_gameInitialized)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    childAspectRatio: 1,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: 64,
                  itemBuilder: (context, index) {
                    final row = index ~/ 8;
                    final col = index % 8;
                    final cell = _grid[row][col];
                    return GestureDetector(
                      onTap: () => _revealCell(row, col),
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              cell.isRevealed
                                  ? (cell.isChecking
                                      ? Colors.grey[600]
                                      : (cell.toxicity > 0.5
                                          ? Colors.red
                                          : Colors.lightBlue))
                                  : Colors.grey[800],
                          border: Border.all(color: Colors.white24),
                        ),
                        child:
                            cell.isRevealed
                                ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Text(
                                          cell.content,
                                          style: const TextStyle(fontSize: 8),
                                          textAlign: TextAlign.center,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    if (cell.isChecking)
                                      const Padding(
                                        padding: EdgeInsets.only(bottom: 4.0),
                                        child: SizedBox(
                                          height: 12,
                                          width: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    else
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4.0,
                                        ),
                                        child: Text(
                                          '${(cell.toxicity * 100).toStringAsFixed(1)}%',
                                          style: const TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                )
                                : null,
                      ),
                    );
                  },
                ),
            ],
          ),
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

class GridCell {
  final String content;
  final double toxicity;
  final bool isRevealed;
  final bool isChecking;

  GridCell({
    this.content = '',
    this.toxicity = 0.0,
    this.isRevealed = false,
    this.isChecking = false,
  });

  GridCell copyWith({
    String? content,
    double? toxicity,
    bool? isRevealed,
    bool? isChecking,
  }) {
    return GridCell(
      content: content ?? this.content,
      toxicity: toxicity ?? this.toxicity,
      isRevealed: isRevealed ?? this.isRevealed,
      isChecking: isChecking ?? this.isChecking,
    );
  }
}
