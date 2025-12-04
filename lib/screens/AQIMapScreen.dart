import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AQIMapScreen extends StatefulWidget {
  @override
  _AQIMapScreenState createState() => _AQIMapScreenState();
}

class _AQIMapScreenState extends State<AQIMapScreen> {
  static const String olaApiKey = '81BdA7HuHsQVRzEShFlU0BZTyAjpmDBaxd4zBmiJ';
  bool _isLoading = true;
  List<dynamic> _stations = [];
  dynamic _selectedStation;

  // Delhi bounds for coordinate mapping
  final double minLat = 28.4;
  final double maxLat = 28.9;
  final double minLon = 76.8;
  final double maxLon = 77.4;

  @override
  void initState() {
    super.initState();
    _fetchStations();
  }

  Future<void> _fetchStations() async {
    setState(() => _isLoading = true);

    try {
      print('Fetching AQI data...');
      final response = await http.get(Uri.parse(
          'https://api.waqi.info/map/bounds?token=$olaApiKey&latlng=$minLat,$minLon,$maxLat,$maxLon'));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        print('API Status: ${jsonBody['status']}');

        if (jsonBody['status'] == 'ok') {
          final data = jsonBody['data'] as List;
          print('Found ${data.length} stations');

          if (mounted) {
            setState(() {
              _stations = data.where((station) => station['aqi'] != '-').toList();
              _isLoading = false;
            });
          }
        } else {
          print('API Error: ${jsonBody['data']}');
          _loadDemoData();
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        _loadDemoData();
      }
    } catch (e) {
      print('Network Error: $e');
      _loadDemoData();
    }
  }

  void _loadDemoData() {
    print('Loading demo data...');
    // Demo data for Delhi area with proper coordinates
    final demoStations = [
      {
        'lat': 28.6139, 'lon': 77.2090, 'aqi': 156,
        'station': {'name': 'Delhi Central, Delhi'}
      },
      {
        'lat': 28.7041, 'lon': 77.1025, 'aqi': 189,
        'station': {'name': 'North Delhi, Delhi'}
      },
      {
        'lat': 28.4595, 'lon': 77.0266, 'aqi': 142,
        'station': {'name': 'Gurugram, Haryana'}
      },
      {
        'lat': 28.5355, 'lon': 77.3910, 'aqi': 167,
        'station': {'name': 'East Delhi, Delhi'}
      },
      {
        'lat': 28.4089, 'lon': 77.3178, 'aqi': 134,
        'station': {'name': 'Faridabad, Haryana'}
      },
      {
        'lat': 28.6792, 'lon': 77.0697, 'aqi': 178,
        'station': {'name': 'Rohini, Delhi'}
      },
      {
        'lat': 28.5744, 'lon': 77.1997, 'aqi': 195,
        'station': {'name': 'Connaught Place, Delhi'}
      },
      {
        'lat': 28.4999, 'lon': 77.2689, 'aqi': 145,
        'station': {'name': 'South Delhi, Delhi'}
      },
      {
        'lat': 28.7233, 'lon': 77.2712, 'aqi': 167,
        'station': {'name': 'Ghaziabad, UP'}
      },
    ];

    if (mounted) {
      setState(() {
        _stations = demoStations;
        _isLoading = false;
      });
    }
  }

