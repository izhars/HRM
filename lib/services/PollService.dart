import 'network_service.dart';

class PollService {
  final NetworkService _network = NetworkService();

  /// Fetch all polls
  Future<List<dynamic>> fetchPolls() async {
    final data = await _network.get("/polls");
    return data['polls'] ?? [];
  }

  /// Submit vote for a specific poll option
  Future<Map<String, dynamic>> votePoll(String pollId, int optionIndex) async {
    final body = {'opts': optionIndex};
    final data = await _network.post("/polls/$pollId/vote", body);
    return {
      'success': data['success'] ?? false,
      'message': data['message'] ?? 'Vote recorded',
    };
  }

  /// Fetch poll results
  Future<Map<String, dynamic>> fetchPollResults(String pollId) async {
    final data = await _network.get("/polls/$pollId");
    return data['poll'] ?? {};
  }
}
