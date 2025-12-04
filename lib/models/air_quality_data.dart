class AirQualityData {
  final int aqi;
  final String cityName;
  final String dominantPollutant;
  final double temperature;
  final int humidity;
  final double wind;

  AirQualityData({
    required this.aqi,
    required this.cityName,
    required this.dominantPollutant,
    required this.temperature,
    required this.humidity,
    required this.wind,
  });

  factory AirQualityData.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is int) return v.toDouble();
      if (v is double) return v;
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    int aqi = 0;
    try {
      aqi = (json['aqi'] as num).toInt();
    } catch (_) {}

    final city = json['city'] != null ? (json['city']['name'] ?? 'Unknown') : 'Unknown';
    final dom = json['dominentpol'] ?? 'N/A';

    final iaqi = json['iaqi'] ?? {};
    final temp = parseDouble(iaqi['t']?['v']);
    final hum = (parseDouble(iaqi['h']?['v'])).toInt();
    final wind = parseDouble(iaqi['w']?['v']);

    return AirQualityData(
      aqi: aqi,
      cityName: city,
      dominantPollutant: dom,
      temperature: temp,
      humidity: hum,
      wind: wind,
    );
  }
}