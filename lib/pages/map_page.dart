import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final double _zoomLevel = 8.0;
  LatLng point = const LatLng(35.3004743, -1.3710402);

  String weatherDescription = '';
  double temperature = 0;
  String iconUrl = '';

  @override
  void initState() {
    super.initState();
    fetchWeatherData();
  }

  void fetchWeatherData() async {
    final apiKey = '9288b0a87c194f099c4a28c2322ca8c0';
    final url =
        'https://api.openweathermap.org/data/2.5/weather?lat=${point.latitude}&lon=${point.longitude}&units=metric&appid=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        weatherDescription = data['weather'][0]['description'];
        temperature = data['main']['temp'];
        final iconCode = data['weather'][0]['icon'];
        iconUrl = 'http://openweathermap.org/img/w/$iconCode.png';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          child: Column(
            children: [
              Flexible(
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        onTap: (p, LatLng) async {
                          setState(() {
                            point = LatLng;
                            fetchWeatherData();
                          });
                        },
                        center: const LatLng(35.3004743, -1.3710402),
                        zoom: _zoomLevel,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: point,
                              width: 80,
                              height: 80,
                              builder: (context) => const Icon(
                                Icons.person_pin_circle_sharp,
                                size: 30.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      top: 40,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Weather Information',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Temperature: ${temperature.toStringAsFixed(1)}°C'),
                            const SizedBox(height: 4),
                            Text('Description: $weatherDescription'),
                            const SizedBox(height: 4),
                            if (iconUrl.isNotEmpty)
                              Image.network(
                                iconUrl,
                                height: 40,
                                width: 40,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
