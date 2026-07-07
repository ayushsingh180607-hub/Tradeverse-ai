import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  int _activeQuizQuestion = 0;
  int _totalRiskScore = 0;
  String _quizResult = '';

  final List<Map<String, dynamic>> _quizQuestions = [
    {
      'q': 'How would you respond if your asset portfolio dropped 15% in a week?',
      'opts': [
        {'text': 'Sell immediately to stop losses.', 'score': 1},
        {'text': 'Hold and review indicators.', 'score': 2},
        {'text': 'Buy more at a discount!', 'score': 3}
      ]
    },
    {
      'q': 'What is your primary investment objective?',
      'opts': [
        {'text': 'Capital preservation & safety', 'score': 1},
        {'text': 'Balanced, steady growth', 'score': 2},
        {'text': 'Aggressive capital expansion', 'score': 3}
      ]
    },
    {
      'q': 'What percentage of savings can you allocate to speculative assets?',
      'opts': [
        {'text': 'Less than 5%', 'score': 1},
        {'text': 'Between 5% to 20%', 'score': 2},
        {'text': 'More than 20%', 'score': 3}
      ]
    }
  ];

  final List<Map<String, String>> _flashcards = [
    {'term': 'RSI', 'def': 'Relative Strength Index. A momentum oscillator measuring speed and change of price movements, valued from 0 to 100. >70 is Overbought, <30 is Oversold.'},
    {'term': 'MACD', 'def': 'Moving Average Convergence Divergence. Trend-following momentum indicator displaying relationship between two exponential moving averages.'},
    {'term': 'Spread', 'def': 'The difference between the highest price a buyer is willing to pay (bid) and lowest price a seller is offering (ask).'},
    {'term': 'Short Selling', 'def': 'Borrowing an asset, selling it at market, with plans to buy it back cheaper later when price falls, making a profit.'},
  ];

  int _currentCardIdx = 0;
  bool _isCardFlipped = false;

  void _answerQuestion(int score) {
    _totalRiskScore += score;
    if (_activeQuizQuestion < _quizQuestions.length - 1) {
      setState(() {
        _activeQuizQuestion++;
      });
    } else {
      String category = 'Moderate';
      if (_totalRiskScore <= 4) {
        category = 'Conservative';
      } else if (_totalRiskScore >= 8) {
        category = 'Aggressive / Growth Miner';
      }
      setState(() {
        _quizResult = category;
      });
    }
  }

  void _resetQuiz() {
    setState(() {
      _activeQuizQuestion = 0;
      _totalRiskScore = 0;
      _quizResult = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0E14),
        appBar: const TabBar(
          indicatorColor: Color(0xFF10B981),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'Lessons'),
            Tab(text: 'Risk Quiz'),
            Tab(text: 'Flashcards'),
          ],
        ),
        body: TabBarView(
          children: [
            // Lessons Tab
            ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildLessonCard(
                  '1. Trading Terminology & Mechanics',
                  'Learn how order books work, the difference between market and limit orders, bid-ask spreads, and liquidations.',
                  LucideIcons.bookOpen,
                  '5 Mins',
                ),
                _buildLessonCard(
                  '2. Advanced Technical Oscillators',
                  'Mastering indicators: Relative Strength Index (RSI), MACD crossovers, Moving Averages (EMA, SMA), and Support/Resistance lines.',
                  LucideIcons.activity,
                  '8 Mins',
                ),
                _buildLessonCard(
                  '3. Risk Management & Position Sizing',
                  'Essential risk reduction principles. Never risk more than 1-2% of total capital on a single speculative trade. Set hard Stop Losses.',
                  LucideIcons.shieldAlert,
                  '6 Mins',
                ),
              ],
            ),

            // Risk Appetite Quiz Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _quizResult.isNotEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.award, size: 64, color: Color(0xFF10B981)),
                        const SizedBox(height: 16),
                        const Text('Your Profile Category', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 6),
                        Text(
                          _quizResult,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _quizResult == 'Conservative'
                              ? 'You prefer capital stability. Focus on Blue Chip index stocks, bonds, and minimal speculation.'
                              : _quizResult == 'Moderate'
                                  ? 'Balanced growth. Maintain solid positions in Tech indices while allocating 10% to growth assets.'
                                  : 'Aggressive risk profiling. Comfortable with momentum speculation, high volatility assets, and options trading simulation.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E2533)),
                          onPressed: _resetQuiz,
                          child: const Text('Retake Quiz', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Question ${_activeQuizQuestion + 1}/${_quizQuestions.length}',
                          style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _quizQuestions[_activeQuizQuestion]['q'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 24),
                        ...(_quizQuestions[_activeQuizQuestion]['opts'] as List).map((opt) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF161D28),
                                side: const BorderSide(color: Color(0xFF1E2533)),
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                alignment: Alignment.centerLeft,
                              ),
                              onPressed: () => _answerQuestion(opt['score'] as int),
                              child: Text(
                                opt['text'] as String,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
            ),

            // Flashcards Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isCardFlipped = !_isCardFlipped;
                      });
                    },
                    child: Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: _isCardFlipped ? const Color(0xFF10B981) : const Color(0xFF161D28),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF1E2533), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isCardFlipped ? LucideIcons.eye : LucideIcons.helpCircle,
                            color: Colors.white70,
                            size: 24,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isCardFlipped
                                ? _flashcards[_currentCardIdx]['def']!
                                : _flashcards[_currentCardIdx]['term']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: _isCardFlipped ? 14 : 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (!_isCardFlipped)
                            const Text('Tap to Flip Card', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                        onPressed: _currentCardIdx > 0
                            ? () {
                                setState(() {
                                  _currentCardIdx--;
                                  _isCardFlipped = false;
                                });
                              }
                            : null,
                      ),
                      Text(
                        '${_currentCardIdx + 1}/${_flashcards.length}',
                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.arrowRight, color: Colors.white),
                        onPressed: _currentCardIdx < _flashcards.length - 1
                            ? () {
                                setState(() {
                                  _currentCardIdx++;
                                  _isCardFlipped = false;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonCard(String title, String desc, IconData icon, String duration) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161D28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E2533)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF0F1218), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: const Color(0xFF10B981), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    ),
                    Text(duration, style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
