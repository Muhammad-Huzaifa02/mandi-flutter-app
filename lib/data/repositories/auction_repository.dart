import 'package:mandi/data/services/supabase_service.dart';
import 'package:mandi/domain/repositories/auction_repository_interface.dart';

/// Production Supabase Implementation of [IAuctionRepository]
class AuctionRepository implements IAuctionRepository {
  @override
  Stream<List<Map<String, dynamic>>> consignmentLotsStream(String shopId) {
    return SupabaseService.consignmentLotsStream(shopId);
  }
}
