/// Clean Architecture Contract for Customer / Buyer Management
abstract class ICustomerRepository {
  Stream<List<Map<String, dynamic>>> customersStream(String shopId);
  Future<List<Map<String, dynamic>>> shopMembersForShop(String shopId);
}
