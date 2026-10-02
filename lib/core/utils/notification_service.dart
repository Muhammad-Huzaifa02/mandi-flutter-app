import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// On-device local push notification service for Mandi trading alerts.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initializes the local notification plugin for Android & iOS.
  static Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();

      const initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(initializationSettings);
    } catch (_) {}
  }

  /// Triggers a local notification when stock drops below the threshold.
  static Future<void> showLowStockNotification({
    required String productName,
    required double currentStockKg,
  }) async {
    if (kIsWeb) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'low_stock_channel',
        'Low Stock Alerts',
        channelDescription: 'Alerts when product stock reaches minimum levels',
        importance: Importance.high,
        priority: Priority.high,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        '⚠️ Low Stock Alert: $productName',
        '$productName current stock is $currentStockKg KG. Please restock.',
        notificationDetails,
      );
    } catch (_) {}
  }

  /// Triggers a local notification when a new sales invoice is created.
  static Future<void> showInvoiceCreatedNotification({
    required String invoiceNumber,
    required double totalAmount,
  }) async {
    if (kIsWeb) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'invoice_channel',
        'Sales Invoice Alerts',
        channelDescription: 'Notifications for new sales invoices',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        '🧾 Invoice Created: $invoiceNumber',
        'Sales invoice $invoiceNumber for Rs. ${totalAmount.toStringAsFixed(0)} saved successfully.',
        notificationDetails,
      );
    } catch (_) {}
  }
}
