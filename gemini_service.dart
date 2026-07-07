import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  GenerativeModel? _model;

  // Initialize the Generative Model with API Key
  void initialize(String apiKey) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  bool get isInitialized => _model != null;

  // Generate customized AI Coach feedback
  Future<String> askAICoach(String prompt) async {
    if (_model == null) {
      return "Gemini API key is missing. Please set your GEMINI_API_KEY to activate your AI Trading Coach.";
    }

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text ?? "The coach was quiet. Try again.";
    } catch (e) {
      return "Failed to contact your AI Coach: ${e.toString()}";
    }
  }

  // Get portfolio health advice
  Future<String> getPortfolioReview({
    required double cash,
    required double totalValue,
    required Map<String, int> holdings,
  }) async {
    final holdingsStr = holdings.entries
        .map((e) => "- ${e.key}: ${e.value} shares")
        .join("\n");

    final systemPrompt = """
You are TradeVerse's AI Investment Coach. You are a professional financial advisor specializing in risk management, portfolio balance, and behavioral finance.
Analyze this paper-trading user's portfolio and provide extremely concise, actionable recommendations:
Cash Balance: \$${cash.toStringAsFixed(2)}
Total Net Worth: \$${totalValue.toStringAsFixed(2)}
Current Holdings:
$holdingsStr

Structure your feedback with the following headings:
- 📊 **Risk Assessment**: (Explain asset allocation risk, sector concentrations)
- 💡 **Action Plan**: (Recommend what to buy or sell to optimize returns)
- 🎯 **Behavioral Advice**: (Give mental training for market fluctuations)
Keep the advice brief, professional, and visually formatted with bullet points.
""";

    return await askAICoach(systemPrompt);
  }
}
