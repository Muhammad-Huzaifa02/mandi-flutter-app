import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/utils/broadcast_report_pdf_generator.dart';
import '../../../data/models/broadcast_campaign_model.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import '../providers/broadcast_provider.dart';
import 'add_subscriber_dialog.dart';
import 'new_broadcast_dialog.dart';

class BroadcastHubPage extends StatefulWidget {
  const BroadcastHubPage({super.key});

  @override
  State<BroadcastHubPage> createState() => _BroadcastHubPageState();
}

class _BroadcastHubPageState extends State<BroadcastHubPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _botTokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shopId = context.read<ShopContextProvider>().currentShopId;
      if (shopId != null) {
        context.read<BroadcastProvider>().init(shopId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _botTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopCtx = context.watch<ShopContextProvider>();
    final broadcastProvider = context.watch<BroadcastProvider>();
    final activeShop = shopCtx.currentShop;
    final isUrdu = AppStrings.isUrdu(context);

    if (activeShop == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.val(context, en: 'Mandi Bhav Broadcast Hub', ur: 'منڈی بھاؤ براڈکاسٹ سنٹر')),
        ),
        body: Center(
          child: Text(AppStrings.val(context, en: 'Please select an active shop', ur: 'براہ کرم فعال دکان منتخب کریں')),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.val(context, en: 'Mandi Bhav Broadcast Hub', ur: 'منڈی بھاؤ براڈکاسٹ سنٹر'),
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: AppStrings.val(context, en: 'Print Distribution Certificate', ur: 'تقسیم سرٹیفکیٹ پرنٹ کریں'),
            onPressed: () {
              if (broadcastProvider.campaigns.isNotEmpty) {
                final latest = broadcastProvider.campaigns.first;
                BroadcastReportPdfGenerator.printBroadcastCampaignReport(
                  shopName: activeShop.name,
                  shopAddress: activeShop.address,
                  campaign: latest,
                  sampleSubscribers: broadcastProvider.subscribers,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppStrings.val(context, en: 'No campaigns to print yet', ur: 'ابھی کوئی مہم پرنٹ کے لیے موجود نہیں')),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: AppStrings.val(context, en: 'Add Subscriber', ur: 'نیا صارف شامل کریں'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const AddSubscriberDialog(),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppStrings.val(context, en: 'Bulletins', ur: 'پیغامات')),
                  if (broadcastProvider.totalCampaigns > 0) ...[
                    const SizedBox(width: 6),
                    Badge(label: Text('${broadcastProvider.totalCampaigns}')),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppStrings.val(context, en: 'Subscribers', ur: 'صارفین')),
                  if (broadcastProvider.activeSubscribersCount > 0) ...[
                    const SizedBox(width: 6),
                    Badge(label: Text('${broadcastProvider.activeSubscribersCount}')),
                  ],
                ],
              ),
            ),
            Tab(text: AppStrings.val(context, en: 'Quick Dispatch & Bot', ur: 'فوری ترسیل و باٹ')),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F6B3C),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.campaign),
        label: Text(AppStrings.val(context, en: 'New Bulletin', ur: 'نیا پیغام')),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const NewBroadcastDialog(),
          );
        },
      ),
      body: Column(
        children: [
          _buildKpiBanner(context, broadcastProvider),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBulletinsTab(context, broadcastProvider, isUrdu),
                _buildSubscribersTab(context, broadcastProvider),
                _buildQuickDispatchTab(context, broadcastProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiBanner(BuildContext context, BroadcastProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          _buildKpiTile(AppStrings.val(context, en: 'Total Sent', ur: 'کل بھیجے گئے'), '${provider.totalSentMessages}', Colors.teal.shade800, Icons.send),
          const SizedBox(width: 8),
          _buildKpiTile(AppStrings.val(context, en: 'Delivery Rate', ur: 'ترسیل شرح'), '${provider.overallDeliveryRate.toStringAsFixed(1)}%', Colors.green.shade800, Icons.verified),
          const SizedBox(width: 8),
          _buildKpiTile(AppStrings.val(context, en: 'WhatsApp Subs', ur: 'واٹس ایپ'), '${provider.whatsappSubscribersCount}', const Color(0xFF25D366), Icons.phone_android),
          const SizedBox(width: 8),
          _buildKpiTile(AppStrings.val(context, en: 'Telegram Subs', ur: 'ٹیلیگرام'), '${provider.telegramSubscribersCount}', const Color(0xFF0088CC), Icons.telegram),
        ],
      ),
    );
  }

  Widget _buildKpiTile(String title, String val, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              val,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletinsTab(BuildContext context, BroadcastProvider provider, bool isUrdu) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.campaigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              AppStrings.val(context, en: 'No Broadcast Bulletins Yet', ur: 'ابھی کوئی پیغام نہیں ہے'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.val(
                context,
                en: 'Create daily rate lists and alerts for farmers and buyers.',
                ur: 'زمینداروں اور خریداروں کے لیے روزانہ ریٹ لسٹ اور پیغامات بنائیں۔',
              ),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.campaigns.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final campaign = provider.campaigns[index];
        final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(campaign.createdAt);

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: campaign.channel == BroadcastChannel.whatsapp
                  ? const Color(0xFFE8F5E9)
                  : (campaign.channel == BroadcastChannel.telegram ? const Color(0xFFE1F5FE) : Colors.teal.shade50),
              child: Icon(
                campaign.channel == BroadcastChannel.whatsapp
                    ? Icons.phone_android
                    : (campaign.channel == BroadcastChannel.telegram ? Icons.telegram : Icons.campaign),
                color: campaign.channel == BroadcastChannel.whatsapp
                    ? Colors.green.shade800
                    : (campaign.channel == BroadcastChannel.telegram ? const Color(0xFF0088CC) : Colors.teal.shade800),
                size: 20,
              ),
            ),
            title: Text(campaign.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
              '${isUrdu ? campaign.channel.labelUr : campaign.channel.labelEn} • $dateStr\n${AppStrings.val(context, en: 'Recipients', ur: 'وصول کنندگان')}: ${campaign.deliveredCount}/${campaign.totalRecipients}',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: Chip(
              label: Text(isUrdu ? campaign.status.labelUr : campaign.status.labelEn, style: const TextStyle(fontSize: 10)),
              backgroundColor: campaign.status == BroadcastStatus.sent ? Colors.green.shade50 : Colors.amber.shade50,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        campaign.messageBody,
                        style: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.share, size: 14),
                          label: Text(
                            AppStrings.val(context, en: 'Share to Telegram', ur: 'ٹیلیگرام پر شیئر کریں'),
                            style: const TextStyle(fontSize: 11),
                          ),
                          onPressed: () => provider.launchTelegramShare(campaign.messageBody),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.phone_android, size: 14),
                          label: Text(
                            AppStrings.val(context, en: 'Send via WhatsApp', ur: 'واٹس ایپ پر بھیجیں'),
                            style: const TextStyle(fontSize: 11),
                          ),
                          onPressed: () => provider.launchWhatsAppUrl('', campaign.messageBody),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubscribersTab(BuildContext context, BroadcastProvider provider) {
    if (provider.subscribers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              AppStrings.val(context, en: 'No Subscribers Found', ur: 'کوئی صارف نہیں ملا'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.val(
                context,
                en: 'Add farmers and grain merchants to broadcast rate lists.',
                ur: 'ریٹ لسٹ نشر کرنے کے لیے زمیندار اور تاجر شامل کریں۔',
              ),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.subscribers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final sub = provider.subscribers[index];

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            dense: true,
            leading: CircleAvatar(
              backgroundColor: sub.platform == BroadcastChannel.whatsapp
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFE1F5FE),
              child: Icon(
                sub.platform == BroadcastChannel.whatsapp ? Icons.phone_android : Icons.telegram,
                color: sub.platform == BroadcastChannel.whatsapp ? Colors.green.shade800 : const Color(0xFF0088CC),
                size: 18,
              ),
            ),
            title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text('${sub.phoneOrChatId} • ${sub.subscriberType.toUpperCase()}', style: const TextStyle(fontSize: 11)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
              onPressed: () => provider.deleteSubscriber(sub.id),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickDispatchTab(BuildContext context, BroadcastProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.val(context, en: 'Instant Broadcast Channels', ur: 'فوری نشریات کے ذرائع'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.val(
              context,
              en: 'Quickly broadcast today\'s Mandi Bhav rates to your WhatsApp groups or Telegram public channel with one tap.',
              ur: 'ایک کلک کے ساتھ آج کے منڈی بھاؤ اپنے واٹس ایپ گروپس یا ٹیلیگرام چینل پر نشر کریں۔',
            ),
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // WhatsApp Action Card
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.phone_android, color: Color(0xFF25D366), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.val(context, en: 'WhatsApp Direct Broadcast', ur: 'واٹس ایپ ڈائریکٹ براڈکاسٹ'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          AppStrings.val(
                            context,
                            en: 'Open WhatsApp Web or Mobile with synthesized rates pre-filled',
                            ur: 'منڈی ریٹس کے ساتھ واٹس ایپ اوپن کریں',
                          ),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
                    onPressed: () {
                      final latest = provider.campaigns.isNotEmpty ? provider.campaigns.first.messageBody : 'Mandi Bhav Rates: Wheat Rs. 4,000/Maund';
                      provider.launchWhatsAppUrl('', latest);
                    },
                    child: Text(AppStrings.val(context, en: 'Open WhatsApp', ur: 'واٹس ایپ کھولیں')),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Telegram Action Card
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFE1F5FE), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.telegram, color: Color(0xFF0088CC), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.val(context, en: 'Telegram Channel Post', ur: 'ٹیلیگرام چینل پوسٹ'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          AppStrings.val(
                            context,
                            en: 'Share rates to public Mandi subscribers channel',
                            ur: 'منڈی کے پبلک چینل پر ریٹ شیئر کریں',
                          ),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0088CC), foregroundColor: Colors.white),
                    onPressed: () {
                      final latest = provider.campaigns.isNotEmpty ? provider.campaigns.first.messageBody : 'Mandi Bhav Rates: Wheat Rs. 4,000/Maund';
                      provider.launchTelegramShare(latest);
                    },
                    child: Text(AppStrings.val(context, en: 'Share to Telegram', ur: 'ٹیلیگرام شیئر کریں')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
