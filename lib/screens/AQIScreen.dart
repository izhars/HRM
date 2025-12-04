import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import '../models/air_quality_data.dart';
import '../services/aqi_service.dart';

class AQIScreen extends StatefulWidget {
  @override
  _AQIScreenState createState() => _AQIScreenState();
}

class _AQIScreenState extends State<AQIScreen>
    with SingleTickerProviderStateMixin {
  final AQIService _aqiService = AQIService();
  dynamic _rawData;
  AirQualityData? _currentData;
  bool _isLoading = true;
  String _searchQuery = 'Delhi';
  final TextEditingController _controller = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _aqiAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    // FIX: Clamp animation values between 0.0 and 1.0
    _aqiAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fetchAQI(_searchQuery);
    _controller.text = _searchQuery;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchAQI(String city) async {
    setState(() {
      _isLoading = true;
      _searchQuery = city;
    });

    try {
      final response = await http.get(Uri.parse(
          'https://api.waqi.info/feed/$city/?token=5412e87e1efe784aa7861e81376cb5ba55b145f6'));

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        if (jsonBody['status'] == 'ok') {
          if (mounted) {
            setState(() {
              _rawData = jsonBody['data'];
              _currentData = AirQualityData.fromJson(jsonBody['data']);
              _isLoading = false;
            });
            _animationController.forward(from: 0.0);
          }
        } else {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('City not found. Please try another.')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data. Please try again.')),
        );
      }
    }
  }

  Color _getAQIColor(int aqi) {
    if (aqi <= 50) return Color(0xFF00E676);
    if (aqi <= 100) return Color(0xFFFFEB3B);
    if (aqi <= 150) return Color(0xFFFF9800);
    if (aqi <= 200) return Color(0xFFF44336);
    if (aqi <= 300) return Color(0xFFD32F2F);
    return Color(0xFF8D0000);
  }

  String _getAQILevel(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for\nSensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildMainContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.air, color: Colors.white, size: 28),
              ),
              SizedBox(width: 12),
              Text(
                'Air Quality Index',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
            ),
            child: TextField(
              controller: _controller,
              onSubmitted: _fetchAQI,
              style: TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search city (e.g., Delhi, London)...',
                hintStyle: TextStyle(color: Colors.white60, fontSize: 15),
                prefixIcon: Icon(Icons.search, color: Colors.white70, size: 22),
                suffixIcon: _isLoading
                    ? Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return AnimatedBuilder(
      animation: _aqiAnimation,
      builder: (context, child) {
        // FIX: Clamp opacity value to ensure it's always between 0.0 and 1.0
        final clampedValue = _aqiAnimation.value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, 50 * (1 - clampedValue)),
          child: Opacity(
            opacity: clampedValue,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _buildMainAqiCard(),
                  SizedBox(height: 16),
                  _buildPollutantsGrid(),
                  SizedBox(height: 16),
                  _buildWeatherCard(),
                  SizedBox(height: 16),
                  if (_rawData?['forecast']?['daily']?['pm25'] != null)
                    _buildForecastCard(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainAqiCard() {
    if (_isLoading || _currentData == null) {
      return _buildLoadingCard();
    }

    final aqi = _currentData!.aqi;
    final color = _getAQIColor(aqi);
    final level = _getAQILevel(aqi);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // AQI Circle
          Stack(alignment: Alignment.center, children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.05),
                  Colors.transparent,
                ]),
              ),
            ),
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 6),
                color: color.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$aqi',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'AQI',
                  style: TextStyle(
                    fontSize: 16,
                    color: color.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ]),
          SizedBox(height: 24),
          // Level Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.4), width: 1.5),
            ),
            child: Text(
              level,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1.2,
              ),
            ),
          ),
          SizedBox(height: 20),
          // Location & Dominant Pollutant
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentData!.cityName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800]!,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Dominant: ${_currentData!.dominantPollutant.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600]!,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(Icons.warning_rounded, color: color, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPollutantsGrid() {
    if (_rawData?['iaqi'] == null) return SizedBox();

    final iaqi = _rawData!['iaqi'] as Map<String, dynamic>;
    final pollutants = <String, dynamic>{};

    ['pm25', 'pm10', 'o3', 'no2', 'so2', 'co'].forEach((key) {
      if (iaqi[key] != null && iaqi[key]['v'] != null) {
        pollutants[key] = iaqi[key]['v'];
      }
    });

    if (pollutants.isEmpty) return SizedBox();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF667eea).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.analytics_outlined, color: Color(0xFF667eea), size: 20),
            ),
            SizedBox(width: 12),
            Text(
              'Pollutants',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800]!,
              ),
            ),
          ]),
          SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.1,
            children: pollutants.entries.map((entry) {
              final key = entry.key;
              final value = entry.value;
              final color = _getPollutantColor(key);
              return Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.3), width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getPollutantName(key),
                      style: TextStyle(
                        fontSize: 11,
                        color: color.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getPollutantColor(String pollutant) {
    switch (pollutant) {
      case 'pm25':
        return Color(0xFF4CAF50);
      case 'pm10':
        return Color(0xFFFF9800);
      case 'o3':
        return Color(0xFF2196F3);
      case 'no2':
        return Color(0xFFF44336);
      case 'so2':
        return Color(0xFF9C27B0);
      case 'co':
        return Color(0xFFFF5722);
      default:
        return Colors.grey;
    }
  }

  String _getPollutantName(String key) {
    final names = {
      'pm25': 'PM2.5',
      'pm10': 'PM10',
      'o3': 'O₃',
      'no2': 'NO₂',
      'so2': 'SO₂',
      'co': 'CO',
    };
    return names[key] ?? key.toUpperCase();
  }

  Widget _buildWeatherCard() {
    if (_rawData?['iaqi'] == null) return SizedBox();

    final iaqi = _rawData!['iaqi'];
    final weatherData = <Map<String, dynamic>>[];

    if (iaqi['t']?['v'] != null) {
      weatherData.add({
        'icon': Icons.thermostat,
        'value': '${iaqi['t']['v'].toStringAsFixed(1)}°C',
        'label': 'Temp'
      });
    }
    if (iaqi['h']?['v'] != null) {
      weatherData.add({
        'icon': Icons.water_drop,
        'value': '${iaqi['h']['v'].toStringAsFixed(0)}%',
        'label': 'Humidity'
      });
    }
    if (iaqi['w']?['v'] != null) {
      weatherData.add({
        'icon': Icons.air,
        'value': '${iaqi['w']['v'].toStringAsFixed(1)} m/s',
        'label': 'Wind'
      });
    }
    if (iaqi['p']?['v'] != null) {
      weatherData.add({
        'icon': Icons.speed,
        'value': '${iaqi['p']['v'].toStringAsFixed(0)} hPa',
        'label': 'Pressure'
      });
    }

    if (weatherData.isEmpty) return SizedBox();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF667eea).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.wb_sunny_outlined, color: Color(0xFF667eea), size: 20),
            ),
            SizedBox(width: 12),
            Text(
              'Weather Conditions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800]!,
              ),
            ),
          ]),
          SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: weatherData.map((data) {
              return _buildWeatherMetric(
                data['icon'] as IconData,
                data['value'] as String,
                data['label'] as String,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherMetric(IconData icon, String value, String label) {
    return Container(
      width: (MediaQuery.of(context).size.width - 72) / 2,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF667eea).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF667eea).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF667eea).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Color(0xFF667eea), size: 20),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800]!,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600]!,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastCard() {
    if (_rawData?['forecast']?['daily']?['pm25'] == null) return SizedBox();

    final pm25Forecast = _rawData!['forecast']['daily']['pm25'] as List;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF667eea).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.trending_up, color: Color(0xFF667eea), size: 20),
            ),
            SizedBox(width: 12),
            Text(
              '7-Day PM2.5 Forecast',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800]!,
              ),
            ),
          ]),
          SizedBox(height: 16),
          ...pm25Forecast.take(7).map((forecast) {
            final avg = forecast['avg'] as int;
            final date = DateTime.parse(forecast['day']);
            final dayName = _getDayName(date);

            return Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      dayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700]!,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        minHeight: 24,
                        value: (avg / 300).clamp(0.0, 1.0),
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(_getAQIColor(avg)),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '$avg',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getAQIColor(avg),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  String _getDayName(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    }
    final tomorrow = now.add(Duration(days: 1));
    if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'Tomorrow';
    }
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      height: 300,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
          ),
          SizedBox(height: 20),
          Text(
            'Loading air quality data...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF667eea),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}