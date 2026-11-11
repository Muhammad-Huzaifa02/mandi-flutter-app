// Provider for Live Auction (Boli) Digital Floor Terminal
// (*لائیو نیلامی بولی اسکرین و پھڑ ٹرمینل*).

import 'dart:async';
import 'package:flutter/foundation.dart';

class AuctionBidEntry {
  final int paddleNumber;
  final String buyerName;
  final String? buyerId;
  final double bidPerMaund;
  final DateTime timestamp;

  AuctionBidEntry({
    required this.paddleNumber,
    required this.buyerName,
    this.buyerId,
    required this.bidPerMaund,
    required this.timestamp,
  });
}

class AuctionBoliProvider extends ChangeNotifier {
  String? _shopId;

  // Current Lot / Heap State
  String _lotCode = 'HEAP-01';
  String _cropCommodity = 'Wheat (گندم)';
  String _farmerName = 'Chaudhry Riaz (چوہدری ریاض)';
  String? _farmerSupplierId;
  double _heapMaunds = 50.0; // 50 Maunds = 2000 KG
  int _estimatedBags = 50;
  double _basePricePerMaund = 3800.0;
  double _currentBidPerMaund = 3800.0;

  // Selected Buyer
  int _selectedPaddleNumber = 12;
  String _selectedBuyerName = 'Haji Mukhtar Traders';
  String? _selectedBuyerId;

  // Gavel State
  int _gavelCount = 0; // 0 = ready, 1 = "ایک!", 2 = "دو!", 3 = "تین — ہو گیا!"
  bool _isAuctionLocked = false;
  String _gavelMessage = '';
  bool _soundCueTriggered = false;

  // Bids History
  final List<AuctionBidEntry> _bidHistory = [];

  // Loading
  bool _isFinalizing = false;
  String? _errorMessage;

  // Getters
  String? get shopId => _shopId;
  String get lotCode => _lotCode;
  String get cropCommodity => _cropCommodity;
  String get farmerName => _farmerName;
  String? get farmerSupplierId => _farmerSupplierId;
  double get heapMaunds => _heapMaunds;
  int get estimatedBags => _estimatedBags;
  double get basePricePerMaund => _basePricePerMaund;
  double get currentBidPerMaund => _currentBidPerMaund;

  int get selectedPaddleNumber => _selectedPaddleNumber;
  String get selectedBuyerName => _selectedBuyerName;
  String? get selectedBuyerId => _selectedBuyerId;

  int get gavelCount => _gavelCount;
  bool get isAuctionLocked => _isAuctionLocked;
  String get gavelMessage => _gavelMessage;
  bool get soundCueTriggered => _soundCueTriggered;
  List<AuctionBidEntry> get bidHistory => List.unmodifiable(_bidHistory);
  bool get isFinalizing => _isFinalizing;
  String? get errorMessage => _errorMessage;

  double get currentTotalGrossValue => _heapMaunds * _currentBidPerMaund;

  void updateShop(String? shopId) {
    if (_shopId != shopId) {
      _shopId = shopId;
      resetAuction();
    }
  }

  void initializeLot({
    required String lotCode,
    required String cropCommodity,
    required String farmerName,
    String? farmerSupplierId,
    required double heapMaunds,
    required int estimatedBags,
    required double basePricePerMaund,
  }) {
    _lotCode = lotCode;
    _cropCommodity = cropCommodity;
    _farmerName = farmerName;
    _farmerSupplierId = farmerSupplierId;
    _heapMaunds = heapMaunds;
    _estimatedBags = estimatedBags;
    _basePricePerMaund = basePricePerMaund;
    _currentBidPerMaund = basePricePerMaund;

    _gavelCount = 0;
    _isAuctionLocked = false;
    _gavelMessage = '';
    _soundCueTriggered = false;
    _bidHistory.clear();

    notifyListeners();
  }

  void selectBuyer({required int paddleNumber, required String buyerName, String? buyerId}) {
    if (_isAuctionLocked) return;
    _selectedPaddleNumber = paddleNumber;
    _selectedBuyerName = buyerName;
    _selectedBuyerId = buyerId;
    notifyListeners();
  }

  void incrementBid(double delta) {
    if (_isAuctionLocked) return;
    _currentBidPerMaund += delta;
    _gavelCount = 0; // reset gavel count on new bid
    _gavelMessage = '';

    _bidHistory.insert(
      0,
      AuctionBidEntry(
        paddleNumber: _selectedPaddleNumber,
        buyerName: _selectedBuyerName,
        buyerId: _selectedBuyerId,
        bidPerMaund: _currentBidPerMaund,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void setCustomBid(double newBid) {
    if (_isAuctionLocked || newBid < _basePricePerMaund) return;
    _currentBidPerMaund = newBid;
    _gavelCount = 0;
    _gavelMessage = '';

    _bidHistory.insert(
      0,
      AuctionBidEntry(
        paddleNumber: _selectedPaddleNumber,
        buyerName: _selectedBuyerName,
        buyerId: _selectedBuyerId,
        bidPerMaund: _currentBidPerMaund,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void strikeGavel() {
    if (_isAuctionLocked) return;

    if (_gavelCount == 0) {
      _gavelCount = 1;
      _gavelMessage = 'ایک! (Ek - First Call)';
    } else if (_gavelCount == 1) {
      _gavelCount = 2;
      _gavelMessage = 'دو! (Do - Second Call)';
    } else if (_gavelCount == 2) {
      _gavelCount = 3;
      _gavelMessage = 'تین — ہو گیا! (Teen - SOLD!)';
      _isAuctionLocked = true;
      _soundCueTriggered = true;
    }
    notifyListeners();
  }

  void resetGavel() {
    _gavelCount = 0;
    _isAuctionLocked = false;
    _gavelMessage = '';
    _soundCueTriggered = false;
    notifyListeners();
  }

  void acknowledgeSoundCue() {
    _soundCueTriggered = false;
  }

  Future<bool> finalizeBoliAndLockSale({
    required double commissionRate, // e.g. 2.5%
    required double laborRatePerMaund, // e.g. Rs. 20/Maund
  }) async {
    if (_shopId == null || !_isAuctionLocked) return false;

    _isFinalizing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Ensure we have a product or consignment reference
      // If buyer ID is present, we create an invoice or consignment record
      // In Mandi, Boli locks the buyer.
      _isFinalizing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isFinalizing = false;
      notifyListeners();
      return false;
    }
  }

  void resetAuction() {
    _currentBidPerMaund = _basePricePerMaund;
    _gavelCount = 0;
    _isAuctionLocked = false;
    _gavelMessage = '';
    _soundCueTriggered = false;
    _bidHistory.clear();
    notifyListeners();
  }
}
