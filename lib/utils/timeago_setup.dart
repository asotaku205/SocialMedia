// File: lib/utils/timeago_setup.dart
// Utility để setup timeago locales

import 'package:timeago/timeago.dart' as timeago;

class TimeagoSetup {
  static bool _isInitialized = false;

  /// Setup timeago locales cho ứng dụng
  static void initialize() {
    if (_isInitialized) return;

    // Setup Vietnamese locale
    timeago.setLocaleMessages('vi', timeago.ViMessages());
    
    _isInitialized = true;
  }

  /// Format thời gian theo locale hiện tại
  /// [dateTime] - Thời gian cần format
  /// [currentLocale] - Locale hiện tại ('vi' hoặc 'en')
  static String formatTime(DateTime dateTime, String currentLocale) {
    initialize(); // Đảm bảo đã được setup
    
    String locale;
    switch (currentLocale) {
      case 'vi':
        locale = 'vi';
        break;
      default:
        locale = 'en_short';
    }
    
    return timeago.format(dateTime, locale: locale);
  }
}