class UserProfile {
  double cashBalance;
  double initialBalance;
  Map<String, int> holdings; // Symbol -> Quantity
  List<double> portfolioHistory;

  UserProfile({
    required this.cashBalance,
    required this.initialBalance,
    required this.holdings,
    required this.portfolioHistory,
  });

  double getPortfolioValue(Map<String, double> currentPrices) {
    double holdingsValue = 0.0;
    holdings.forEach((symbol, qty) {
      final price = currentPrices[symbol] ?? 0.0;
      holdingsValue += price * qty;
    });
    return cashBalance + holdingsValue;
  }

  factory UserProfile.defaultProfile() {
    return UserProfile(
      cashBalance: 100000.0,
      initialBalance: 100000.0,
      holdings: {
        'AAPL': 15,
        'TSLA': 8,
        'MSFT': 5,
        'NVDA': 20,
      },
      portfolioHistory: [98000, 99500, 101200, 100500, 102400, 103900],
    );
  }
}
