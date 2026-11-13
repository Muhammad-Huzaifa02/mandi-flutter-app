import 'package:mandi/data/models/weighbridge_ticket_model.dart';
import 'package:mandi/data/services/supabase_service.dart';
import 'package:mandi/domain/repositories/weighbridge_repository_interface.dart';

/// Production Supabase Implementation of [IWeighbridgeRepository]
class WeighbridgeRepository implements IWeighbridgeRepository {
  @override
  Stream<List<WeighbridgeTicket>> ticketsStream(String shopId) {
    return SupabaseService.weighbridgeTicketsStream(shopId).map(
      (list) => list
          .map((map) => WeighbridgeTicket.fromMap(map['id'] as String, map))
          .toList(),
    );
  }

  @override
  Future<String> saveTicket(WeighbridgeTicket ticket) {
    return SupabaseService.createWeighbridgeTicket(ticket.toMap());
  }

  @override
  Future<void> updateTicket({
    required String ticketId,
    required String shopId,
    required Map<String, dynamic> data,
  }) {
    return SupabaseService.updateWeighbridgeTicket(
      id: ticketId,
      shopId: shopId,
      data: data,
    );
  }

  @override
  Future<void> cancelTicket({
    required String ticketId,
    required String shopId,
  }) {
    return SupabaseService.cancelWeighbridgeTicket(
      id: ticketId,
      shopId: shopId,
    );
  }
}
