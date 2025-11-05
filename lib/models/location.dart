class LocationModel {
  final double latitude;
  final double longitude;
  final String? address;
  final String? name;
  final String? city;
  final String? state;

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.address,
    this.name,
    this.city,
    this.state
  });
}