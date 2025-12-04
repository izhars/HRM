import '../app/constants.dart';
import 'network_service.dart';
import 'api_exception.dart';

class LeavesService {
  final NetworkService _network = NetworkService();

  final String baseUrl = "${AppConstants.apiBaseUrl}/leaves";

  // -------------------------
  // CANCEL LEAVE
  // -------------------------
  Future<Map<String, dynamic>> cancelLeave(String id) async {
    return await _network.put("/leaves/$id/cancel", {});
  }

  // -------------------------
  // PENDING LEAVES
  // -------------------------
  Future<List<dynamic>> getPendingLeaves() async {
    final data = await _network.get("/leaves/pending/all");
    return data['leaves'] ?? [];
  }

  // -------------------------
  // LEAVE BALANCE
  // -------------------------
  Future<Map<String, dynamic>> getLeaveBalance() async {
    final data = await _network.get("/leaves/balance");
    return data['leaveBalance'] ?? {};
  }

  // -------------------------
  // MY LEAVES
  // -------------------------
  Future<List<dynamic>> getMyLeaves({String? status}) async {
    final endpoint = status != null
        ? "/leaves?status=$status"
        : "/leaves";

    final data = await _network.get(endpoint);
    return data['leaves'] ?? [];
  }

  // -------------------------
  // APPLY LEAVE
  // -------------------------
  Future<Map<String, dynamic>> applyLeave(Map<String, dynamic> leaveData) async {
    return await _network.post("/leaves", leaveData);
  }

  // -------------------------
  // ALL LEAVES (Manager/HR)
  // -------------------------
  Future<List<dynamic>> getAllLeaves({String? status, String? year}) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (year != null) queryParams['year'] = year;

    final queryString = Uri(queryParameters: queryParams).query;
    final endpoint = "/leaves/all${queryString.isNotEmpty ? '?$queryString' : ''}";

    final data = await _network.get(endpoint);
    return data['leaves'] ?? [];
  }

  // -------------------------
  // APPROVE
  // -------------------------
  Future<void> approveLeave(String id) async {
    await _network.put("/leaves/$id/approve", {});
  }

  // -------------------------
  // REJECT
  // -------------------------
  Future<void> rejectLeave(String id, String reason) async {
    await _network.put(
      "/leaves/$id/reject",
      {"rejectionReason": reason},
    );
  }
}
