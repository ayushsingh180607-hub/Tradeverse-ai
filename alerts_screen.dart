import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/firebase_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final TextEditingController _symbolController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String _alertType = 'ABOVE'; // 'ABOVE' or 'BELOW'

  final List<Map<String, String>> _calendarEvents = [
    {'date': 'July 8', 'time': 'Pre-Market', 'symbol': 'TSLA', 'event': 'Q2 Earnings Release', 'impact': 'High'},
    {'date': 'July 10', 'time': '08:30 AM', 'symbol': 'CPI', 'event': 'Inflation Index Report', 'impact': 'Critical'},
    {'date': 'July 14', 'time': 'Post-Market', 'symbol': 'AAPL', 'event': 'Product Feature Announcement', 'impact': 'Medium'},
    {'date': 'July 15', 'time': '02:00 PM', 'symbol': 'FED', 'event': 'Interest Rate FOMC Minutes', 'impact': 'Critical'},
  ];

  @override
  void dispose() {
    _symbolController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _createAlert() async {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    final symbol = _symbolController.text.trim().toUpperCase();
    final price = double.tryParse(_priceController.text) ?? 0.0;

    if (symbol.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid stock symbol and target price.')),
      );
      return;
    }

    await firebaseService.saveAlert(symbol, price, _alertType);
    _symbolController.clear();
    _priceController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF10B981),
        content: Text('Real-time price alert configured and synced with Cloud Firestore!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Create Price Alert Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161D28),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E2533)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.bellRing, color: Color(0xFF10B981), size: 18),
                    SizedBox(width: 8),
                    Text('Create Price Alert', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _symbolController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'AAPL',
                          hintStyle: const TextStyle(color: Colors.grey),
                          labelText: 'Stock Symbol',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFF0F1218),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '185.00',
                          hintStyle: const TextStyle(color: Colors.grey),
                          labelText: 'Trigger Price',
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFF0F1218),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Alert Condition', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    DropdownButton<String>(
                      value: _alertType,
                      dropdownColor: const Color(0xFF1E2533),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      underline: Container(),
                      items: const [
                        DropdownMenuItem(value: 'ABOVE', child: Text('Goes Above (≥)')),
                        DropdownMenuItem(value: 'BELOW', child: Text('Goes Below (≤)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _alertType = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _createAlert,
                  child: const Text('Add Alert Trigger', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Active Price Alerts List
          const Text('Active Price Alerts (Cloud Firestore)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          const SizedBox(height: 8),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: firebaseService.streamAlerts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Card(
                  color: Color(0xFF161D28),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No custom price alerts set yet. Syncing real-time.', style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              final alerts = snapshot.data!;
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: alerts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  final isAbove = alert['type'] == 'ABOVE';

                  return Dismissible(
                    key: Key(alert['id']),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(color: const Color(0xFFF43F5E), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(LucideIcons.trash2, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      firebaseService.deleteAlert(alert['id']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Alert threshold deleted.')),
                      );
                    },
                    child: Container(
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
                              Icon(
                                isAbove ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                                color: isAbove ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(alert['symbol'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                                  Text(isAbove ? 'Trigger when goes above' : 'Trigger when goes below', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            '\$${(alert['targetPrice'] as num).toDouble().toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),

          // Earnings / Economic Calendar
          const Text('Earnings & Economic Calendar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _calendarEvents.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final ev = _calendarEvents[index];
              final isCritical = ev['impact'] == 'Critical';
              final isHigh = ev['impact'] == 'High';

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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFF161D28), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            children: [
                              Text(ev['date']!.split(' ')[0], style: const TextStyle(color: Colors.grey, fontSize: 10)),
                              Text(ev['date']!.split(' ')[1], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${ev['symbol']} - ${ev['event']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            Text(ev['time']!, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCritical
                            ? const Color(0xFFF43F5E).withOpacity(0.2)
                            : isHigh
                                ? Colors.orange.withOpacity(0.2)
                                : Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ev['impact']!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isCritical
                              ? const Color(0xFFF43F5E)
                              : isHigh
                                  ? Colors.orange
                                  : Colors.blue,
                        ),
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