  String _getShortName(String fullName) {
    final parts = fullName.split(',');
    return parts[0].trim();
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
    if (aqi <= 150) return 'Unhealthy for Sensitive';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                child: _isLoading
                    ? _buildLoading()
                    : _stations.isEmpty
                    ? _buildNoData()
                    : _buildMapView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delhi AQI Map',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (!_isLoading && _stations.isNotEmpty)
                      Text(
                        '${_stations.length} monitoring stations',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white, size: 28),
                onPressed: _fetchStations,
              ),
            ],
          ),
          if (!_isLoading && _stations.isNotEmpty)
            _buildAQIInfoBar(),
        ],
      ),
    );
  }

  Widget _buildAQIInfoBar() {
    final aqiValues = _stations.map((s) => int.parse(s['aqi'].toString())).toList();
    final avgAqi = (aqiValues.reduce((a, b) => a + b) / aqiValues.length).round();
    final color = _getAQIColor(avgAqi);
    final level = _getAQILevel(avgAqi);

    return Container(
      margin: EdgeInsets.only(top: 10),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Average AQI',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                '$avgAqi - $level',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              level.split(' ')[0],
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 20),
          Text(
            'Loading AQI Data...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoData() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.white, size: 64),
          SizedBox(height: 20),
          Text(
            'No AQI Data Available',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Check your API key or internet connection',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchStations,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF667eea),
            ),
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Enhanced map background
                  CustomPaint(
                    painter: DelhiMapPainter(),
                    child: Container(),
                  ),

                  // Station markers
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: _stations.map((station) {
                          final lat = station['lat'] as double;
                          final lon = station['lon'] as double;
                          final aqi = int.parse(station['aqi'].toString());

                          // Convert lat/lon to screen coordinates with bounds checking
                          double x = ((lon - minLon) / (maxLon - minLon)) * constraints.maxWidth;
                          double y = ((maxLat - lat) / (maxLat - minLat)) * constraints.maxHeight;

                          // Ensure markers stay within bounds
                          x = x.clamp(10.0, constraints.maxWidth - 10);
                          y = y.clamp(10.0, constraints.maxHeight - 10);

                          return Positioned(
                            left: x - 20,
                            top: y - 20,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _selectedStation = _selectedStation == station ? null : station;
                              }),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _getAQIColor(aqi),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: _selectedStation == station ? 3 : 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getAQIColor(aqi).withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: _selectedStation == station ? 3 : 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '$aqi',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  // Legend
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: _buildLegend(),
                  ),

                  // Map title
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Delhi Region',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Station card and stats
        if (_selectedStation != null) _buildStationCard(),
        _buildStatsCard(),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStationCard() {
    final aqi = int.parse(_selectedStation['aqi'].toString());
    final color = _getAQIColor(aqi);
    final level = _getAQILevel(aqi);
    final name = _selectedStation['station']['name'] as String;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _getShortName(name),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.grey[600]),
                onPressed: () => setState(() => _selectedStation = null),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$aqi',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Air Quality Index',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                _getAQIIcon(aqi),
                color: color,
                size: 36,
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getAQIIcon(int aqi) {
    if (aqi <= 50) return Icons.sentiment_very_satisfied;
    if (aqi <= 100) return Icons.sentiment_satisfied;
    if (aqi <= 150) return Icons.sentiment_neutral;
    if (aqi <= 200) return Icons.sentiment_dissatisfied;
    return Icons.sentiment_very_dissatisfied;
  }

  Widget _buildStatsCard() {
    final aqiValues = _stations.map((s) => int.parse(s['aqi'].toString())).toList();
    final avgAqi = (aqiValues.reduce((a, b) => a + b) / aqiValues.length).round();
    final maxAqi = aqiValues.reduce((a, b) => a > b ? a : b);
    final minAqi = aqiValues.reduce((a, b) => a < b ? a : b);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Color(0xFF667eea), size: 24),
              SizedBox(width: 12),
              Text(
                'Regional Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem('Average', avgAqi, _getAQIColor(avgAqi), Icons.trending_up),
              SizedBox(width: 12),
              _buildStatItem('Highest', maxAqi, _getAQIColor(maxAqi), Icons.warning),
              SizedBox(width: 12),
              _buildStatItem('Lowest', minAqi, _getAQIColor(minAqi), Icons.trending_down),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AQI Levels',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          _buildLegendItem(Color(0xFF00E676), '0-50', 'Good'),
          _buildLegendItem(Color(0xFFFFEB3B), '51-100', 'Moderate'),
          _buildLegendItem(Color(0xFFFF9800), '101-150', 'Unhealthy(SG)'),
          _buildLegendItem(Color(0xFFF44336), '151-200', 'Unhealthy'),
          _buildLegendItem(Color(0xFFD32F2F), '201-300', 'Very Unhealthy'),
          _buildLegendItem(Color(0xFF8D0000), '300+', 'Hazardous'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String range, String level) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                range,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                level,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DelhiMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue[50]!
      ..style = PaintingStyle.fill;

    // Draw background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.blue[100]!
      ..strokeWidth = 0.5;

    // Vertical grid lines
    for (int i = 0; i <= 10; i++) {
      final x = (size.width / 10) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Horizontal grid lines
    for (int i = 0; i <= 10; i++) {
      final y = (size.height / 10) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.blue[300]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      borderPaint,
    );

    // Draw some landmarks or text to make it look like a map
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Delhi Region Map',
        style: TextStyle(
          color: Colors.blue[300],
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width / 2 - textPainter.width / 2, size.height / 2 - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}