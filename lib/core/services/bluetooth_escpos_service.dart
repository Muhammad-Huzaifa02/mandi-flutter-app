import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

/// Hardware abstraction & direct thermal ESC/POS binding service.
/// Connects to 58mm and 80mm Mandi thermal receipt printers via Bluetooth RFCOMM socket,
/// with robust fallback to platform graphics rasterization.
class BluetoothEscPosService {
  static const MethodChannel _channel = MethodChannel('com.mandi.app/thermal_printer');

  /// Standard ESC/POS Command Byte Constants
  static const List<int> cmdInit = [0x1B, 0x40]; // Initialize printer
  static const List<int> cmdAlignLeft = [0x1B, 0x61, 0x00];
  static const List<int> cmdAlignCenter = [0x1B, 0x61, 0x01];
  static const List<int> cmdAlignRight = [0x1B, 0x61, 0x02];
  static const List<int> cmdBoldOn = [0x1B, 0x45, 0x01];
  static const List<int> cmdBoldOff = [0x1B, 0x45, 0x00];
  static const List<int> cmdDoubleHeight = [0x1D, 0x21, 0x01];
  static const List<int> cmdNormalText = [0x1D, 0x21, 0x00];
  static const List<int> cmdFeedAndCut = [0x1D, 0x56, 0x42, 0x00]; // Full cut with feed

  /// Discovers paired Mandi Bluetooth ESC/POS printers.
  static Future<List<Map<String, String>>> getPairedBluetoothPrinters() async {
    try {
      final List<dynamic>? devices = await _channel.invokeMethod('getPairedPrinters');
      if (devices != null) {
        return devices.map((d) => Map<String, String>.from(d as Map)).toList();
      }
    } on PlatformException catch (_) {
      // Fallback via Printing plugin's direct printer discovery
      final printers = await Printing.listPrinters();
      return printers
          .map((p) => {
                'name': p.name,
                'address': p.url,
                'isDefault': p.isDefault.toString(),
              })
          .toList();
    }
    return [];
  }

  /// Sends raw ESC/POS byte sequence over RFCOMM socket.
  static Future<bool> sendRawBytes({
    required String macAddress,
    required Uint8List bytes,
  }) async {
    try {
      final bool? success = await _channel.invokeMethod('sendRawBytes', {
        'macAddress': macAddress,
        'bytes': bytes,
      });
      return success ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// High-reliability printing pipeline:
  /// Tries direct RFCOMM byte stream first, falls back to Printing.directPrintPdf
  static Future<bool> printDocument({
    required String printerName,
    required Uint8List pdfBytes,
    String? macAddress,
  }) async {
    if (macAddress != null && macAddress.isNotEmpty) {
      final rawFormatted = buildEscPosHeader(printerName);
      final rawSuccess = await sendRawBytes(
        macAddress: macAddress,
        bytes: Uint8List.fromList(rawFormatted),
      );
      if (rawSuccess) return true;
    }

    // Direct platform printing fallback
    try {
      return await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: printerName,
      );
    } catch (_) {
      return false;
    }
  }

  /// Generates ESC/POS test pattern header.
  static List<int> buildEscPosHeader(String title) {
    final bytes = <int>[];
    bytes.addAll(cmdInit);
    bytes.addAll(cmdAlignCenter);
    bytes.addAll(cmdBoldOn);
    bytes.addAll(cmdDoubleHeight);
    bytes.addAll(title.codeUnits);
    bytes.add(0x0A); // New line
    bytes.addAll(cmdNormalText);
    bytes.addAll(cmdBoldOff);
    bytes.addAll('--- Mandi Terminal Receipt ---'.codeUnits);
    bytes.add(0x0A);
    bytes.addAll(cmdAlignLeft);
    return bytes;
  }
}
