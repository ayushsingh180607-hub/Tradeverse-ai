import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/stock.dart';
import '../models/trade.dart';
import '../models/user_profile.dart';
import '../services/firebase_service.dart';

class TradingPanelScreen extends StatefulWidget {
  const TradingPanelScreen({super.key});

  @override
  State<TradingPanelScreen> createState() => _TradingPanelScreenState();
}

class _TradingPanelScreenState extends State<TradingPanelScreen> {
  final _random = Random();
  Timer? _priceTimer;
  String _selectedSymbol = 'AAPL';
  final TextEditingController _sharesController = TextEditingController(text: '10');
  String _orderType = 'BUY'; // 'BUY' or 'SELL'
  
  // Local list of active simulated stocks
  final List<Stock> _stocks = [
    Stock(symbol: 'AAPL', name: 'Apple Inc.', price: 185.40, changePercent: 1.2, changeAmount: 2.2, history24h: [183.0, 184.2, 183.9, 185.1, 185.40], rsi: '54.2', macd: 'Bullish', volume: 54.2),
    Stock(symbol: 'TSLA', name: 'Tesla Inc.', price: 177.90, changePercent: -2.4, changeAmount: -4.3, history24h: [182.0, 180.5, 179.1, 178.2, 177.90], rsi: '36.8', macd: 'Bearish', volume: 88.5),
    Stock(symbol: 'MSFT', name: 'Microsoft Corp.', price: 421.20, changePercent: 0.8, changeAmount: 3.3, history24h: [418.0, 419.5, 420.1, 420.5, 421.20], rsi: '62.1', macd: 'Bullish', volume: 22.8),
    Stock(symbol: 'NVDA', name: 'NVIDIA Corp.', price: 875.12, changePercent: 4.8, changeAmount: 40.12, history24h: [835.0, 848.0, 855.0, 868.0, 875.12], rsi: '74.5', macd: 'Strong Bullish', volume: 110.4),
    Stock(symbol: 'AMZN', name: 'Amazon.com Inc.', price: 180.10, changePercent: -0.5, changeAmount: -0.9, history24h: [181.0, 180.8, 179.5, 180.2, 180.10], rsi: '48.9', macd: 'Neutral', volume: 38.1),
  ];

  @override
  void initState() {
    super.initState();
    // Simulate real-time stock ticks every 3 seconds
    _priceTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      setState(() {
        for (var stock in _stocks) {
          final pct = (_random.nextDouble() * 0.8 - 0.4) / 100.0; // -0.4% to +0.4%
          final delta = stock.price * pct;
          stock.price += delta;
          stock.changeAmount += delta;
          stock.changePercent = (stock.changeAmount / (stock.price - stock.changeAmount)) * 100.0;
          stock.history24h.removeAt(0);
          stock.history24h.add(stock.price);
        }
      });
    });
  }

  @override
  void dispose() {
    _priceTimer?.cancel();
    _sharesController.dispose();
    super.dispose();
  }

  Stock get _selectedStock => _stocks.firstWhere((s) => s.symbol == _selectedSymbol);

  void _executeTrade() async {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    final userProfile = Provider.of<UserProfile>(context, listen: false);
    final stock = _selectedStock;

    final shares = int.tryParse(_sharesController.text) ?? 0;
    if (shares <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number of shares.')),
      );
      return;
    }

    final totalCost = stock.price * shares;

    if (_orderType == 'BUY') {
      if (userProfile.cashBalance < totalCost) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Insufficient cash balance! Need \$${totalCost.toStringAsFixed(2)}')),
        );
        return;
      }
      userProfile.cashBalance -= totalCost;
      userProfile.holdings[stock.symbol] = (userProfile.holdings[stock.symbol] ?? 0) + shares;
    } else {
      final currentHoldings = userProfile.holdings[stock.symbol] ?? 0;
      if (currentHoldings < shares) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Insufficient shares to sell! You hold $currentHoldings shares.')),
        );
        return;
      }
      userProfile.cashBalance += totalCost;
      userProfile.holdings[stock.symbol] = currentHoldings - shares;
      if (userProfile.holdings[stock.symbol] == 0) {
        userProfile.holdings.remove(stock.symbol);
      }
    }

    final trade = Trade(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      symbol: stock.symbol,
      type: _orderType,
      shares: shares,
      executionPrice: stock.price,
      timestamp: DateTime.now(),
      totalValue: totalCost,
    );

    // Save trade using Firestore
    await firebaseService.saveTrade(trade);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        content: Text('Order executed: $_orderType $shares shares of ${stock.symbol} successfully!'),
      ),
    );
    
    // Refresh parent state
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<UserProfile>(context);
    final stock = _selectedStock;
    final isBullish = stock.changePercent >= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Simulated Cash Card
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF161D28),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E2533)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Available Paper Cash', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      '\$${userProfile.cashBalance.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                const Icon(LucideIcons.wallet, color: Color(0xFF10B981), size: 28),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Stock Selection & Live Market List
          const Text('Market Ticker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          const SizedBox(height: 6),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _stocks.length,
              itemBuilder: (context, index) {
                final s = _stocks[index];
                final isSelected = s.symbol == _selectedSymbol;
                final isUp = s.changePercent >= 0;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSymbol = s.symbol;
                    });
                  },
                  child: Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 10, bottom: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1E2533) : const Color(0xFF161D28),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF10B981) : const Color(0xFF1E2533),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(s.symbol, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            Icon(isUp ? LucideIcons.trendingUp : LucideIcons.trendingDown, 
                                 size: 14, 
                                 color: isUp ? const Color(0xFF10B981) : const Color(0xFFF43F5E)),
                          ],
                        ),
                        Text('\$${s.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(
                          '${isUp ? '+' : ''}${s.changePercent.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: isUp ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Order Placement Section
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF161D28),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E2533)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${stock.symbol} - ${stock.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text('\$${stock.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(width: 8),
                            Text(
                              '${isBullish ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                              style: TextStyle(color: isBullish ? const Color(0xFF10B981) : const Color(0xFFF43F5E), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Indicator badges
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2533),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('RSI: ${stock.rsi}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF1E2533), height: 24),

                // Order side selection (Buy / Sell)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orderType == 'BUY' ? const Color(0xFF10B981) : const Color(0xFF1E2533),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => setState(() => _orderType = 'BUY'),
                        child: const Text('Buy / Long'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orderType == 'SELL' ? const Color(0xFFF43F5E) : const Color(0xFF1E2533),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => setState(() => _orderType = 'SELL'),
                        child: const Text('Sell / Short'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Share count field
                const Text('Shares Quantity', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _sharesController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (val) => setState(() {}),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF0F1218),
                    hintText: 'Enter shares...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E2533))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF10B981))),
                  ),
                ),
                const SizedBox(height: 16),

                // Pricing Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estimated Order Cost', style: TextStyle(color: Colors.grey)),
                    Text(
                      '\$${(stock.price * (double.tryParse(_sharesController.text) ?? 0.0)).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orderType == 'BUY' ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _executeTrade,
                  child: Text('Submit Trade Order', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
