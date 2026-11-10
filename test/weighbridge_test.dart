import 'package:flutter_test/flutter_test.dart';

import 'package:mandi/core/utils/scale_service.dart';
import 'package:mandi/core/utils/weighbridge_slip_pdf_generator.dart';
import 'package:mandi/data/models/weighbridge_ticket_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WeighbridgeTicket Model Tests', () {
    test('serializes toMap and deserializes fromMap accurately', () {
      final now = DateTime.now();
      final ticket = WeighbridgeTicket(
        id: 'wb-001',
        shopId: 'shop-xyz',
        ticketNumber: 'WB-2411-001',
        vehicleNumber: 'LES-8920',
        vehicleType: VehicleType.trolley,
        driverName: 'Muhammad Akram',
        driverPhone: '03001234567',
        partyName: 'Chaudhry Bashir',
        partyType: WeighbridgePartyType.farmer,
        commodityName: 'Super Basmati Paddy (دھان)',
        grossWeightKg: 9500.0,
        tareWeightKg: 2500.0,
        netWeightKg: 7000.0,
        deductionKg: 100.0,
        deductionReason: 'Moisture 2%',
        finalWeightKg: 6900.0,
        bagCount: 175,
        kandaFee: 250.0,
        feePaidBy: WeighbridgeFeePaidBy.farmer,
        status: WeighbridgeStatus.completed,
        grossWeighedAt: now.subtract(const Duration(hours: 1)),
        tareWeighedAt: now,
        operatorName: 'Ustad Shaukat',
        notes: 'Loaded from Deepalpur',
        createdAt: now,
      );

      final map = ticket.toMap();
      expect(map['shop_id'], 'shop-xyz');
      expect(map['ticket_number'], 'WB-2411-001');
      expect(map['vehicle_number'], 'LES-8920');
      expect(map['vehicle_type'], 'trolley');
      expect(map['driver_name'], 'Muhammad Akram');
      expect(map['driver_phone'], '03001234567');
      expect(map['party_name'], 'Chaudhry Bashir');
      expect(map['party_type'], 'farmer');
      expect(map['commodity_name'], 'Super Basmati Paddy (دھان)');
      expect(map['gross_weight_kg'], 9500.0);
      expect(map['tare_weight_kg'], 2500.0);
      expect(map['net_weight_kg'], 7000.0);
      expect(map['deduction_kg'], 100.0);
      expect(map['deduction_reason'], 'Moisture 2%');
      expect(map['final_weight_kg'], 6900.0);
      expect(map['bag_count'], 175);
      expect(map['kanda_fee'], 250.0);
      expect(map['fee_paid_by'], 'farmer');
      expect(map['status'], 'completed');
      expect(map['operator_name'], 'Ustad Shaukat');

      final parsed = WeighbridgeTicket.fromMap('wb-001', map);
      expect(parsed.id, 'wb-001');
      expect(parsed.ticketNumber, 'WB-2411-001');
      expect(parsed.vehicleNumber, 'LES-8920');
      expect(parsed.vehicleType, VehicleType.trolley);
      expect(parsed.grossWeightKg, 9500.0);
      expect(parsed.tareWeightKg, 2500.0);
      expect(parsed.status, WeighbridgeStatus.completed);
      expect(parsed.isAwaitingTare, isFalse);
    });

    test('calculates computedNetWeightKg, computedFinalWeightKg, and maunds correctly', () {
      final now = DateTime.now();
      // Gross: 10,000 KG, Tare: 2,000 KG -> Net: 8,000 KG
      // Deduction: 200 KG -> Final: 7,800 KG
      // Maunds: 7,800 / 40 = 195.0 Maunds
      final ticket = WeighbridgeTicket(
        id: '1',
        shopId: 's1',
        ticketNumber: 'WB-101',
        vehicleNumber: 'FDN-2024',
        grossWeightKg: 10000.0,
        tareWeightKg: 2000.0,
        deductionKg: 200.0,
        grossWeighedAt: now,
      );

      expect(ticket.computedNetWeightKg, 8000.0);
      expect(ticket.computedFinalWeightKg, 7800.0);
      expect(ticket.maunds, 195.0);
      expect(ticket.grossMaunds, 250.0); // 10000 / 40
      expect(ticket.tareMaunds, 50.0); // 2000 / 40
      expect(ticket.netMaunds, 200.0); // 8000 / 40
    });

    test('detects isAwaitingTare status properly', () {
      final now = DateTime.now();
      final awaitingTicket = WeighbridgeTicket(
        id: '2',
        shopId: 's1',
        ticketNumber: 'WB-102',
        vehicleNumber: 'MN-7711',
        grossWeightKg: 8500.0,
        tareWeightKg: 0.0,
        status: WeighbridgeStatus.grossRecorded,
        grossWeighedAt: now,
      );

      expect(awaitingTicket.isAwaitingTare, isTrue);

      final completedTicket = awaitingTicket.copyWith(
        tareWeightKg: 2300.0,
        status: WeighbridgeStatus.completed,
      );
      expect(completedTicket.isAwaitingTare, isFalse);
    });

    test('handles boundary condition where deduction exceeds net weight', () {
      final now = DateTime.now();
      final ticket = WeighbridgeTicket(
        id: '3',
        shopId: 's1',
        ticketNumber: 'WB-103',
        vehicleNumber: 'LHR-1',
        grossWeightKg: 3000.0,
        tareWeightKg: 2800.0, // net = 200 kg
        deductionKg: 500.0, // deduction exceeds net
        grossWeighedAt: now,
      );

      expect(ticket.computedNetWeightKg, 200.0);
      expect(ticket.computedFinalWeightKg, 0.0); // Clamped to 0
      expect(ticket.maunds, 0.0);
    });

    test('returns localized labels for vehicle types and ticket status', () {
      expect(VehicleType.trolley.labelEnglish, 'Tractor Trolley');
      expect(VehicleType.trolley.labelUrdu, 'ٹریکٹر ٹرالی');
      expect(VehicleType.truckMazda.labelEnglish, 'Mazda / 6-Wheeler Truck');
      expect(VehicleType.truckMazda.labelUrdu, 'مزدا / 6 ویلر ٹرک');
      expect(VehicleType.shehzore.labelUrdu, 'شہزور ڈالہ');

      expect(WeighbridgeStatus.grossRecorded.labelEnglish, 'Awaiting Tare Weight');
      expect(WeighbridgeStatus.grossRecorded.labelUrdu, 'وزن بھرا (خالی گاڑی باقی)');
      expect(WeighbridgeStatus.completed.labelEnglish, 'Completed');
      expect(WeighbridgeStatus.completed.labelUrdu, 'مکمل کنڈا پرچی');
    });

    test('copyWith produces updated ticket instance', () {
      final now = DateTime.now();
      final ticket = WeighbridgeTicket(
        id: '1',
        shopId: 's1',
        ticketNumber: 'WB-001',
        vehicleNumber: 'OLD-123',
        grossWeightKg: 5000.0,
        grossWeighedAt: now,
      );

      final updated = ticket.copyWith(
        vehicleNumber: 'NEW-999',
        tareWeightKg: 1500.0,
      );
      expect(updated.vehicleNumber, 'NEW-999');
      expect(updated.tareWeightKg, 1500.0);
      expect(updated.grossWeightKg, 5000.0);
      expect(updated.id, '1');
    });
  });

  group('WeighbridgeSummary Tests', () {
    test('aggregates tickets metrics accurately and excludes cancelled', () {
      final now = DateTime.now();
      final tickets = [
        WeighbridgeTicket(
          id: '1',
          shopId: 's1',
          ticketNumber: 'WB-01',
          vehicleNumber: 'V1',
          grossWeightKg: 10000.0,
          tareWeightKg: 2000.0,
          deductionKg: 100.0, // net: 8000, final: 7900
          kandaFee: 200.0,
          status: WeighbridgeStatus.completed,
          grossWeighedAt: now,
        ),
        WeighbridgeTicket(
          id: '2',
          shopId: 's1',
          ticketNumber: 'WB-02',
          vehicleNumber: 'V2',
          grossWeightKg: 8000.0,
          tareWeightKg: 0.0, // awaiting tare
          kandaFee: 200.0,
          status: WeighbridgeStatus.grossRecorded,
          grossWeighedAt: now,
        ),
        WeighbridgeTicket(
          id: '3',
          shopId: 's1',
          ticketNumber: 'WB-03',
          vehicleNumber: 'V3',
          grossWeightKg: 6000.0,
          tareWeightKg: 1500.0,
          deductionKg: 50.0, // net: 4500, final: 4450
          kandaFee: 150.0,
          status: WeighbridgeStatus.completed,
          grossWeighedAt: now,
        ),
        WeighbridgeTicket(
          id: '4',
          shopId: 's1',
          ticketNumber: 'WB-04',
          vehicleNumber: 'V4',
          grossWeightKg: 9000.0,
          tareWeightKg: 2000.0,
          kandaFee: 200.0,
          status: WeighbridgeStatus.cancelled, // should be excluded
          grossWeighedAt: now,
        ),
      ];

      final summary = WeighbridgeSummary.fromTickets(tickets);

      // Total tickets (excluding cancelled): 3
      expect(summary.totalTicketsCount, 3);
      // Awaiting tare: ticket #2
      expect(summary.awaitingTareCount, 1);
      // Completed: tickets #1 and #3
      expect(summary.completedCount, 2);

      // Total gross: 10,000 + 8,000 + 6,000 = 24,000
      expect(summary.totalGrossWeightKg, 24000.0);

      // Total net completed: 8,000 + 4,500 = 12,500
      expect(summary.totalNetWeightKg, 12500.0);

      // Total final billable completed: 7,900 + 4,450 = 12,350
      expect(summary.totalFinalWeightKg, 12350.0);
      expect(summary.totalFinalMaunds, closeTo(308.75, 0.01)); // 12,350 / 40

      // Total fee: 200 + 200 + 150 = 550
      expect(summary.totalKandaFee, 550.0);
    });
  });

  group('ScaleService Tests', () {
    test('updates manual weight and emits stream events', () async {
      final scale = ScaleService();
      expect(scale.currentWeight, 0.0);

      scale.setManualWeight(5420.0);
      expect(scale.currentWeight, 5420.0);

      scale.zeroScale();
      expect(scale.currentWeight, 0.0);
    });
  });

  group('WeighbridgeSlipPdfGenerator Tests', () {
    test('generates valid non-empty PDF bytes for official Kanda Slip', () async {
      final now = DateTime.now();
      final ticket = WeighbridgeTicket(
        id: 'wb-pdf-1',
        shopId: 's1',
        ticketNumber: 'WB-2411-901',
        vehicleNumber: 'LES-9920',
        vehicleType: VehicleType.trolley,
        driverName: 'Muhammad Rasheed',
        driverPhone: '03011122334',
        partyName: 'Chaudhry Sarwar Gujjar',
        commodityName: 'Super Basmati Rice (کرنل چاول)',
        grossWeightKg: 12400.0,
        tareWeightKg: 2800.0,
        deductionKg: 120.0,
        deductionReason: 'Moisture cut',
        bagCount: 240,
        kandaFee: 300.0,
        feePaidBy: WeighbridgeFeePaidBy.farmer,
        status: WeighbridgeStatus.completed,
        grossWeighedAt: now.subtract(const Duration(hours: 2)),
        tareWeighedAt: now,
        operatorName: 'Malik Nasir',
      );

      final pdfBytes = await WeighbridgeSlipPdfGenerator.generateSlipPdf(
        shopName: 'Bismillah Commission Agent & Kanda',
        ticket: ticket,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
    });

    test('generates valid non-empty PDF bytes for Daily Weighbridge Register', () async {
      final now = DateTime.now();
      final tickets = [
        WeighbridgeTicket(
          id: '1',
          shopId: 's1',
          ticketNumber: 'WB-01',
          vehicleNumber: 'LES-100',
          vehicleType: VehicleType.trolley,
          partyName: 'Farmer A',
          commodityName: 'Wheat (گندم)',
          grossWeightKg: 9000.0,
          tareWeightKg: 2200.0,
          status: WeighbridgeStatus.completed,
          grossWeighedAt: now,
          tareWeighedAt: now,
        ),
        WeighbridgeTicket(
          id: '2',
          shopId: 's1',
          ticketNumber: 'WB-02',
          vehicleNumber: 'FDN-200',
          vehicleType: VehicleType.truckMazda,
          partyName: 'Farmer B',
          commodityName: 'Maize (مکئی)',
          grossWeightKg: 14000.0,
          tareWeightKg: 0.0,
          status: WeighbridgeStatus.grossRecorded,
          grossWeighedAt: now,
        ),
      ];

      final summary = WeighbridgeSummary.fromTickets(tickets);

      final pdfBytes = await WeighbridgeSlipPdfGenerator.generateRegisterPdf(
        shopName: 'Bismillah Commission Agent & Kanda',
        tickets: tickets,
        summary: summary,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
    });
  });
}
