import 'dart:convert';
import 'dart:typed_data';

/// Text Alignment for ESC/POS commands
enum PosAlign { left, center, right }

/// Text size scaling for ESC/POS commands
enum PosTextSize { normal, doubleHeight, doubleWidth, doubleBoth }

/// Roll paper width standard
enum ThermalRollWidth {
  mm58(32, 58.0, '58mm Mobile Bluetooth'),
  mm80(48, 80.0, '80mm Desktop POS');

  final int maxColumns;
  final double widthMm;
  final String label;

  const ThermalRollWidth(this.maxColumns, this.widthMm, this.label);
}

/// Standard ESC/POS Command Byte Generator & Receipt Formatter.
///
/// Builds raw ESC/POS byte sequences compatible with 58mm & 80mm
/// Bluetooth and USB thermal receipt printers (e.g., PT-210, Rongta, Xprinter, Sunmi).
class EscPosCommandBuilder {
  final ThermalRollWidth rollWidth;
  final List<int> _buffer = [];
  final StringBuffer _textBuffer = StringBuffer();

  EscPosCommandBuilder({this.rollWidth = ThermalRollWidth.mm80}) {
    initialize();
  }

  int get maxCols => rollWidth.maxColumns;

  /// ESC @ - Initialize printer
  void initialize() {
    _buffer.addAll([0x1B, 0x40]);
  }

  /// Sets text alignment
  void setAlignment(PosAlign align) {
    int code;
    switch (align) {
      case PosAlign.left:
        code = 0x00;
        break;
      case PosAlign.center:
        code = 0x01;
        break;
      case PosAlign.right:
        code = 0x02;
        break;
    }
    _buffer.addAll([0x1B, 0x61, code]);
  }

  /// Sets text boldness
  void setBold(bool bold) {
    _buffer.addAll([0x1B, 0x45, bold ? 0x01 : 0x00]);
  }

  /// Sets text underline
  void setUnderline(bool underline) {
    _buffer.addAll([0x1B, 0x2D, underline ? 0x01 : 0x00]);
  }

  /// Sets text sizing
  void setTextSize(PosTextSize size) {
    int code;
    switch (size) {
      case PosTextSize.normal:
        code = 0x00;
        break;
      case PosTextSize.doubleHeight:
        code = 0x01;
        break;
      case PosTextSize.doubleWidth:
        code = 0x10;
        break;
      case PosTextSize.doubleBoth:
        code = 0x11;
        break;
    }
    _buffer.addAll([0x1D, 0x21, code]);
  }

  /// Adds a plain line of text with optional styling
  void text(
    String text, {
    PosAlign align = PosAlign.left,
    PosTextSize size = PosTextSize.normal,
    bool bold = false,
    bool underline = false,
  }) {
    setAlignment(align);
    setTextSize(size);
    setBold(bold);
    setUnderline(underline);

    _buffer.addAll(latin1.encode(text));
    _buffer.add(0x0A); // Newline LF

    // Text representation preview
    String previewLine = text;
    if (align == PosAlign.center) {
      previewLine = _padCenter(text, maxCols);
    } else if (align == PosAlign.right) {
      previewLine = _padLeft(text, maxCols);
    }
    _textBuffer.writeln(previewLine);

    // Reset styles
    if (bold) setBold(false);
    if (underline) setUnderline(false);
    if (size != PosTextSize.normal) setTextSize(PosTextSize.normal);
  }

  /// Adds a header block (centered, bold, double height/width)
  void header(String title, {String? subtitle, String? phone}) {
    text(title, align: PosAlign.center, size: PosTextSize.doubleBoth, bold: true);
    if (subtitle != null && subtitle.isNotEmpty) {
      text(subtitle, align: PosAlign.center, bold: false);
    }
    if (phone != null && phone.isNotEmpty) {
      text('Ph: $phone', align: PosAlign.center, bold: false);
    }
    divider();
  }

  /// Adds a 2-column key-value row with automatic space padding
  void row2({
    required String left,
    required String right,
    bool bold = false,
  }) {
    setAlignment(PosAlign.left);
    setBold(bold);

    final totalCols = maxCols;
    final leftLen = left.length;
    final rightLen = right.length;

    String line;
    if (leftLen + rightLen >= totalCols) {
      final availableLeft = totalCols - rightLen - 1;
      final truncatedLeft = availableLeft > 0 ? left.substring(0, availableLeft) : '';
      line = '$truncatedLeft $right';
    } else {
      final spaceCount = totalCols - leftLen - rightLen;
      line = '$left${' ' * spaceCount}$right';
    }

    _buffer.addAll(latin1.encode(line));
    _buffer.add(0x0A);
    _textBuffer.writeln(line);

    if (bold) setBold(false);
  }

  /// Adds a 3-column table row (e.g. Item, Qty, Total)
  void row3({
    required String col1,
    required String col2,
    required String col3,
    int flex1 = 5,
    int flex2 = 2,
    int flex3 = 3,
    bool bold = false,
  }) {
    setAlignment(PosAlign.left);
    setBold(bold);

    final totalFlex = flex1 + flex2 + flex3;
    final w1 = (maxCols * flex1 / totalFlex).floor();
    final w2 = (maxCols * flex2 / totalFlex).floor();
    final w3 = maxCols - w1 - w2;

    final c1 = _truncateOrPad(col1, w1, align: PosAlign.left);
    final c2 = _truncateOrPad(col2, w2, align: PosAlign.center);
    final c3 = _truncateOrPad(col3, w3, align: PosAlign.right);

    final line = '$c1$c2$c3';
    _buffer.addAll(latin1.encode(line));
    _buffer.add(0x0A);
    _textBuffer.writeln(line);

    if (bold) setBold(false);
  }

  /// Horizontal divider line (`-`)
  void divider({String char = '-'}) {
    setAlignment(PosAlign.center);
    final line = char * maxCols;
    _buffer.addAll(latin1.encode(line));
    _buffer.add(0x0A);
    _textBuffer.writeln(line);
  }

  /// Double horizontal divider line (`=`)
  void doubleDivider() {
    divider(char: '=');
  }

  /// Feeds [lines] empty lines
  void feed(int lines) {
    for (int i = 0; i < lines; i++) {
      _buffer.add(0x0A);
      _textBuffer.writeln();
    }
  }

  /// GS V - Cut paper
  void cut({bool partial = false}) {
    feed(3);
    _buffer.addAll([0x1D, 0x56, partial ? 0x01 : 0x00]);
  }

  /// Returns raw ESC/POS byte sequence
  Uint8List toBytes() {
    return Uint8List.fromList(_buffer);
  }

  /// Returns monospace plain text representation for UI preview
  String buildTextRepresentation() {
    return _textBuffer.toString();
  }

  // --- Helper padding string algorithms ---
  static String _padLeft(String s, int width) {
    if (s.length >= width) return s;
    return ' ' * (width - s.length) + s;
  }

  static String _padCenter(String s, int width) {
    if (s.length >= width) return s;
    final leftPadding = (width - s.length) ~/ 2;
    final rightPadding = width - s.length - leftPadding;
    return '${' ' * leftPadding}$s${' ' * rightPadding}';
  }

  static String _truncateOrPad(String s, int width, {PosAlign align = PosAlign.left}) {
    if (s.length > width) {
      return s.substring(0, width);
    }
    if (align == PosAlign.left) {
      return s + ' ' * (width - s.length);
    } else if (align == PosAlign.right) {
      return ' ' * (width - s.length) + s;
    } else {
      return _padCenter(s, width);
    }
  }
}
