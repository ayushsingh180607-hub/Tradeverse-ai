import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/gemini_service.dart';
import '../models/user_profile.dart';

class AICoachScreen extends StatefulWidget {
  const AICoachScreen({super.key});

  @override
  State<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends State<AICoachScreen> {
  final TextEditingController _queryController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  String _portfolioAdvice = '';
  bool _loadingAdvice = false;

  final List<String> _chips = [
    "What is RSI?",
    "Explain MACD trend",
    "How should I manage stock risk?",
    "Review my portfolio",
  ];

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _getPortfolioAdvice() async {
    final userProfile = Provider.of<UserProfile>(context, listen: false);
    final geminiService = Provider.of<GeminiService>(context, listen: false);

    setState(() {
      _loadingAdvice = true;
    });

    final advice = await geminiService.getPortfolioReview(
      cash: userProfile.cashBalance,
      totalValue: userProfile.getPortfolioValue({'AAPL': 185.40, 'TSLA': 177.90, 'MSFT': 421.20, 'NVDA': 875.12}),
      holdings: userProfile.holdings,
    );

    setState(() {
      _portfolioAdvice = advice;
      _loadingAdvice = false;
    });
  }

  void _sendMessage(String query) async {
    if (query.trim().isEmpty) return;
    final geminiService = Provider.of<GeminiService>(context, listen: false);

    setState(() {
      _messages.add({"sender": "user", "text": query});
      _isLoading = true;
    });
    _queryController.clear();

    final response = await geminiService.askAICoach(query);

    setState(() {
      _messages.add({"sender": "ai", "text": response});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Portfolio Review Section
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF161D28),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1E2533)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(LucideIcons.sparkles, color: Color(0xFF10B981), size: 18),
                      SizedBox(width: 8),
                      Text('AI Coach Portfolio Health Check', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onPressed: _getPortfolioAdvice,
                    icon: _loadingAdvice
                        ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(LucideIcons.play, size: 12),
                    label: const Text('Analyze', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              if (_portfolioAdvice.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1218),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _portfolioAdvice,
                    style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Chat Conversation history
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.bot, size: 48, color: Colors.grey),
                      const SizedBox(height: 10),
                      const Text('Ask your AI Consultant anything about trading strategy!', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        alignment: WrapAlignment.center,
                        children: _chips.map((chip) {
                          return ActionChip(
                            backgroundColor: const Color(0xFF161D28),
                            side: const BorderSide(color: Color(0xFF1E2533)),
                            label: Text(chip, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            onPressed: () => _sendMessage(chip),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isUser = msg["sender"] == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                        decoration: BoxDecoration(
                          color: isUser ? const Color(0xFF10B981) : const Color(0xFF161D28),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: isUser ? const Radius.circular(12) : Radius.zero,
                            bottomRight: isUser ? Radius.zero : const Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          msg["text"] ?? '',
                          style: TextStyle(color: isUser ? Colors.white : Colors.white, fontSize: 14),
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Chat input field
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFF161D28),
            border: Border(top: BorderSide(color: Color(0xFF1E2533))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type financial question or trade logic...',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFF0F1218),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _sendMessage(_queryController.text),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(LucideIcons.send, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
