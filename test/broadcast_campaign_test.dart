import 'package:flutter_test/flutter_test.dart';
import 'package:mandi/core/utils/broadcast_report_pdf_generator.dart';
import 'package:mandi/data/models/broadcast_campaign_model.dart';
import 'package:mandi/data/models/mandi_rate_model.dart';
import 'package:mandi/data/services/broadcast_service.dart';

void main() {
  group('BroadcastCampaign & Telegram Bot Tests', () {
    test('BroadcastChannel, AudienceType, TemplateType parsing', () {
      expect(BroadcastChannel.fromString('whatsapp'), BroadcastChannel.whatsapp);
      expect(BroadcastChannel.fromString('telegram'), BroadcastChannel.telegram);
      expect(BroadcastChannel.fromString('both'), BroadcastChannel.both);

      expect(AudienceType.fromString('all_farmers'), AudienceType.allFarmers);
      expect(AudienceType.fromString('all_buyers'), AudienceType.allBuyers);
      expect(AudienceType.fromString('commission_agents'), AudienceType.commissionAgents);

      expect(TemplateType.fromString('daily_rates'), TemplateType.dailyRates);
      expect(TemplateType.fromString('boli_alert'), TemplateType.boliAlert);
      expect(TemplateType.fromString('khata_reminder'), TemplateType.khataReminder);
    });

    test('Pakistan phone number standardization', () {
      expect(BroadcastCampaign.standardizePakistanPhone('03001234567'), '923001234567');
      expect(BroadcastCampaign.standardizePakistanPhone('0300-1234567'), '923001234567');
      expect(BroadcastCampaign.standardizePakistanPhone('+92 300 1234567'), '923001234567');
      expect(BroadcastCampaign.standardizePakistanPhone('923001234567'), '923001234567');
    });

    test('BroadcastCampaign toMap, fromMap and delivery percentage', () {
      final now = DateTime(2026, 11, 11, 10, 0);
      final campaign = BroadcastCampaign(
        id: 'camp-100',
        shopId: 'shop-200',
        title: 'Morning Rate Board Broadcast',
        channel: BroadcastChannel.both,
        audienceType: AudienceType.allFarmers,
        templateType: TemplateType.dailyRates,
        messageBody: '🌾 گندم ریٹ فی 40 کلو: Rs. 3,900 - 4,100',
        totalRecipients: 50,
        deliveredCount: 45,
        failedCount: 5,
        status: BroadcastStatus.sent,
        createdAt: now,
        updatedAt: now,
      );

      expect(campaign.deliveryRatePercentage, 90.0);

      final map = campaign.toMap();
      expect(map['title'], 'Morning Rate Board Broadcast');
      expect(map['total_recipients'], 50);
      expect(map['delivered_count'], 45);

      final fromMap = BroadcastCampaign.fromMap(map);
      expect(fromMap.id, 'camp-100');
      expect(fromMap.channel, BroadcastChannel.both);
      expect(fromMap.status, BroadcastStatus.sent);
      expect(fromMap.deliveredCount, 45);
    });

    test('BroadcastSubscriber toMap and fromMap', () {
      final now = DateTime(2026, 11, 11, 10, 0);
      final subscriber = BroadcastSubscriber(
        id: 'sub-1',
        shopId: 'shop-200',
        name: 'Chaudhry Bashir',
        phoneOrChatId: '03001234567',
        platform: BroadcastChannel.whatsapp,
        subscriberType: 'farmer',
        notes: 'Chak 45 JB',
        createdAt: now,
      );

      final map = subscriber.toMap();
      expect(map['name'], 'Chaudhry Bashir');
      expect(map['platform'], 'whatsapp');

      final fromMap = BroadcastSubscriber.fromMap(map);
      expect(fromMap.id, 'sub-1');
      expect(fromMap.phoneOrChatId, '03001234567');
      expect(fromMap.isActive, true);
    });

    test('BroadcastService synthesizes formatted Mandi bulletin', () {
      final rate = MandiCommodityRate(
        id: 'rate-1',
        shopId: 'shop-1',
        commodityName: 'گندم (Wheat)',
        variety: 'Faisalabad 2008',
        minRatePerMaund: 3950.0,
        maxRatePerMaund: 4100.0,
        modalRatePerMaund: 4000.0,
        marketTrend: MarketTrend.bullish,
        arrivalsMaunds: 3500.0,
        rateDate: DateTime(2026, 11, 11),
        notes: 'Top quality',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final bulletin = BroadcastService.instance.generateDailyRatesBulletin(
        marketName: 'فیصل آباد غلہ منڈی',
        date: DateTime(2026, 11, 11),
        rates: [rate],
        munshiPhone: '0300-1234567',
        shopName: 'چوہدری غلہ کمیشن شاپ',
      );

      expect(bulletin, contains('غلہ منڈی روزانہ ریٹ لسٹ'));
      expect(bulletin, contains('گندم'));
      expect(bulletin, contains('Rs. 3950 - 4100'));
      expect(bulletin, contains('بولی کے اوقات'));
    });

    test('BroadcastReportPdfGenerator generates non-empty PDF bytes', () async {
      final now = DateTime.now();
      final campaign = BroadcastCampaign(
        id: 'camp-pdf-01',
        shopId: 'shop-1',
        title: 'Daily Mandi Rate Broadcast',
        channel: BroadcastChannel.both,
        audienceType: AudienceType.allFarmers,
        templateType: TemplateType.dailyRates,
        messageBody: 'Wheat Rates: Rs. 4,000 / Maund\nArrivals: 4,000 Maunds',
        totalRecipients: 10,
        deliveredCount: 9,
        failedCount: 1,
        status: BroadcastStatus.sent,
        createdAt: now,
        updatedAt: now,
      );

      final sub = BroadcastSubscriber(
        id: 'sub-1',
        shopId: 'shop-1',
        name: 'Haji Aslam',
        phoneOrChatId: '0301-2345678',
        platform: BroadcastChannel.whatsapp,
        createdAt: now,
      );

      final pdfBytes = await BroadcastReportPdfGenerator.generateBroadcastCampaignPdf(
        shopName: 'Al-Madina Grain Commission',
        shopAddress: 'Ghalla Mandi, Faisalabad',
        campaign: campaign,
        sampleSubscribers: [sub],
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(100));
    });
  });
}
