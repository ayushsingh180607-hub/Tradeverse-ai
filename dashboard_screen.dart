import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'trading_panel_screen.dart';
import 'watchlist_screen.dart';
import 'portfolio_screen.dart';
import 'ai_coach_screen.dart';
import 'learning_screen.dart';
import 'social_contest_screen.dart';
import 'alerts_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _tabs = [
    {
      'title': 'Trade Station',
      'icon': LucideIcons.lineChart,
      'screen': const TradingPanelScreen(),
    },
    {
      'title': 'Watchlist',
      'icon': LucideIcons.eye,
      'screen': const WatchlistScreen(),
    },
    {
      'title': 'Portfolio',
      'icon': LucideIcons.pieChart,
      'screen': const PortfolioScreen(),
    },
    {
      'title': 'AI Coach',
      'icon': LucideIcons.sparkles,
      'screen': const AICoachScreen(),
    },
    {
      'title': 'Alerts',
      'icon': LucideIcons.bell,
      'screen': const AlertsScreen(),
    },
    {
      'title': 'Academy',
      'icon': LucideIcons.graduationCap,
      'screen': const LearningScreen(),
    },
    {
      'title': 'Arena',
      'icon': LucideIcons.trophy,
      'screen': const SocialContestScreen(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final currentTab = _tabs[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1218),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(LucideIcons.barChart2, color: Color(0xFF10B981), size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              'TradeVerse AI',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.user, color: Colors.white, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile synced & authenticated with Firebase Auth!')),
              );
            },
          ),
        ],
      ),
      body: currentTab['screen'] as Widget,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0F1218),
        selectedItemColor: const Color(0xFF10B981),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 8,
        items: _tabs.map((tab) {
          return BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Icon(tab['icon'] as IconData, size: 20),
            ),
            label: tab['title'] as String,
          );
        }).toList(),
      ),
    );
  }
}
