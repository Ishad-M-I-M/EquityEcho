/// Application-wide constants
class AppConstants {
  AppConstants._();

  /// App name
  static const String appName = 'EquityEcho';

  /// Database name
  static const String databaseName = 'equity_echo.db';

  /// Template placeholders
  static const String symbolPlaceholder = '{{symbol}}';
  static const String quantityPlaceholder = '{{quantity}}';
  static const String pricePlaceholder = '{{price}}';
  static const String amountPlaceholder = '{{amount}}';
  static const String datePlaceholder = '{{date}}';
  static const String timePlaceholder = '{{time}}';

  /// All supported placeholders
  static const List<String> allPlaceholders = [
    symbolPlaceholder,
    quantityPlaceholder,
    pricePlaceholder,
    amountPlaceholder,
    datePlaceholder,
    timePlaceholder,
  ];

  /// Placeholder descriptions for UI
  static const Map<String, String> placeholderDescriptions = {
    symbolPlaceholder: 'Stock ticker symbol (e.g., MGT.N0000)',
    quantityPlaceholder: 'Number of shares',
    pricePlaceholder: 'Price per share',
    amountPlaceholder: 'Fund transfer amount',
    datePlaceholder: 'Date (optional, falls back to SMS date)',
    timePlaceholder: 'Time (optional, falls back to SMS time)',
  };
}
