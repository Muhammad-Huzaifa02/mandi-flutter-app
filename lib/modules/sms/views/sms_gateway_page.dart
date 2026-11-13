import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/localization/app_strings.dart';
import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/widgets/glass_card.dart';
import 'package:mandi/data/models/sms_gateway_model.dart';
import 'package:mandi/providers/shop_context_provider.dart';
import 'package:mandi/modules/sms/providers/sms_provider.dart';
import 'package:mandi/modules/sms/views/send_quick_sms_dialog.dart';

/// Central management console for Mandi automated SMS gateway configuration,
/// event-driven dispatch triggers, and telecom delivery receipt logs.
class SmsGatewayPage extends StatefulWidget {
  const SmsGatewayPage({super.key});

  @override
  State<SmsGatewayPage> createState() => _SmsGatewayPageState();
}

class _SmsGatewayPageState extends State<SmsGatewayPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Form controllers for settings
  late final TextEditingController _senderIdController;
  late final TextEditingController _accountSidController;
  late final TextEditingController _apiSecretController;
  late final TextEditingController _fromNumberController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _webhookUrlController;
  late final TextEditingController _payloadTemplateController;

  SmsProviderType _selectedProvider = SmsProviderType.mock;
  String _httpMethod = 'POST';
  bool _isEnabled = false;
  bool _autoInvoice = true;
  bool _autoPayment = true;
  bool _autoBoli = false;
  bool _autoWeighbridge = false;
  bool _autoAdvance = false;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _senderIdController = TextEditingController();
    _accountSidController = TextEditingController();
    _apiSecretController = TextEditingController();
    _fromNumberController = TextEditingController();
    _apiKeyController = TextEditingController();
    _webhookUrlController = TextEditingController();
    _payloadTemplateController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final smsProvider = context.read<SmsProvider>();
      _syncFormWithSettings(smsProvider.settings);
      _initialized = true;
    }
  }

  void _syncFormWithSettings(SmsGatewaySettings settings) {
    _isEnabled = settings.isEnabled;
    _selectedProvider = settings.provider;
    _senderIdController.text = settings.senderId;
    _accountSidController.text = settings.accountSid;
    _apiSecretController.text = settings.apiSecret;
    _fromNumberController.text = settings.fromNumber;
    _apiKeyController.text = settings.apiKey;
    _webhookUrlController.text = settings.webhookUrl;
    _httpMethod = settings.httpMethod;
    _payloadTemplateController.text = settings.httpPayloadTemplate;
    _autoInvoice = settings.autoSendOnInvoice;
    _autoPayment = settings.autoSendOnPayment;
    _autoBoli = settings.autoSendOnBoli;
    _autoWeighbridge = settings.autoSendOnWeighbridge;
    _autoAdvance = settings.autoSendOnAdvance;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _senderIdController.dispose();
    _accountSidController.dispose();
    _apiSecretController.dispose();
    _fromNumberController.dispose();
    _apiKeyController.dispose();
    _webhookUrlController.dispose();
    _payloadTemplateController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveSettings() async {
    final smsProvider = context.read<SmsProvider>();
    final shopContext = context.read<ShopContextProvider>();
    final shopId = shopContext.currentShopId ?? '';

    final updated = smsProvider.settings.copyWith(
      shopId: shopId,
      isEnabled: _isEnabled,
      provider: _selectedProvider,
      senderId: _senderIdController.text.trim(),
      accountSid: _accountSidController.text.trim(),
      apiSecret: _apiSecretController.text.trim(),
      fromNumber: _fromNumberController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      webhookUrl: _webhookUrlController.text.trim(),
      httpMethod: _httpMethod,
      httpPayloadTemplate: _payloadTemplateController.text.trim(),
      autoSendOnInvoice: _autoInvoice,
      autoSendOnPayment: _autoPayment,
      autoSendOnBoli: _autoBoli,
      autoSendOnWeighbridge: _autoWeighbridge,
      autoSendOnAdvance: _autoAdvance,
    );

    final success = await smsProvider.saveSettings(updated);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SMS Gateway settings saved successfully!'),
          backgroundColor: MColors.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to save SMS settings.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _showTestSmsDialog() {
    final shop = context.read<ShopContextProvider>().currentShop;
    final shopName = shop?.name ?? 'Mandi Commission Shop';

    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Send Test Verification SMS'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter recipient phone to test the ${_selectedProvider.labelEnglish} gateway connection:',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Recipient Phone',
                  hintText: '03001234567',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: MColors.primary),
              onPressed: () async {
                final phone = phoneController.text.trim();
                if (phone.isEmpty) return;
                Navigator.of(ctx).pop();

                final smsProvider = context.read<SmsProvider>();
                final res = await smsProvider.sendTestSms(
                  recipientPhone: phone,
                  shopName: shopName,
                );

                if (!mounted) return;

                if (res.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Test SMS delivered! (ID: ${res.messageId})'),
                      backgroundColor: MColors.primary,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Test SMS failed: ${res.errorMessage}'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                }
              },
              child: const Text('Send Test'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final smsProvider = context.watch<SmsProvider>();
    final summary = smsProvider.summary;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.val(context, en: 'SMS Gateway & Notifications', ur: 'ایس ایم ایس گیٹ وے'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              AppStrings.val(context, en: 'Automated SMS Gateway & Delivery Alerts', ur: 'خودکار پیغامات اور ترسیل کا نظام'),
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Send Test SMS',
            icon: const Icon(Icons.send_to_mobile_rounded),
            onPressed: _showTestSmsDialog,
          ),
          IconButton(
            tooltip: 'Reload Settings & Logs',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => smsProvider.loadSettings(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(icon: const Icon(Icons.tune_rounded), text: AppStrings.val(context, en: 'Gateway Settings', ur: 'گیٹ وے سیٹنگز')),
            Tab(icon: const Icon(Icons.history_rounded), text: AppStrings.val(context, en: 'Delivery Logs', ur: 'پیغامات کا تاریخچہ')),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: MColors.primary,
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: Text(AppStrings.val(context, en: 'Compose SMS', ur: 'نیا پیغام'), style: const TextStyle(color: Colors.white)),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const SendQuickSmsDialog(),
          );
        },
      ),
      body: Column(
        children: [
          // KPI Summary Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildKpiCard(
                  title: 'Total Dispatched',
                  titleUrdu: 'کل پیغامات',
                  val: '${summary.totalCount}',
                  icon: Icons.sms_rounded,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 10),
                _buildKpiCard(
                  title: 'Delivered',
                  titleUrdu: 'موصول شدہ',
                  val: '${summary.deliveredCount + summary.sentCount}',
                  icon: Icons.check_circle_rounded,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 10),
                _buildKpiCard(
                  title: 'Failed',
                  titleUrdu: 'ناکام پیغامات',
                  val: '${summary.failedCount}',
                  icon: Icons.error_outline_rounded,
                  color: Colors.red.shade700,
                ),
                const SizedBox(width: 10),
                _buildKpiCard(
                  title: "Today's Volume",
                  titleUrdu: 'آج کے پیغامات',
                  val: '${summary.todayCount}',
                  icon: Icons.today_rounded,
                  color: Colors.orange.shade800,
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Settings
                _buildSettingsTab(smsProvider),

                // Tab 2: Logs
                _buildLogsTab(smsProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Settings View ─────────────────────────────────────────────────

  Widget _buildSettingsTab(SmsProvider smsProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Enable Switch
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isEnabled
                          ? MColors.primary.withValues(alpha: 0.15)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.power_settings_new_rounded,
                      color: _isEnabled ? MColors.primary : Colors.grey.shade600,
                    ),
                  ),
                  title: const Text(
                    'Automated SMS Service Enabled',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: const Text(
                    'Automatically dispatch real-time SMS alerts to buyers and farmers on transactions.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _isEnabled,
                  activeThumbColor: MColors.primary,
                  onChanged: (val) {
                    setState(() => _isEnabled = val);
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Provider Configuration Card
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gateway Provider & Credentials',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select telecom SMS provider and configure API credentials.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),

                    // Provider Dropdown
                    DropdownButtonFormField<SmsProviderType>(
                      initialValue: _selectedProvider,
                      decoration: const InputDecoration(
                        labelText: 'SMS Provider Gateway',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cloud_sync_rounded),
                      ),
                      items: SmsProviderType.values.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text('${p.labelEnglish} (${p.labelUrdu})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedProvider = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Sender ID Mask
                    TextFormField(
                      controller: _senderIdController,
                      decoration: InputDecoration(
                        labelText: AppStrings.val(context, en: 'Sender ID / Mask', ur: 'سینڈر نام یا مہر'),
                        hintText: 'e.g. MANDI-ERP or AL-REHMAN',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.badge_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Conditional fields based on provider
                    if (_selectedProvider == SmsProviderType.mock)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Mock Simulator Mode: All outgoing SMS are logged and simulated locally without charging telecom balances.',
                                style: TextStyle(fontSize: 12, color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_selectedProvider == SmsProviderType.twilio) ...[
                      TextFormField(
                        controller: _accountSidController,
                        decoration: const InputDecoration(
                          labelText: 'Twilio Account SID',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.account_circle),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _apiSecretController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Twilio Auth Token',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.key),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _fromNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Twilio Sender Phone Number',
                          hintText: '+14155552671',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                    ],

                    if (_selectedProvider == SmsProviderType.genericHttp ||
                        _selectedProvider == SmsProviderType.telcoPakistan) ...[
                      TextFormField(
                        controller: _webhookUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Webhook API Endpoint URL',
                          hintText: 'https://api.smsprovider.pk/send?to={to}&msg={message}',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _httpMethod,
                              decoration: const InputDecoration(
                                labelText: 'HTTP Method',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'POST', child: Text('POST')),
                                DropdownMenuItem(value: 'GET', child: Text('GET')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _httpMethod = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _apiKeyController,
                              decoration: const InputDecoration(
                                labelText: 'API Key / Secret Token',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.security),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_httpMethod == 'POST') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _payloadTemplateController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'JSON Payload Template',
                            hintText: '{"to": "{to}", "message": "{message}", "sender": "{sender}"}',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.code),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Automated Event Triggers Card
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.val(context, en: 'Automated Event Triggers', ur: 'خودکار روانگی کے واقعات'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.val(
                        context,
                        en: 'Choose which Mandi business actions trigger automatic background SMS dispatch.',
                        ur: 'منتخب کریں کن تجارتی سرگرمیوں پر پس منظر میں خودکار پیغام ارسال ہو۔',
                      ),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const Divider(height: 24),
                    SwitchListTile(
                      title: Text(AppStrings.val(context, en: 'Sales Invoices', ur: 'سیلز بل رسید')),
                      subtitle: Text(AppStrings.val(context, en: 'Send SMS to customer with grand total & pending balance.', ur: 'گاہک کو کل رقم اور بقایا بیلنس کا پیغام۔')),
                      value: _autoInvoice,
                      activeThumbColor: MColors.primary,
                      onChanged: (val) => setState(() => _autoInvoice = val),
                    ),
                    SwitchListTile(
                      title: Text(AppStrings.val(context, en: 'Payment Receipts', ur: 'وصولی پرچہ')),
                      subtitle: Text(AppStrings.val(context, en: 'Send SMS when cash/bank receipt is recorded.', ur: 'نقدی یا بینک وصولی کے اندراج پر فوری پیغام۔')),
                      value: _autoPayment,
                      activeThumbColor: MColors.primary,
                      onChanged: (val) => setState(() => _autoPayment = val),
                    ),
                    SwitchListTile(
                      title: Text(AppStrings.val(context, en: 'Auction Boli Bids', ur: 'بولی تصدیق')),
                      subtitle: Text(AppStrings.val(context, en: 'Send SMS to winning buyer with lot quantity & price/Mann.', ur: 'کامیاب خریدار کو جنس کی مقدار اور فی من ریٹ کا پیغام۔')),
                      value: _autoBoli,
                      activeThumbColor: MColors.primary,
                      onChanged: (val) => setState(() => _autoBoli = val),
                    ),
                    SwitchListTile(
                      title: Text(AppStrings.val(context, en: 'Weighbridge Kanda', ur: 'دھرم کنڈا وزن')),
                      subtitle: Text(AppStrings.val(context, en: 'Send SMS with gross, tare, and certified net weight.', ur: 'گاڑی کے وزن، کٹوتی اور خالص وزن کی پرچی۔')),
                      value: _autoWeighbridge,
                      activeThumbColor: MColors.primary,
                      onChanged: (val) => setState(() => _autoWeighbridge = val),
                    ),
                    SwitchListTile(
                      title: Text(AppStrings.val(context, en: 'Farmer Advances', ur: 'زمیندار کٹوتی')),
                      subtitle: Text(AppStrings.val(context, en: 'Send SMS to farmer upon harvest loan deduction.', ur: 'زمیندار کو ایڈوانس یا قرض کٹوتی کا پیغام۔')),
                      value: _autoAdvance,
                      activeThumbColor: MColors.primary,
                      onChanged: (val) => setState(() => _autoAdvance = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: smsProvider.isSavingSettings ? null : _handleSaveSettings,
                  icon: smsProvider.isSavingSettings
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    smsProvider.isSavingSettings ? 'Saving Settings...' : 'Save Gateway Configuration',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab 2: Logs View ─────────────────────────────────────────────────────

  Widget _buildLogsTab(SmsProvider smsProvider) {
    final logs = smsProvider.filteredLogs;

    return Column(
      children: [
        // Search & Filter Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by phone, recipient, or message...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (val) => smsProvider.setSearchQuery(val),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All Status'),
                      selected: smsProvider.statusFilter == null,
                      onSelected: (_) => smsProvider.setStatusFilter(null),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('Sent / Delivered'),
                      selected: smsProvider.statusFilter == 'sent' ||
                          smsProvider.statusFilter == 'delivered',
                      onSelected: (_) => smsProvider.setStatusFilter('sent'),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('Failed'),
                      selected: smsProvider.statusFilter == 'failed',
                      onSelected: (_) => smsProvider.setStatusFilter('failed'),
                    ),
                    const SizedBox(width: 12),
                    const VerticalDivider(),
                    const SizedBox(width: 12),
                    FilterChip(
                      label: const Text('All Events'),
                      selected: smsProvider.eventFilter == null,
                      onSelected: (_) => smsProvider.setEventFilter(null),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('Invoices'),
                      selected: smsProvider.eventFilter == SmsEventType.invoice,
                      onSelected: (_) => smsProvider.setEventFilter(SmsEventType.invoice),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('Payments'),
                      selected: smsProvider.eventFilter == SmsEventType.payment,
                      onSelected: (_) => smsProvider.setEventFilter(SmsEventType.payment),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('Boli'),
                      selected: smsProvider.eventFilter == SmsEventType.boli,
                      onSelected: (_) => smsProvider.setEventFilter(SmsEventType.boli),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Logs List
        Expanded(
          child: logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_rounded, size: 54, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'No SMS logs found for current filters.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Messages sent through automated triggers will appear here.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return _buildLogCard(log, smsProvider);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLogCard(SmsLog log, SmsProvider smsProvider) {
    final timeStr = DateFormat('dd/MM/yyyy hh:mm a').format(log.createdAt);

    Color statusColor;
    IconData statusIcon;
    switch (log.status) {
      case SmsDeliveryStatus.sent:
      case SmsDeliveryStatus.delivered:
        statusColor = Colors.green.shade700;
        statusIcon = Icons.check_circle_rounded;
        break;
      case SmsDeliveryStatus.failed:
        statusColor = Colors.red.shade700;
        statusIcon = Icons.cancel_rounded;
        break;
      case SmsDeliveryStatus.pending:
        statusColor = Colors.amber.shade800;
        statusIcon = Icons.hourglass_top_rounded;
        break;
    }

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: MColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AppStrings.isUrdu(context) ? log.eventType.labelUrdu : log.eventType.labelEnglish,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: MColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${log.partsCount} ${log.partsCount == 1 ? "Part" : "Parts"}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                Text(
                  timeStr,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Recipient Row
            Row(
              children: [
                const Icon(Icons.phone_iphone_rounded, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  log.recipientPhone,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                if (log.recipientName.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    '(${log.recipientName})',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),

            // Message Body Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                log.messageBody,
                style: const TextStyle(fontSize: 12, height: 1.3),
              ),
            ),
            const SizedBox(height: 8),

            // Status & Action Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      AppStrings.isUrdu(context) ? log.status.labelUrdu : log.status.labelEnglish,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    if (log.errorMessage != null && log.errorMessage!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '- ${log.errorMessage}',
                        style: TextStyle(fontSize: 10, color: Colors.red.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
                if (log.status == SmsDeliveryStatus.failed)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () async {
                      final res = await smsProvider.retrySms(log);
                      if (res.success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Retried SMS sent successfully!'),
                            backgroundColor: MColors.primary,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.replay_rounded, size: 14),
                    label: const Text('Retry Send', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String titleUrdu,
    required String val,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    val,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    AppStrings.isUrdu(context) ? titleUrdu : title,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
