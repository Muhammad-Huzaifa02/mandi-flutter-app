import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../data/models/broadcast_campaign_model.dart';
import '../../../data/models/mandi_rate_model.dart';
import '../../../data/services/broadcast_service.dart';
import '../../../data/services/supabase_service.dart';

class BroadcastProvider with ChangeNotifier {
  final _service = BroadcastService.instance;

  String? _shopId;
  bool _isLoading = false;
  bool _isBroadcasting = false;
  double _broadcastProgress = 0.0;
  String _searchQuery = '';
  BroadcastChannel? _channelFilter;

  List<BroadcastCampaign> _campaigns = [];
  List<BroadcastSubscriber> _subscribers = [];

  StreamSubscription<List<Map<String, dynamic>>>? _campaignsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _subscribersSub;

  String? get shopId => _shopId;
  bool get isLoading => _isLoading;
  bool get isBroadcasting => _isBroadcasting;
  double get broadcastProgress => _broadcastProgress;
  String get searchQuery => _searchQuery;
  BroadcastChannel? get channelFilter => _channelFilter;

  List<BroadcastCampaign> get campaigns {
    return _campaigns.where((c) {
      if (_channelFilter != null && c.channel != _channelFilter && c.channel != BroadcastChannel.both) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = c.title.toLowerCase().contains(q);
        final matchBody = c.messageBody.toLowerCase().contains(q);
        return matchTitle || matchBody;
      }
      return true;
    }).toList();
  }

  List<BroadcastSubscriber> get subscribers => List.unmodifiable(_subscribers);

  int get totalCampaigns => _campaigns.length;

  int get totalSentMessages {
    return _campaigns.fold(0, (sum, c) => sum + c.deliveredCount);
  }

  double get overallDeliveryRate {
    final totalRecipients = _campaigns.fold(0, (sum, c) => sum + c.totalRecipients);
    if (totalRecipients <= 0) return 100.0;
    return (totalSentMessages / totalRecipients) * 100.0;
  }

  int get activeSubscribersCount => _subscribers.where((s) => s.isActive).length;

  int get whatsappSubscribersCount =>
      _subscribers.where((s) => s.isActive && (s.platform == BroadcastChannel.whatsapp || s.platform == BroadcastChannel.both)).length;

  int get telegramSubscribersCount =>
      _subscribers.where((s) => s.isActive && (s.platform == BroadcastChannel.telegram || s.platform == BroadcastChannel.both)).length;

  /// Updates shop context from proxy provider
  void updateShop(String? shopId) {
    if (shopId != null && shopId.isNotEmpty) {
      init(shopId);
    }
  }

  /// Initializes provider for active shop
  void init(String shopId) {
    if (_shopId == shopId) return;
    _shopId = shopId;
    _isLoading = true;
    notifyListeners();

    _campaignsSub?.cancel();
    _campaignsSub = SupabaseService.broadcastCampaignsStream(shopId).listen(
      (rows) {
        _campaigns = rows.map((r) => BroadcastCampaign.fromMap(r)).toList();
        _isLoading = false;
        notifyListeners();
      },
      onError: (_) {
        _isLoading = false;
        notifyListeners();
      },
    );

    _subscribersSub?.cancel();
    _subscribersSub = SupabaseService.broadcastSubscribersStream(shopId).listen(
      (rows) {
        _subscribers = rows.map((r) => BroadcastSubscriber.fromMap(r)).toList();
        notifyListeners();
      },
    );
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setChannelFilter(BroadcastChannel? channel) {
    _channelFilter = channel;
    notifyListeners();
  }

  /// Synthesizes formatted Mandi Bhav text bulletin
  String synthesizeMandiRatesBulletin({
    required String marketName,
    required DateTime date,
    required List<MandiCommodityRate> rates,
    String? munshiPhone,
    String? shopName,
    String? customNote,
  }) {
    return _service.generateDailyRatesBulletin(
      marketName: marketName,
      date: date,
      rates: rates,
      munshiPhone: munshiPhone,
      shopName: shopName,
      customNote: customNote,
    );
  }

  /// Creates and saves a new broadcast campaign
  Future<BroadcastCampaign?> createCampaign({
    required String title,
    required BroadcastChannel channel,
    required AudienceType audienceType,
    required TemplateType templateType,
    required String messageBody,
    DateTime? scheduledAt,
  }) async {
    if (_shopId == null) return null;

    final targetSubs = _filterSubscribersByAudience(audienceType, channel);

    final campaign = BroadcastCampaign(
      id: '',
      shopId: _shopId!,
      title: title,
      channel: channel,
      audienceType: audienceType,
      templateType: templateType,
      messageBody: messageBody,
      totalRecipients: targetSubs.length,
      deliveredCount: 0,
      failedCount: 0,
      status: scheduledAt != null ? BroadcastStatus.scheduled : BroadcastStatus.draft,
      scheduledAt: scheduledAt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final id = await SupabaseService.createBroadcastCampaign(campaign.toMap());
    return campaign.copyWith(id: id);
  }

  /// Dispatches campaign immediately to target subscribers
  Future<void> dispatchCampaign(BroadcastCampaign campaign, {String? telegramBotToken}) async {
    _isBroadcasting = true;
    _broadcastProgress = 0.0;
    notifyListeners();

    final targetSubs = _filterSubscribersByAudience(campaign.audienceType, campaign.channel);

    await _service.dispatchCampaignToSubscribers(
      campaign: campaign,
      subscribers: targetSubs,
      telegramBotToken: telegramBotToken,
      onProgress: (current, total) {
        _broadcastProgress = total > 0 ? (current / total) : 1.0;
        notifyListeners();
      },
    );

    _isBroadcasting = false;
    _broadcastProgress = 1.0;
    notifyListeners();
  }

  /// Filters subscriber list by audience and platform
  List<BroadcastSubscriber> _filterSubscribersByAudience(AudienceType audience, BroadcastChannel channel) {
    return _subscribers.where((s) {
      if (!s.isActive) return false;

      // Platform check
      if (channel != BroadcastChannel.both) {
        if (s.platform != channel && s.platform != BroadcastChannel.both) return false;
      }

      // Audience check
      switch (audience) {
        case AudienceType.allFarmers:
          return s.subscriberType == 'farmer' || s.subscriberType == 'all';
        case AudienceType.allBuyers:
          return s.subscriberType == 'buyer' || s.subscriberType == 'miller';
        case AudienceType.commissionAgents:
          return s.subscriberType == 'agent';
        case AudienceType.transporters:
          return s.subscriberType == 'transporter' || s.subscriberType == 'driver';
        case AudienceType.custom:
          return true;
      }
    }).toList();
  }

  /// Launches WhatsApp Web or Native App directly
  Future<bool> launchWhatsAppUrl(String phone, String text) async {
    return await _service.launchWhatsAppUrl(phone, text);
  }

  /// Shares bulletin text directly to Telegram
  Future<bool> launchTelegramShare(String text) async {
    return await _service.launchTelegramShare(text);
  }

  /// Adds a new subscriber to directory
  Future<String> addSubscriber({
    required String name,
    required String phoneOrChatId,
    required BroadcastChannel platform,
    required String subscriberType,
    String notes = '',
  }) async {
    if (_shopId == null) throw Exception('No shop selected');

    final sub = BroadcastSubscriber(
      id: '',
      shopId: _shopId!,
      name: name,
      phoneOrChatId: phoneOrChatId,
      platform: platform,
      subscriberType: subscriberType,
      isActive: true,
      notes: notes,
      createdAt: DateTime.now(),
    );

    final id = await SupabaseService.createBroadcastSubscriber(sub.toMap());
    return id;
  }

  /// Deletes a campaign
  Future<void> deleteCampaign(String id) async {
    if (_shopId == null) return;
    await SupabaseService.deleteBroadcastCampaign(id, _shopId!);
  }

  /// Deletes a subscriber
  Future<void> deleteSubscriber(String id) async {
    if (_shopId == null) return;
    await SupabaseService.deleteBroadcastSubscriber(id, _shopId!);
  }

  @override
  void dispose() {
    _campaignsSub?.cancel();
    _subscribersSub?.cancel();
    super.dispose();
  }
}
