/// Trade action types
enum TradeAction {
  buy,
  sell;

  String get label {
    switch (this) {
      case TradeAction.buy:
        return 'BUY';
      case TradeAction.sell:
        return 'SELL';
    }
  }
}

/// Fund transfer action types
enum FundAction {
  deposit,
  withdrawal,
  ipoDeposit;

  String get label {
    switch (this) {
      case FundAction.deposit:
        return 'Deposit';
      case FundAction.withdrawal:
        return 'Withdrawal';
      case FundAction.ipoDeposit:
        return 'IPO Deposit';
    }
  }
}
