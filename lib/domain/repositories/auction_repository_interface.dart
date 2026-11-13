/// Clean Architecture Contract for Live Auction Floor & Consignment Lots
abstract class IAuctionRepository {
  Stream<List<Map<String, dynamic>>> consignmentLotsStream(String shopId);
}
