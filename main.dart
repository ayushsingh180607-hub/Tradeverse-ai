import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'models/user_profile.dart';
import 'services/firebase_service.dart';
import 'services/gemini_service.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final firebaseService = FirebaseService();
  final geminiService = GeminiService();

  // Initialize the Gemini API key (passed at runtime or injected)
  // To protect keys, we lazy-initialize with placeholders or pull from env if available
  const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  if (geminiApiKey.isNotEmpty) {
    geminiService.initialize(geminiApiKey);
  }

  // Run the app with providers
  runApp(
    MultiProvider(
      providers: [
        Provider<FirebaseService>.value(value: firebaseService),
        Provider<GeminiService>.value(value: geminiService),
        ChangeNotifierProvider<UserProfileProvider>(
          create: (_) => UserProfileProvider(UserProfile.defaultProfile()),
        ),
      ],
      child: const TradeVerseApp(),
    ),
  );
}

// Simple ChangeNotifier wrapper to enable real-time UI rebuilds in Dart/Flutter
class UserProfileProvider extends ChangeNotifier {
  final UserProfile _profile;

  UserProfileProvider(this._profile);

  double get cashBalance => _profile.cashBalance;
  double get initialBalance => _profile.initialBalance;
  Map<String, int> get holdings => _profile.holdings;
  List<double> get portfolioHistory => _profile.portfolioHistory;

  set cashBalance(double val) {
    _profile.cashBalance = val;
    notifyListeners();
  }

  double getPortfolioValue(Map<String, double> currentPrices) {
    return _profile.getPortfolioValue(currentPrices);
  }
}

class TradeVerseApp extends StatelessWidget {
  const TradeVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Custom Slate Dark Theme mimicking high-density dashboard palette
    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B0E14),
      primaryColor: const Color(0xFF10B981),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF10B981),
        secondary: Color(0xFF1E2533),
        surface: Color(0xFF0F1218),
        error: Color(0xFFF43F5E),
      ),
    );

    return MaterialApp(
      title: 'TradeVerse AI',
      debugShowCheckedModeBanner: false,
      theme: darkTheme,
      home: const DashboardScreen(),
    );
  }
}
