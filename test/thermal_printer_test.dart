import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

import 'package:mandi/core/utils/esc_pos_command_builder.dart';
import 'package:mandi/core/utils/thermal_receipt_service.dart';
import 'package:mandi/data/models/consignment_lot_model.dart';
import 'package:mandi/data/models/farmer_advance_model.dart';
import 'package:mandi/data/models/invoice_model.dart';
import 'package:mandi/data/models/weighbridge_ticket_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EscPosCommandBuilder Tests', () {
    test('initializes with ESC @ and sets roll width parameters correctly', () {
      final builder58 = EscPosCommandBuilder(rollWidth: ThermalRollWidth.mm58);
      expect(builder58.maxCols, 32);
      expect(builder58.rollWidth.widthMm, 58.0);

      final bytes = builder58.toBytes();
      expect(bytes.length, greaterThanOrEqualTo(2));
      expect(bytes[0], 0x1B);
      expect(bytes[1], 0x40);

      final builder80 = EscPosCommandBuilder(rollWidth: ThermalRollWidth.mm80);
      expect(builder80.maxCols, 48);
      expect(builder80.rollWidth.widthMm, 80.0);
    });

    test('adds text and formats alignment, boldness, and text size', () {
      final builder = EscPosCommandBuilder(rollWidth: ThermalRollWidth.mm80);
      builder.text('CENTERED HEADER',
          align: PosAlign.center, bold: true, size: PosTextSize.doubleBoth);
      builder.text('LEFT BODY', align: PosAlign.left, bold: false);
      builder.text('RIGHT FOOTER', align: PosAlign.right);

      final bytes = builder.toBytes();
      expect(bytes, isNotEmpty);

      final preview = builder.buildTextRepresentation();
      expect(preview, contains('CENTERED HEADER'));
      expect(preview, contains('LEFT BODY'));
      expect(preview, contains('RIGHT FOOTER'));
    });

    test('formats 2-column key-value row with correct space padding', () {
      final builder = EscPosCommandBuilder(rollWidth: ThermalRollWidth.mm58);
      builder.row2(left: 'Subtotal:', right: 'Rs. 45000');

      final preview = builder.buildTextRepresentation();
      final lines = preview.split('\n');
      expect(lines.isNotEmpty, isTrue);

      final firstLine = lines.first;
      expect(firstLine.length, equals(32));
      expect(firstLine.startsWith('Subtotal:'), isTrue);
      expect(firstLine.endsWith('Rs. 45000'), isTrue);
    });

    test('formats 3-column table row with proportional flex widths', () {
      final builder = EscPosCommandBuilder(rollWidth: ThermalRollWidth.mm80);
      builder.row3(col1: 'Basmati Rice', col2: '50B', col3: 'Rs.150000');

      final preview = builder.buildTextRepresentation();
      expect(preview, contains('Basmati Rice'));
      expect(preview, contains('50B'));
      expect(preview, contains('Rs.150000'));
    });

    test('emits dividers, feed lines, and cut command', () {
      final builder = EscPosCommandBuilder(rollWidth: ThermalRollWidth.mm58);
      builder.divider();
      builder.doubleDivider();
      builder.feed(2);
      builder.cut(partial: true);

      final bytes = builder.toBytes();
      expect(bytes, isNotEmpty);
      // Cut command GS V 0x01
      expect(bytes.contains(0x1D), isTrue);
      expect(bytes.contains(0x56), isTrue);

      final preview = builder.buildTextRepresentation();
      expect(preview, contains('--------------------------------'));
      expect(preview, contains('================================'));
    });
  });

  group('ThermalReceiptService Multi-Document Printing Tests', () {
    test('generates valid non-empty PDF for Sales Invoice thermal slip', () async {
      final invoice = Invoice(
        id: 'inv-101',
        shopId: 'shop-1',
        invoiceNumber: 'INV-2026-001',
        customerName: 'Chaudhry Akram Traders',
        subtotal: 100000.0,
        commission: 2000.0,
        expenses: 500.0,
        discount: 0.0,
        total: 102500.0,
        receivedAmount: 102500.0,
        pendingAmount: 0.0,
        createdAt: DateTime(2026, 3, 15),
        items: [
          const InvoiceItem(
            id: 'item-1',
            invoiceId: 'inv-101',
            productId: 'prod-1',
            productName: 'Super Kernel Rice',
            quantity: 50.0,
            weightKg: 2000.0,
            unitPrice: 2000.0,
            lineTotal: 100000.0,
          ),
        ],
      );

      final pdfBytes80 = await ThermalReceiptService.generateThermalReceiptPdf(
        invoice: invoice,
        shopName: 'Bismillah Fruit & Grain Mandi',
        shopCity: 'Okara',
        shopPhone: '0300-1122334',
        rollWidthMm: 80,
      );

      expect(pdfBytes80, isNotNull);
      expect(pdfBytes80.length, greaterThan(100));
      final headerStr = utf8.decode(pdfBytes80.sublist(0, 5), allowMalformed: true);
      expect(headerStr, equals('%PDF-'));

      final pdfBytes58 = await ThermalReceiptService.generateThermalReceiptPdf(
        invoice: invoice,
        shopName: 'Bismillah Fruit & Grain Mandi',
        rollWidthMm: 58,
      );
      expect(pdfBytes58.length, greaterThan(100));
    });

    test('generates valid non-empty PDF for Auction Boli Slip', () async {
      final lot = ConsignmentLot(
        id: 'lot-88',
        shopId: 'shop-1',
        lotNumber: 'LOT-2026-088',
        supplierName: 'Malik Tariq Farmer',
        productName: 'Wheat / گندم',
        vehicleNumber: 'MN-7860',
        bagCount: 100,
        weightKg: 4000.0, // 100 Maunds
        ratePerMaund: 3800.0,
        winningBuyerName: 'Al-Madina Flour Mills',
        status: ConsignmentLotStatus.sold,
        createdAt: DateTime(2026, 4, 10),
      );

      final pdfBytes = await ThermalReceiptService.generateBoliSlipPdf(
        lot: lot,
        shopName: 'Ittefaq Commission Shop',
        shopCity: 'Sahiwal',
        shopPhone: '0301-7654321',
        rollWidthMm: 80,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(100));
      expect(utf8.decode(pdfBytes.sublist(0, 5), allowMalformed: true), equals('%PDF-'));
    });

    test('generates valid non-empty PDF for Weighbridge Kanda Slip', () async {
      final ticket = WeighbridgeTicket(
        id: 'kanda-01',
        shopId: 'shop-1',
        ticketNumber: 'WB-2026-0045',
        vehicleNumber: 'LES-9988',
        vehicleType: VehicleType.truckMazda,
        driverName: 'Muhammad Aslam',
        partyName: 'Haji Sharif & Sons',
        commodityName: 'Paddy Basmati Rice',
        grossWeightKg: 16500.0,
        tareWeightKg: 6500.0,
        netWeightKg: 10000.0,
        deductionKg: 200.0,
        deductionReason: 'Moisture 2% + Dirt',
        finalWeightKg: 9800.0,
        bagCount: 200,
        kandaFee: 600.0,
        grossWeighedAt: DateTime(2026, 5, 1, 10, 30),
        tareWeighedAt: DateTime(2026, 5, 1, 11, 45),
        status: WeighbridgeStatus.completed,
      );

      final pdfBytes = await ThermalReceiptService.generateWeighbridgeSlipPdf(
        ticket: ticket,
        shopName: 'Computerized Mandi Kanda',
        shopCity: 'Gojra',
        shopPhone: '0321-9876543',
        rollWidthMm: 80,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(100));
      expect(utf8.decode(pdfBytes.sublist(0, 5), allowMalformed: true), equals('%PDF-'));
    });

    test('generates valid non-empty PDF for Cash Khata Payment Receipt', () async {
      final pdfBytes = await ThermalReceiptService.generatePaymentReceiptPdf(
        receiptNumber: 'RCP-2026-0542',
        partyName: 'Bismillah Fruit Traders',
        partyType: 'Customer / Buyer',
        amount: 85000.0,
        previousBalance: 245000.0,
        remainingBalance: 160000.0,
        paymentMethod: 'Cash',
        referenceNumber: 'Handed to Munshi',
        shopName: 'New Sabzi & Fruit Mandi Aarthi',
        shopCity: 'Faisalabad',
        shopPhone: '0300-4455667',
        rollWidthMm: 80,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(100));
      expect(utf8.decode(pdfBytes.sublist(0, 5), allowMalformed: true), equals('%PDF-'));
    });

    test('generates valid non-empty PDF for Farmer Advance Loan Recovery Slip', () async {
      final advance = FarmerAdvance(
        id: 'adv-99',
        shopId: 'shop-1',
        supplierId: 'sup-55',
        farmerName: 'Chaudhry Manzoor Ahmad',
        advanceType: FarmerAdvanceType.fertilizer,
        description: '50 Bags DAP Fertilizer',
        principalAmount: 500000.0,
        totalPayable: 550000.0,
        recoveredAmount: 200000.0,
        remainingBalance: 350000.0,
        disbursementDate: DateTime(2025, 11, 1),
        targetCrop: 'Wheat Rabi 2026',
      );

      final recovery = FarmerAdvanceRecovery(
        id: 'rec-0077',
        shopId: 'shop-1',
        advanceId: 'adv-99',
        recoveredAmount: 200000.0,
        recoveryDate: DateTime(2026, 4, 25),
        recoveryMethod: 'auction_deduction',
        notes: 'Deducted from Lot #LOT-2026-088 payout',
      );

      final pdfBytes = await ThermalReceiptService.generateAdvanceRecoverySlipPdf(
        advance: advance,
        recovery: recovery,
        shopName: 'Madina Kissan Commission Shop',
        shopCity: 'Bahawalpur',
        shopPhone: '0302-3344556',
        rollWidthMm: 80,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(100));
      expect(utf8.decode(pdfBytes.sublist(0, 5), allowMalformed: true), equals('%PDF-'));
    });

    test('generates valid non-empty PDF for Printer Hardware Test Slip', () async {
      final pdfBytes = await ThermalReceiptService.generateTestSlipPdf(
        shopName: 'Test Mandi Shop POS',
        shopCity: 'Lahore',
        shopPhone: '0300-0000000',
        rollWidthMm: 58,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(100));
      expect(utf8.decode(pdfBytes.sublist(0, 5), allowMalformed: true), equals('%PDF-'));
    });

    test('builds raw ESC/POS byte sequences for Invoice and Boli slip', () {
      const invoice = Invoice(
        id: 'inv-1',
        shopId: 's1',
        invoiceNumber: 'INV-001',
        customerName: 'Ahmad Trader',
        subtotal: 50000.0,
        total: 50000.0,
        receivedAmount: 50000.0,
        pendingAmount: 0.0,
        items: [
          InvoiceItem(
            id: 'it-1',
            invoiceId: 'inv-1',
            productId: 'prod-rice',
            productName: 'Rice',
            quantity: 20,
            weightKg: 800,
            unitPrice: 2500,
            lineTotal: 50000,
          ),
        ],
      );

      final invoiceBytes = ThermalReceiptService.buildInvoiceEscPosBytes(
        invoice: invoice,
        shopName: 'Al-Rehman Shop',
        shopCity: 'Multan',
        shopPhone: '0300-1234567',
        rollWidth: ThermalRollWidth.mm80,
      );
      expect(invoiceBytes, isNotEmpty);
      expect(invoiceBytes.length, greaterThan(50));

      const lot = ConsignmentLot(
        id: 'l-1',
        shopId: 's1',
        lotNumber: 'LOT-01',
        supplierName: 'Bashir Farmer',
        productName: 'Cotton',
        bagCount: 40,
        weightKg: 1600,
        ratePerMaund: 8500,
        winningBuyerName: 'Textile Mill',
      );

      final boliBytes = ThermalReceiptService.buildBoliEscPosBytes(
        lot: lot,
        shopName: 'Al-Rehman Shop',
        shopCity: 'Multan',
        rollWidth: ThermalRollWidth.mm58,
      );
      expect(boliBytes, isNotEmpty);
      expect(boliBytes.length, greaterThan(50));
    });
  });
}
