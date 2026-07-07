import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user_profile.dart';
import '../models/trade.dart';
import '../services/firebase_service.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<UserProfile>(context);
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);

    // Mock stock prices for calculation
    final mockPrices = {
      'AAPL': 185.40,
      'TSLA': 177.90,
      'MSFT': 421.20,
      'NVDA': 875.12,
    };

    final double totalNetWorth = userProfile.getPortfolioValue(mockPrices);
    final double totalGainLoss = totalNetWorth - userProfile.initialBalance;
    final double gainLossPct = (totalGainLoss / userProfile.initialBalance) * 100.0;
    final bool isProfit = totalGainLoss >= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Total Net Worth Summary Card
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF161D28), const Color(0xFF1E2533)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2C364B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Portfolio Valuation', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  '\$${totalNetWorth.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isProfit ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                      color: isProfit ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isProfit ? '+' : ''}\$${totalGainLoss.toStringAsFixed(2)} (${gainLossPct.toStringAsFixed(2)}% all-time)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isProfit ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Portfolio Line Chart
          const Text('Performance History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          const SizedBox(height: 8),
          Container(
            height: 180,
            padding: const EdgeInsets.only(right: 20, top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF161D28),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E2533)),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: const Color(0xFF1E2533),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'P${value.toInt()}',
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: userProfile.portfolioHistory.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value);
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFF10B981),
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF10B981).withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // User Holdings List
          const Text('Your Asset Holdings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          const SizedBox(height: 8),
          if (userProfile.holdings.isEmpty)
            const Card(
              color: Color(0xFF161D28),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No holding assets. Submit order in Trading Panel to buy stocks.', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: userProfile.holdings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = userProfile.holdings.entries.elementAt(index);
                final symbol = entry.key;
                final qty = entry.value;
                final price = mockPrices[symbol] ?? 0.0;
                final valuation = price * qty;

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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2533),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.landmark, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(symbol, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              Text('$qty shares', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('\$${valuation.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('Avg. \$${price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 16),

          // Real-time Cloud Transaction Logs Stream
          const Text('Transaction History (Cloud Firestore)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          const SizedBox(height: 8),
          StreamBuilder<List<Trade>>(
            stream: firebaseService.streamTrades(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Card(
                  color: Color(0xFF161D28),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No trades executed yet. Logs will be synced with Cloud Firestore real-time.', style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              final trades = snapshot.data!;
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: trades.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final trade = trades[index];
                  final isBuy = trade.type == 'BUY';

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1218),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF1E2533)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isBuy ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft,
                              color: isBuy ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${trade.type} ${trade.symbol}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                Text('${trade.shares} shares', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${trade.totalValue.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              '${trade.timestamp.hour}:${trade.timestamp.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
