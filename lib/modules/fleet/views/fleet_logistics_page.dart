import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mandi/core/theme/app_theme.dart';
import 'package:mandi/core/utils/fleet_logistics_pdf_generator.dart';
import 'package:mandi/data/models/fleet_model.dart';
import 'package:mandi/modules/fleet/providers/fleet_provider.dart';
import 'package:mandi/modules/fleet/views/log_fuel_expense_dialog.dart';
import 'package:mandi/modules/fleet/views/new_trip_challan_dialog.dart';
import 'package:mandi/modules/fleet/views/register_vehicle_dialog.dart';
import 'package:mandi/providers/shop_context_provider.dart';

/// Central Fleet Logistics, Trip Bilty & Vehicle P&L Ledger Page
/// (*ٹرانسپورٹ بلٹی، گاڑیوں کا تیل اور کرایہ و منافع کھاتہ*).
class FleetLogisticsPage extends StatefulWidget {
  const FleetLogisticsPage({super.key});

  @override
  State<FleetLogisticsPage> createState() => _FleetLogisticsPageState();
}

class _FleetLogisticsPageState extends State<FleetLogisticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyFmt = NumberFormat('#,##0', 'en_US');
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FleetProvider>().loadFleetData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openRegisterVehicleDialog() {
    showDialog(
      context: context,
      builder: (_) => const RegisterVehicleDialog(),
    );
  }

  void _openNewTripDialog([String? vehicleId]) {
    showDialog(
      context: context,
      builder: (_) => NewTripChallanDialog(preselectedVehicleId: vehicleId),
    );
  }

  void _openLogFuelDialog([String? vehicleId, String? tripId]) {
    showDialog(
      context: context,
      builder: (_) => LogFuelExpenseDialog(
        preselectedVehicleId: vehicleId,
        preselectedTripId: tripId,
      ),
    );
  }

  void _printTripBilty(FleetTrip trip, FleetVehicle vehicle) {
    final shop = context.read<ShopContextProvider>().currentShop;
    FleetLogisticsPdfGenerator.printTripChallan(
      trip: trip,
      vehicle: vehicle,
      shopName: shop?.name ?? 'Mandi Trading Co.',
      shopAddress: shop?.address,
      shopPhone: shop?.phone,
    );
  }

  void _printVehicleLedger(FleetVehicle vehicle, List<FleetTrip> trips,
      List<FleetFuelLog> fuelLogs) {
    final shop = context.read<ShopContextProvider>().currentShop;
    FleetLogisticsPdfGenerator.printVehicleLedger(
      vehicle: vehicle,
      trips: trips,
      fuelLogs: fuelLogs,
      shopName: shop?.name ?? 'Mandi Trading Co.',
      shopAddress: shop?.address,
      shopPhone: shop?.phone,
    );
  }

  Future<void> _completeTripModal(FleetTrip trip) async {
    final dieselCtrl =
        TextEditingController(text: trip.dieselExpensePkr.toStringAsFixed(0));
    final tollCtrl =
        TextEditingController(text: trip.tollAndTaxPkr.toStringAsFixed(0));
    final otherCtrl =
        TextEditingController(text: trip.otherExpensePkr.toStringAsFixed(0));

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green),
              const SizedBox(width: 10),
              Text('Complete Trip (${trip.tripNumber})'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Finalize trip expenses to calculate accurate net profit:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: dieselCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Actual Diesel Expense (PKR)',
                    prefixText: 'Rs. ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: tollCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Actual Toll & Tax (PKR)',
                    prefixText: 'Rs. ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: otherCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Actual Other Expense (PKR)',
                    prefixText: 'Rs. ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Mark Completed (مکمل کریں)'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final finalDiesel = double.tryParse(dieselCtrl.text.trim());
      final finalToll = double.tryParse(tollCtrl.text.trim());
      final finalOther = double.tryParse(otherCtrl.text.trim());

      final provider = context.read<FleetProvider>();
      final success = await provider.completeTrip(
        trip.id,
        finalDiesel: finalDiesel,
        finalToll: finalToll,
        finalOther: finalOther,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trip marked as completed!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update trip.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FleetProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Logistics & Bilty (ٹرانسپورٹ کھاتہ)'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Fleet Data',
            onPressed: () => provider.loadFleetData(),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.local_gas_station, size: 18),
            label: const Text('Log Diesel'),
            onPressed: () => _openLogFuelDialog(),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: MColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Trip (بلٹی)'),
            onPressed: () => _openNewTripDialog(),
          ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: MColors.primary,
          indicatorWeight: 3,
          labelColor: MColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(
              icon: Icon(Icons.assignment_outlined),
              text: 'Trips & Bilty (ٹرپ اور بلٹی)',
            ),
            Tab(
              icon: Icon(Icons.local_shipping_outlined),
              text: 'Fleet & P&L (گاڑیاں اور کھاتہ)',
            ),
            Tab(
              icon: Icon(Icons.local_gas_station_outlined),
              text: 'Fuel & Maintenance (ڈیزل و اخراجات)',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // KPI Metric Bar
          _buildKpiMetricsBanner(provider),

          // Main Tabs Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTripsTab(provider),
                _buildVehiclesTab(provider),
                _buildFuelLogsTab(provider),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: MColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Register Vehicle'),
        onPressed: _openRegisterVehicleDialog,
      ),
    );
  }

  // ===========================================================================
  // KPI METRICS BANNER
  // ===========================================================================

  Widget _buildKpiMetricsBanner(FleetProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildKpiTile(
              label: 'Fleet Size / گاڑیاں',
              value:
                  '${provider.activeVehiclesCount} / ${provider.totalVehiclesCount}',
              subtitle: 'Active Vehicles',
              color: Colors.blue,
              icon: Icons.local_shipping,
            ),
            const SizedBox(width: 12),
            _buildKpiTile(
              label: 'In Transit / راستے میں',
              value: '${provider.inTransitTripsCount} Trips',
              subtitle: 'Active On-Route',
              color: Colors.orange,
              icon: Icons.directions_bus,
            ),
            const SizedBox(width: 12),
            _buildKpiTile(
              label: 'Total Freight / کل کرایہ',
              value: 'Rs. ${_currencyFmt.format(provider.totalFreightRevenue)}',
              subtitle: 'Gross Billing',
              color: Colors.indigo,
              icon: Icons.payments_outlined,
            ),
            const SizedBox(width: 12),
            _buildKpiTile(
              label: 'Fuel Logged / ڈیزل خرچ',
              value:
                  '${_currencyFmt.format(provider.totalFuelLiters)} Ltr (Rs. ${_currencyFmt.format(provider.totalFuelExpense)})',
              subtitle: 'Operating Fuel',
              color: Colors.amber.shade900,
              icon: Icons.local_gas_station,
            ),
            const SizedBox(width: 12),
            _buildKpiTile(
              label: 'Net Fleet Profit / خالص منافع',
              value: 'Rs. ${_currencyFmt.format(provider.totalNetProfit)}',
              subtitle: 'Revenue - Expenses',
              color: Colors.green,
              icon: Icons.trending_up,
            ),
            const SizedBox(width: 12),
            _buildKpiTile(
              label: 'Pending Payable / بقایا کرایہ',
              value:
                  'Rs. ${_currencyFmt.format(provider.totalPendingFreightPayable)}',
              subtitle: 'Driver Freight Balance',
              color: Colors.redAccent,
              icon: Icons.receipt_long,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiTile({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 155),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700)),
              Text(
                value,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: color),
              ),
              Text(subtitle,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: TRIPS & BILTY REGISTER
  // ===========================================================================

  Widget _buildTripsTab(FleetProvider provider) {
    final trips = provider.filteredTrips;

    return Column(
      children: [
        // Filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText:
                        'Search trip #, destination, party or cargo (تلاش کریں)...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              provider.setSearchQuery('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) => provider.setSearchQuery(val),
                ),
              ),
              const SizedBox(width: 12),
              // Status filter
              DropdownButton<TripStatus?>(
                value: provider.statusFilter,
                hint: const Text('All Status'),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('All Status (تمام)')),
                  DropdownMenuItem(
                      value: TripStatus.inTransit,
                      child: Text(TripStatus.inTransit.labelEnglish)),
                  DropdownMenuItem(
                      value: TripStatus.completed,
                      child: Text(TripStatus.completed.labelEnglish)),
                  DropdownMenuItem(
                      value: TripStatus.cancelled,
                      child: Text(TripStatus.cancelled.labelEnglish)),
                ],
                onChanged: (val) => provider.setStatusFilter(val),
              ),
              const SizedBox(width: 12),
              // Vehicle filter
              DropdownButton<String?>(
                value: provider.selectedVehicleId,
                hint: const Text('All Vehicles'),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('All Vehicles (تمام گاڑیاں)')),
                  ...provider.vehicles.map((v) {
                    return DropdownMenuItem(
                      value: v.id,
                      child: Text(
                        '${v.registrationNumber} (${v.vehicleType.labelEnglish})',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }),
                ],
                onChanged: (val) => provider.setSelectedVehicleId(val),
              ),
            ],
          ),
        ),

        // Trips List
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : trips.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_shipping_outlined,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'No Freight Trips Found / کوئی ٹرپ ریکارڈ نہیں',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Dispatch your first cargo trip and print official Mandi Bilty.',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Dispatch Trip Bilty'),
                            onPressed: () => _openNewTripDialog(),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: trips.length,
                      itemBuilder: (context, index) {
                        final trip = trips[index];
                        final vehicle = provider.getVehicleById(trip.vehicleId);
                        return _buildTripCard(trip, vehicle);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildTripCard(FleetTrip trip, FleetVehicle? vehicle) {
    final statusColor = trip.status == TripStatus.inTransit
        ? Colors.orange
        : (trip.status == TripStatus.completed ? Colors.green : Colors.red);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Trip #, Date, Status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: MColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.receipt,
                          color: MColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      trip.tripNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: MColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        trip.status.labelEnglish,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor),
                      ),
                    ),
                  ],
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(trip.tripDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Route & Vehicle
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.trip_origin,
                          size: 16, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text(
                        trip.origin,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child:
                            Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                      ),
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.redAccent),
                      const SizedBox(width: 6),
                      Text(
                        trip.destination,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (vehicle != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      '${vehicle.registrationNumber} • ${vehicle.vehicleType.labelEnglish}',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Cargo & Party details
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Cargo: ${trip.commodityName.isEmpty ? 'General Freight' : trip.commodityName} • ${trip.loadedWeightKg > 0 ? '${_currencyFmt.format(trip.loadedWeightKg)} KG' : ''} (${trip.loadedWeightMaunds.toStringAsFixed(1)} Maunds) • ${trip.bagCount > 0 ? '${trip.bagCount} Bags' : ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  if (trip.partyName.isNotEmpty)
                    Text(
                      'Party: ${trip.partyName}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey.shade800),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Financial Summary Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Agreed Freight',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                    Text('Rs. ${_currencyFmt.format(trip.agreedFreightPkr)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.blue)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Advance Paid',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                    Text('Rs. ${_currencyFmt.format(trip.driverAdvancePkr)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Operating Exp',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                    Text(
                        'Rs. ${_currencyFmt.format(trip.totalOperatingExpensePkr)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.orange)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Net Trip Profit',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                    Text('Rs. ${_currencyFmt.format(trip.netTripProfitPkr)}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: trip.netTripProfitPkr >= 0
                                ? Colors.green
                                : Colors.red)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Freight Balance',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                    Text(
                        'Rs. ${_currencyFmt.format(trip.balanceFreightPayablePkr)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.redAccent)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.local_gas_station,
                      size: 16, color: Colors.amber),
                  label: const Text('Log Fuel', style: TextStyle(fontSize: 12)),
                  onPressed: () =>
                      _openLogFuelDialog(trip.vehicleId, trip.id),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.print, size: 16),
                  label:
                      const Text('Print Bilty', style: TextStyle(fontSize: 12)),
                  onPressed: vehicle != null
                      ? () => _printTripBilty(trip, vehicle)
                      : null,
                ),
                if (trip.status == TripStatus.inTransit) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Complete Trip',
                        style: TextStyle(fontSize: 12)),
                    onPressed: () => _completeTripModal(trip),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 2: VEHICLES & P&L LEDGER
  // ===========================================================================

  Widget _buildVehiclesTab(FleetProvider provider) {
    final vehicles = provider.vehicles;

    if (vehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No Vehicles in Fleet / کوئی گاڑی درج نہیں',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Register your transport fleet (Mazda, Shehzore, Tractor Trolley) to manage ledgers.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: MColors.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Register Vehicle (گاڑی درج کریں)'),
              onPressed: _openRegisterVehicleDialog,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = vehicles[index];
        final vTrips =
            provider.trips.where((t) => t.vehicleId == vehicle.id).toList();
        final vFuel =
            provider.fuelLogs.where((f) => f.vehicleId == vehicle.id).toList();

        final earned = vTrips.fold(0.0, (sum, t) => sum + t.agreedFreightPkr);
        final profit = vTrips.fold(0.0, (sum, t) => sum + t.netTripProfitPkr);
        final fuelExpense =
            vFuel.fold(0.0, (sum, f) => sum + f.totalCostPkr);
        final fuelLiters = vFuel.fold(0.0, (sum, f) => sum + f.liters);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Reg #, Type badge, Ownership badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: MColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.local_shipping,
                              color: MColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle.registrationNumber,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: MColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${vehicle.vehicleType.labelEnglish} (${vehicle.vehicleType.labelUrdu})',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blueGrey.shade200),
                          ),
                          child: Text(
                            vehicle.ownershipType.labelEnglish,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueGrey.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: vehicle.isActive
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: vehicle.isActive
                                    ? Colors.green
                                    : Colors.grey),
                          ),
                          child: Text(
                            vehicle.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: vehicle.isActive
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Driver & Specs
                Row(
                  children: [
                    if (vehicle.driverName.isNotEmpty) ...[
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Driver: ${vehicle.driverName} ${vehicle.driverPhone.isNotEmpty ? '(${vehicle.driverPhone})' : ''}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                    ],
                    const Icon(Icons.inventory_2_outlined,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Capacity: ${vehicle.capacityMaunds.toStringAsFixed(0)} Maunds',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.speed, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Odometer: ${_currencyFmt.format(vehicle.odometerKm)} KM',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Financial Overview Bar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('Trips Completed',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade700)),
                          const SizedBox(height: 2),
                          Text('${vTrips.length}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      Column(
                        children: [
                          Text('Total Freight',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade700)),
                          const SizedBox(height: 2),
                          Text('Rs. ${_currencyFmt.format(earned)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.blue)),
                        ],
                      ),
                      Column(
                        children: [
                          Text('Fuel & Repairs',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade700)),
                          const SizedBox(height: 2),
                          Text(
                              'Rs. ${_currencyFmt.format(fuelExpense)} (${fuelLiters.toStringAsFixed(0)} Ltr)',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.amber)),
                        ],
                      ),
                      Column(
                        children: [
                          Text('Net Profit (خالص نفع)',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade700)),
                          const SizedBox(height: 2),
                          Text('Rs. ${_currencyFmt.format(profit)}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: profit >= 0
                                      ? Colors.green
                                      : Colors.red)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.local_gas_station,
                          size: 16, color: Colors.amber),
                      label: const Text('Log Diesel',
                          style: TextStyle(fontSize: 12)),
                      onPressed: () => _openLogFuelDialog(vehicle.id),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.receipt_long, size: 16),
                      label: const Text('Print Ledger A4',
                          style: TextStyle(fontSize: 12)),
                      onPressed: () =>
                          _printVehicleLedger(vehicle, vTrips, vFuel),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('New Trip',
                          style: TextStyle(fontSize: 12)),
                      onPressed: () => _openNewTripDialog(vehicle.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // TAB 3: FUEL & MAINTENANCE LOGS
  // ===========================================================================

  Widget _buildFuelLogsTab(FleetProvider provider) {
    final logs = provider.filteredFuelLogs;

    return Column(
      children: [
        // Top filter by vehicle
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Filter by Vehicle: ',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  DropdownButton<String?>(
                    value: provider.selectedVehicleId,
                    hint: const Text('All Vehicles'),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('All Vehicles (تمام)')),
                      ...provider.vehicles.map((v) {
                        return DropdownMenuItem(
                          value: v.id,
                          child: Text(
                            '${v.registrationNumber} (${v.vehicleType.labelEnglish})',
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) => provider.setSelectedVehicleId(val),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade800,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Fuel Receipt'),
                onPressed: () =>
                    _openLogFuelDialog(provider.selectedVehicleId),
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
                      Icon(Icons.local_gas_station_outlined,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'No Fuel or Maintenance Logs Found',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Record diesel purchases, engine oil changes and repairs.',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final vehicle = provider.getVehicleById(log.vehicleId);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.local_gas_station,
                              color: Colors.amber),
                        ),
                        title: Row(
                          children: [
                            Text(
                              log.fuelType.toUpperCase(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            if (vehicle != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  vehicle.registrationNumber,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            const Spacer(),
                            Text(
                              'Rs. ${_currencyFmt.format(log.totalCostPkr)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.brown,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${log.pumpOrVendorName} • ${log.liters > 0 ? '${log.liters.toStringAsFixed(1)} Ltr @ Rs. ${log.ratePerLiter.toStringAsFixed(1)}' : 'Service'}${log.receiptVoucherNumber.isNotEmpty ? ' • Voucher: ${log.receiptVoucherNumber}' : ''}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              Text(
                                DateFormat('dd MMM yyyy').format(log.logDate),
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
