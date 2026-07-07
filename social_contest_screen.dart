import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SocialContestScreen extends StatelessWidget {
  const SocialContestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Simulated Contest Leaderboard Data
    final List<Map<String, dynamic>> leaderboard = [
      {'rank': 1, 'name': 'WarrenBuffettJunior', 'pnl': '+142.50%', 'prize': '\$2,500 Cash'},
      {'rank': 2, 'name': 'BullRunner88', 'pnl': '+89.12%', 'prize': '\$1,000 Cash'},
      {'rank': 3, 'name': 'OptionsGod', 'pnl': '+74.20%', 'prize': '\$500 Cash'},
      {'rank': 4, 'name': 'DiamondHands', 'pnl': '+62.45%', 'prize': 'Trade Pro Badge'},
      {'rank': 5, 'name': 'VanguardSim', 'pnl': '+44.10%', 'prize': 'Trade Pro Badge'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Active Contest Info Card
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF1E2533), const Color(0xFF2C364B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981), width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(6)),
                      child: const Text('LIVE CONTEST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const Row(
                      children: [
                        Icon(LucideIcons.clock, color: Colors.grey, size: 14),
                        SizedBox(width: 4),
                        Text('3d 14h left', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Summer Stock Simulator Championship', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                const Text('Compete with paper-trading users globally. Top 3 highest percentage gainers win real cash rewards.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Your Current Rank: #142', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                      onPressed: () {},
                      child: const Text('Registered'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Leaderboard Ranking List
          const Row(
            children: [
              Icon(LucideIcons.crown, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text('Global Leaderboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leaderboard.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final user = leaderboard[index];
              final isTop3 = user['rank'] <= 3;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161D28),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1E2533)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isTop3 ? Colors.amber.withOpacity(0.2) : const Color(0xFF1E2533),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '#${user['rank']}',
                            style: TextStyle(
                              color: isTop3 ? Colors.amber : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            Text('Prize: ${user['prize']}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      user['pnl'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
