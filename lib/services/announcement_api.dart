import '../models/announcement.dart';
import 'network_service.dart';

class AnnouncementService {
  final NetworkService _network = NetworkService();

  Future<List<Announcement>> fetchAnnouncements() async {
    final data = await _network.get('/announcements');

    final List list = data['announcements'];
    return list.map((e) => Announcement.fromJson(e)).toList();
  }
}
