import 'package:mandi/data/services/supabase_service.dart';
import 'package:mandi/domain/repositories/customer_repository_interface.dart';

/// Production Supabase Implementation of [ICustomerRepository]
class CustomerRepository implements ICustomerRepository {
  @override
  Stream<List<Map<String, dynamic>>> customersStream(String shopId) {
    return SupabaseService.customersStream(shopId);
  }

  @override
  Future<List<Map<String, dynamic>>> shopMembersForShop(String shopId) {
    return SupabaseService.shopMembersForShop(shopId);
  }
}
