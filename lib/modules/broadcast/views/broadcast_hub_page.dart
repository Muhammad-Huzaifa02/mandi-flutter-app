import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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

    if (activeShop == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mandi Bhav Broadcast Hub')),
        body: const Center(child: Text('Please select an active shop')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mandi Bhav Broadcast Hub', style: TextStyle(fontSize: 16)),
            Text('واٹس ایپ اور ٹیلیگرام ریٹ براڈکاسٹ', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print Distribution Certificate',
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
                  const SnackBar(content: Text('No campaigns to print yet')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add Subscriber',
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
                  const Text('Bulletins'),
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
                  const Text('Subscribers'),
                  if (broadcastProvider.activeSubscribersCount > 0) ...[
                    const SizedBox(width: 6),
                    Badge(label: Text('${broadcastProvider.activeSubscribersCount}')),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Quick Dispatch & Bot'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F6B3C),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.campaign),
        label: const Text('New Bulletin (نیا پیغام)'),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const NewBroadcastDialog(),
          );
        },
      ),
      body: Column(
        children: [
          _buildKpiBanner(broadcastProvider),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBulletinsTab(context, broadcastProvider),
                _buildSubscribersTab(context, broadcastProvider),
                _buildQuickDispatchTab(context, broadcastProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiBanner(BroadcastProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          _buildKpiTile('Total Sent', '${provider.totalSentMessages}', Colors.teal.shade800, Icons.send),
          const SizedBox(width: 8),
          _buildKpiTile('Delivery Rate', '${provider.overallDeliveryRate.toStringAsFixed(1)}%', Colors.green.shade800, Icons.verified),
          const SizedBox(width: 8),
          _buildKpiTile('WhatsApp Subs', '${provider.whatsappSubscribersCount}', const Color(0xFF25D366), Icons.phone_android),
          const SizedBox(width: 8),
          _buildKpiTile('Telegram Subs', '${provider.telegramSubscribersCount}', const Color(0xFF0088CC), Icons.telegram),
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

  Widget _buildBulletinsTab(BuildContext context, BroadcastProvider provider) {
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
            const Text('No Broadcast Bulletins Yet', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Create daily rate lists and alerts for farmers and buyers.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
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
              '${campaign.channel.labelEn} • $dateStr\nRecipients: ${campaign.deliveredCount}/${campaign.totalRecipients}',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: Chip(
              label: Text(campaign.status.labelEn, style: const TextStyle(fontSize: 10)),
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
                          label: const Text('Share to Telegram', style: TextStyle(fontSize: 11)),
                          onPressed: () => provider.launchTelegramShare(campaign.messageBody),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.phone_android, size: 14),
                          label: const Text('Send via WhatsApp', style: TextStyle(fontSize: 11)),
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
            const Text('No Subscribers Found', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Add farmers and grain merchants to broadcast rate lists.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
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
          const Text('Instant Broadcast Channels (فوری نشریات)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Text(
            'Quickly broadcast today\'s Mandi Bhav rates to your WhatsApp groups or Telegram public channel with one tap.',
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WhatsApp Direct Broadcast', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Open WhatsApp Web or Mobile with synthesized rates pre-filled', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
                    onPressed: () {
                      final latest = provider.campaigns.isNotEmpty ? provider.campaigns.first.messageBody : 'Mandi Bhav Rates: Wheat Rs. 4,000/Maund';
                      provider.launchWhatsAppUrl('', latest);
                    },
                    child: const Text('Open WhatsApp'),
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Telegram Channel Post', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Share rates to public Mandi subscribers channel', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0088CC), foregroundColor: Colors.white),
                    onPressed: () {
                      final latest = provider.campaigns.isNotEmpty ? provider.campaigns.first.messageBody : 'Mandi Bhav Rates: Wheat Rs. 4,000/Maund';
                      provider.launchTelegramShare(latest);
                    },
                    child: const Text('Share to Telegram'),
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
