import 'network_service.dart';

class EmployeeService {
  final NetworkService _network = NetworkService();

  /// Get all HRs
  Future<List<Map<String, dynamic>>> getAllHRs() async {
    final data = await _network.get("/employees/hr");
    return List<Map<String, dynamic>>.from(data['hrs'] ?? []);
  }
}
