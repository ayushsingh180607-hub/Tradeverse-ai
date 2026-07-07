import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/stock.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  String _searchQuery = '';
  String _filter = 'ALL'; // 'ALL', 'BULLISH', 'BEARISH'

  final List<Stock> _allStocks = [
    Stock(symbol: 'AAPL', name: 'Apple Inc.', price: 185.40, changePercent: 1.2, changeAmount: 2.2, history24h: [], rsi: '54.2', macd: 'Bullish', volume: 54.2),
    Stock(symbol: 'TSLA', name: 'Tesla Inc.', price: 177.90, changePercent: -2.4, changeAmount: -4.3, history24h: [], rsi: '36.8', macd: 'Bearish', volume: 88.5),
    Stock(symbol: 'MSFT', name: 'Microsoft Corp.', price: 421.20, changePercent: 0.8, changeAmount: 3.3, history24h: [], rsi: '62.1', macd: 'Bullish', volume: 22.8),
    Stock(symbol: 'NVDA', name: 'NVIDIA Corp.', price: 875.12, changePercent: 4.8, changeAmount: 40.12, history24h: [], rsi: '74.5', macd: 'Strong Bullish', volume: 110.4),
    Stock(symbol: 'AMZN', name: 'Amazon.com Inc.', price: 180.10, changePercent: -0.5, changeAmount: -0.9, history24h: [], rsi: '48.9', macd: 'Neutral', volume: 38.1),
    Stock(symbol: 'GOOGL', name: 'Alphabet Inc.', price: 152.30, changePercent: 1.7, changeAmount: 2.50, history24h: [], rsi: '58.4', macd: 'Bullish', volume: 26.4),
    Stock(symbol: 'NFLX', name: 'Netflix Inc.', price: 615.50, changePercent: -1.2, changeAmount: -7.40, history24h: [], rsi: '41.2', macd: 'Bearish', volume: 12.9),
    Stock(symbol: 'META', name: 'Meta Platforms Inc.', price: 495.20, changePercent: 2.9, changeAmount: 14.10, history24h: [], rsi: '69.1', macd: 'Strong Bullish', volume: 45.3),
  ];

  @override
  Widget build(BuildContext context) {
    // Filter & Search logic
    final filteredStocks = _allStocks.where((s) {
      final matchesSearch = s.symbol.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.name.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      if (_filter == 'BULLISH') {
        return s.changePercent > 0;
      } else if (_filter == 'BEARISH') {
        return s.changePercent < 0;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF161D28),
              prefixIcon: const Icon(LucideIcons.search, color: Colors.grey, size: 20),
              hintText: 'Search watchlist by symbol or name...',
              hintStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF1E2533)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF10B981)),
              ),
            ),
          ),
        ),

        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              FilterChip(
                selected: _filter == 'ALL',
                label: const Text('All Assets'),
                labelStyle: TextStyle(color: _filter == 'ALL' ? Colors.white : Colors.grey, fontSize: 13),
                selectedColor: const Color(0xFF1E2533),
                backgroundColor: const Color(0xFF161D28),
                onSelected: (val) => setState(() => _filter = 'ALL'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: _filter == 'BULLISH',
                label: const Text('Bullish Trends'),
                labelStyle: TextStyle(color: _filter == 'BULLISH' ? Colors.white : Colors.grey, fontSize: 13),
                selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                backgroundColor: const Color(0xFF161D28),
                onSelected: (val) => setState(() => _filter = 'BULLISH'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: _filter == 'BEARISH',
                label: const Text('Bearish Trends'),
                labelStyle: TextStyle(color: _filter == 'BEARISH' ? Colors.white : Colors.grey, fontSize: 13),
                selectedColor: const Color(0xFFF43F5E).withOpacity(0.2),
                backgroundColor: const Color(0xFF161D28),
                onSelected: (val) => setState(() => _filter = 'BEARISH'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Interactive stock items list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: filteredStocks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final stock = filteredStocks[index];
              final isUp = stock.changePercent >= 0;

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
                    // Asset Info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(stock.symbol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F1218),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                stock.macd,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: stock.macd.contains('Bullish') ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(stock.name, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),

                    // Technicals Overview
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${stock.price.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(isUp ? LucideIcons.trendingUp : LucideIcons.trendingDown, size: 12, color: isUp ? const Color(0xFF10B981) : const Color(0xFFF43F5E)),
                            const SizedBox(width: 4),
                            Text(
                              '${isUp ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isUp ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
