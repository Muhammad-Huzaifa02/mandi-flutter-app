import '../../data/models/weighbridge_ticket_model.dart';

/// Clean Architecture Contract for Weighbridge & Electronic Scale
abstract class IWeighbridgeRepository {
  Stream<List<WeighbridgeTicket>> ticketsStream(String shopId);
  Future<String> saveTicket(WeighbridgeTicket ticket);
  Future<void> updateTicket({
    required String ticketId,
    required String shopId,
    required Map<String, dynamic> data,
  });
  Future<void> cancelTicket({
    required String ticketId,
    required String shopId,
  });
}
