import 'package:mandi/data/services/supabase_service.dart';
import 'package:mandi/domain/repositories/farmer_repository_interface.dart';

/// Production Supabase Implementation of [IFarmerRepository]
class FarmerRepository implements IFarmerRepository {
  @override
  Stream<List<Map<String, dynamic>>> farmersStream(String shopId) {
    return SupabaseService.suppliersStream(shopId);
  }

  @override
  Future<List<Map<String, dynamic>>> shopMembersForShop(String shopId) {
    return SupabaseService.shopMembersForShop(shopId);
  }
}
