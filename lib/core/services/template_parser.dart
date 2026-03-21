import 'package:intl/intl.dart';

/// Result of parsing an SMS message against a template.
class ParseResult {
  final String? symbol;
  final double? quantity;
  final double? price;
  final double? amount;
  final DateTime? dateTime;
  final bool matched;

  const ParseResult({
    this.symbol,
    this.quantity,
    this.price,
    this.amount,
    this.dateTime,
    this.matched = false,
  });

  /// Convenience for no-match
  static const ParseResult noMatch = ParseResult(matched: false);
}

/// Converts user-friendly template strings with placeholders
/// into regex patterns and parses SMS messages against them.
///
/// Supported placeholders:
///   {{symbol}}   -> Stock ticker symbol
///   {{quantity}} -> Number of shares
///   {{price}}    -> Price per share
///   {{amount}}   -> Fund transfer amount
///   {{date}}     -> Date (e.g., 17-03-2026)
///   {{time}}     -> Time (e.g., 11:41)
///   {{*}}        -> Wildcard (matches any text)
///   {{word}}     -> Matches any single word (no spaces)
class TemplateParser {
  /// The original user template
  final String template;

  /// The generated regex pattern
  late final RegExp _regex;

  /// Whether this template contains a date placeholder
  late final bool hasDate;

  /// Whether this template contains a time placeholder
  late final bool hasTime;

  /// Common date formats to try when parsing {{date}}
  static const List<String> _dateFormats = [
    'dd-MM-yyyy',
    'yyyy-MM-dd',
    'dd/MM/yyyy',
    'MM/dd/yyyy',
    'dd-MM-yy',
    'yyyy/MM/dd',
  ];

  /// Common time formats to try when parsing {{time}}
  static const List<String> _timeFormats = [
    'HH:mm',
    'HH:mm:ss',
    'hh:mm a',
    'hh:mm:ss a',
    'H:mm',
  ];

  TemplateParser(this.template) {
    hasDate = template.contains('{{date}}');
    hasTime = template.contains('{{time}}');
    _regex = _buildRegex(template);
  }

  /// Build a regex from the template string.
  ///
  /// 1. Auto-detect hardcoded dates/times and replace with wildcards
  /// 2. Escape all regex special characters in the literal parts
  /// 3. Replace placeholders with named capture groups
  /// 4. Collapse whitespace into \s+
  static RegExp _buildRegex(String template) {
    // Pre-process: auto-detect hardcoded date/time patterns
    // and replace them with placeholders if user didn't use {{date}}/{{time}}
    String processed = _autoReplaceLiteralDateTimes(template);

    // Map of placeholder -> regex capture group
    const placeholderPatterns = {
      '{{symbol}}': r'(?<symbol>\S+)',
      '{{quantity}}': r'(?<quantity>[\d,.]+)',
      '{{price}}': r'(?<price>[\d,.]+)',
      '{{amount}}': r'(?<amount>[\d,.]+)',
      '{{date}}': r'(?<date>[\d/\-]+)',
      '{{time}}': r'(?<time>[\d:]+\s*[aApPmM]*)',
      '{{*}}': r'.*?',
      '{{word}}': r'\S+',
    };

    // Split the template by placeholders, keeping placeholders as tokens
    final parts = <String>[];
    String remaining = processed;

    while (remaining.isNotEmpty) {
      // Find the next placeholder
      int earliestIndex = remaining.length;
      String? earliestPlaceholder;

      for (final placeholder in placeholderPatterns.keys) {
        final index = remaining.indexOf(placeholder);
        if (index != -1 && index < earliestIndex) {
          earliestIndex = index;
          earliestPlaceholder = placeholder;
        }
      }

      if (earliestPlaceholder != null) {
        // Add the literal part before the placeholder
        if (earliestIndex > 0) {
          parts.add(_escapeRegex(remaining.substring(0, earliestIndex)));
        }
        // Add the capture group for this placeholder
        parts.add(placeholderPatterns[earliestPlaceholder]!);
        remaining =
            remaining.substring(earliestIndex + earliestPlaceholder.length);
      } else {
        // No more placeholders, add the rest as literal
        parts.add(_escapeRegex(remaining));
        remaining = '';
      }
    }

    // Join parts and collapse whitespace
    String pattern = parts.join('');
    // Replace sequences of literal whitespace (escaped or not) with \s+
    pattern = pattern.replaceAll(RegExp(r'(\\ |\s)+'), r'\s+');

    return RegExp(pattern, caseSensitive: false);
  }

