import 'package:mandi/data/services/supabase_service.dart';
import 'package:mandi/domain/repositories/product_repository_interface.dart';

/// Production Supabase Implementation of [IProductRepository]
class ProductRepository implements IProductRepository {
  @override
  Stream<List<Map<String, dynamic>>> productsStream(String shopId) {
    return SupabaseService.productsStream(shopId);
  }

  @override
  Future<void> createProduct(Map<String, dynamic> productData) {
    return SupabaseService.addProduct(productData);
  }

  @override
  Future<void> updateProduct(String productId, Map<String, dynamic> updates) {
    return SupabaseService.updateProduct(productId, updates);
  }

  @override
  Future<void> deleteProduct(String productId) {
    return SupabaseService.deleteProduct(productId);
  }
}
