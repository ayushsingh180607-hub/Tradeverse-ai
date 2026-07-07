class Stock {
  final String symbol;
  final String name;
  double price;
  double changePercent;
  double changeAmount;
  final List<double> history24h;
  final String rsi;
  final String macd;
  final double volume;

  Stock({
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePercent,
    required this.changeAmount,
    required this.history24h,
    required this.rsi,
    required this.macd,
    required this.volume,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      changePercent: (json['changePercent'] as num).toDouble(),
      changeAmount: (json['changeAmount'] as num).toDouble(),
      history24h: List<double>.from(json['history24h'] as List),
      rsi: json['rsi'] as String,
      macd: json['macd'] as String,
      volume: (json['volume'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'price': price,
      'changePercent': changePercent,
      'changeAmount': changeAmount,
      'history24h': history24h,
      'rsi': rsi,
      'macd': macd,
      'volume': volume,
    };
  }
}