  /// Auto-detect hardcoded date and time patterns in the template
  /// and replace them with {{date}} / {{time}} placeholders.
  ///
  /// This allows users to paste a real SMS as a template and only
  /// replace symbol/quantity/price — dates and times are handled
  /// automatically.
  static String _autoReplaceLiteralDateTimes(String template) {
    // Skip if user already used {{date}} or {{time}} placeholders
    bool hasDatePlaceholder = template.contains('{{date}}');
    bool hasTimePlaceholder = template.contains('{{time}}');

    String result = template;

    if (!hasDatePlaceholder) {
      // Match common date formats: dd-MM-yyyy, dd/MM/yyyy, yyyy-MM-dd, etc.
      result = result.replaceFirstMapped(
        RegExp(r'\d{1,4}[/\-]\d{1,2}[/\-]\d{1,4}'),
        (m) => '{{date}}',
      );
    }

    if (!hasTimePlaceholder) {
      // Match common time formats: HH:mm, HH:mm:ss, hh:mm AM/PM
      result = result.replaceFirstMapped(
        RegExp(r'\d{1,2}:\d{2}(?::\d{2})?(?:\s*[aApPmM]{2})?'),
        (m) => '{{time}}',
      );
    }

    return result;
  }

  /// Escape regex special characters in a literal string.
  static String _escapeRegex(String literal) {
    return literal.replaceAllMapped(
      RegExp(r'[.*+?^${}()|[\]\\]'),
      (match) => '\\${match.group(0)}',
    );
  }

  /// Parse an SMS body against this template.
  /// Returns a [ParseResult] with extracted fields.
  ///
  /// If [smsReceivedDate] is provided, it will be used as fallback
  /// when {{date}}/{{time}} placeholders are not in the template.
  ParseResult parse(String smsBody, {DateTime? smsReceivedDate}) {
    final match = _regex.firstMatch(smsBody);
    if (match == null) return ParseResult.noMatch;

    // Extract named groups
    final symbolStr = _tryGroup(match, 'symbol');
    final quantityStr = _tryGroup(match, 'quantity');
    final priceStr = _tryGroup(match, 'price');
    final amountStr = _tryGroup(match, 'amount');
    final dateStr = _tryGroup(match, 'date');
    final timeStr = _tryGroup(match, 'time');

    // Parse numeric values
    final quantity = _parseNumber(quantityStr);
    final price = _parseNumber(priceStr);
    final amount = _parseNumber(amountStr);

    // Parse date/time
    DateTime? dateTime;
    if (dateStr != null || timeStr != null) {
      dateTime = _parseDateTime(dateStr, timeStr, smsReceivedDate);
    }
    dateTime ??= smsReceivedDate;

    return ParseResult(
      symbol: symbolStr,
      quantity: quantity,
      price: price,
      amount: amount,
      dateTime: dateTime,
      matched: true,
    );
  }

  /// Try to get a named group from a match, returning null if not found
  String? _tryGroup(RegExpMatch match, String name) {
    try {
      return match.namedGroup(name);
    } catch (_) {
      return null;
    }
  }

  /// Parse a number string, removing commas
  double? _parseNumber(String? value) {
    if (value == null) return null;
    final cleaned = value.replaceAll(',', '');
    return double.tryParse(cleaned);
  }

  /// Parse date and time strings into a DateTime
  DateTime? _parseDateTime(
    String? dateStr,
    String? timeStr,
    DateTime? fallback,
  ) {
    DateTime? date;

    if (dateStr != null) {
      for (final format in _dateFormats) {
        try {
          date = DateFormat(format).parse(dateStr);
          break;
        } catch (_) {
          continue;
        }
      }
    }

    if (date == null && fallback != null) {
      date = DateTime(fallback.year, fallback.month, fallback.day);
    }

    if (date == null) return null;

    if (timeStr != null) {
      for (final format in _timeFormats) {
        try {
          final time = DateFormat(format).parse(timeStr.trim());
          return DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
            time.second,
          );
        } catch (_) {
          continue;
        }
      }
    }

    // If we have a date but couldn't parse time, use fallback time
    if (fallback != null) {
      return DateTime(
        date.year,
        date.month,
        date.day,
        fallback.hour,
        fallback.minute,
        fallback.second,
      );
    }

    return date;
  }

  /// Get the regex pattern string (for debugging / display)
  String get regexPattern => _regex.pattern;

  /// Test if a message matches this template (without parsing)
  bool matches(String smsBody) => _regex.hasMatch(smsBody);
}
