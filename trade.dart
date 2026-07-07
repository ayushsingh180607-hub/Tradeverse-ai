class Trade {
  final String id;
  final String symbol;
  final String type; // 'BUY' or 'SELL'
  final int shares;
  final double executionPrice;
  final DateTime timestamp;
  final double totalValue;

  Trade({
    required this.id,
    required this.symbol,
    required this.type,
    required this.shares,
    required this.executionPrice,
    required this.timestamp,
    required this.totalValue,
  });

  factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      type: json['type'] as String,
      shares: json['shares'] as int,
      executionPrice: (json['executionPrice'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      totalValue: (json['totalValue'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'type': type,
      'shares': shares,
      'executionPrice': executionPrice,
      'timestamp': timestamp.toIso8601String(),
      'totalValue': totalValue,
    };
  }
}
