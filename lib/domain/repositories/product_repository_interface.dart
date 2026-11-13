/// Clean Architecture Contract for Products & Inventory
abstract class IProductRepository {
  Stream<List<Map<String, dynamic>>> productsStream(String shopId);
  Future<void> createProduct(Map<String, dynamic> productData);
  Future<void> updateProduct(String productId, Map<String, dynamic> updates);
  Future<void> deleteProduct(String productId);
}
