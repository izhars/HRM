import '../models/ComboOff.dart';
import 'network_service.dart';

class ComboApi {
  final NetworkService _network = NetworkService();

  /// GET MY COMBO-OFF LIST
  Future<List<ComboOff>> getMyComboOffs() async {
    final data = await _network.get("/combooff/me");
    final List list = data['comboOffs'] ?? [];
    return list.map((e) => ComboOff.fromJson(e)).toList();
  }

  /// APPLY COMBO-OFF
  Future<bool> applyComboOff(String reason, DateTime date) async {
    final body = {
      'reason': reason,
      'workDate': date.toIso8601String(),
    };

    final data = await _network.post("/combooff", body);
    return data['success'] == true;
  }

  /// DELETE COMBO-OFF
  Future<bool> deleteComboOff(String id) async {
    final data = await _network.delete("/combooff/$id");
    return data['success'] == true;
  }
}
