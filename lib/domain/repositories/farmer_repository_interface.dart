/// Clean Architecture Contract for Farmer / Supplier Khata
abstract class IFarmerRepository {
  Stream<List<Map<String, dynamic>>> farmersStream(String shopId);
  Future<List<Map<String, dynamic>>> shopMembersForShop(String shopId);
}
