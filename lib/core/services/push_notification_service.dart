import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Realtime Push Notification & Alert Dispatcher.
/// Subscribes to Supabase Realtime broadcast channels for:
/// - Instant Auction High-Bid alerts (Live Boli Floor)
/// - Urgent Payment Inflow & Recovery notifications
/// - Inward Trolley Weighment Arrivals
class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static RealtimeChannel? _auctionChannel;
  static RealtimeChannel? _paymentChannel;

  /// Initializes local alert channels and Android notification channels.
  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);
  }

  /// Subscribes to shop-scoped auction updates.
  static void listenToAuctionBids({
    required String shopId,
    required void Function(Map<String, dynamic> payload) onNewBid,
  }) {
    _auctionChannel?.unsubscribe();
    final client = Supabase.instance.client;

    _auctionChannel = client.channel('auction_stream:$shopId')
      ..onBroadcast(
        event: 'new_bid',
        callback: (payload) {
          onNewBid(payload);
          showLocalNotification(
            id: 101,
            title: 'Live Auction Bid Alert!',
            body: 'New highest bid placed: Rs. ${payload['bid_amount']} / Mann',
          );
        },
      )
      ..subscribe();
  }

  /// Displays immediate head-up notification.
  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'mandi_alerts_channel',
      'Mandi Operational Alerts',
      channelDescription: 'High-priority alerts for auctions, payments, and gate passes',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);
    await _localNotifications.show(id, title, body, notificationDetails);
  }

  /// Cleans up realtime subscriptions.
  static void dispose() {
    _auctionChannel?.unsubscribe();
    _paymentChannel?.unsubscribe();
  }
}
