import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:map/classes/language_constants.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final double _zoomLevel = 15.0;
  LatLng point = LatLng(0, 0);

  String weatherDescription = '';
  double temperature = 0;
  String iconUrl = '';
  double _latitude = 0.0;
  double _longitude = 0.0;
  MapController mapController = MapController();
  int minutes = TimeOfDay.now().minute;

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        // Center the map on the fetched location
        point = LatLng(_latitude, _longitude);
        // Now set the center of the map
        mapController.move(point, _zoomLevel);

        print('The Center Coordinations: $_latitude and $_longitude');
      });
    } catch (e) {
      print(e);
    }
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

  String getCurrentLocaleLanguage(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale
        .languageCode; // Returns the current language code (e.g., 'en' for English)
  }

  double getCurrentLocaleLanguagedouble(BuildContext context) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'en' || locale.languageCode == 'fr') {
      return 170;
    } else {
      return 200;
    }
  }

  double getCurrentLocaleLanguageW(BuildContext context) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'en' || locale.languageCode == 'fr') {
      return 10;
    } else {
      return 145;
    }
  }

  double getCurrentLocaleLanguageleft(BuildContext context) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'en' || locale.languageCode == 'fr') {
      return 10;
    } else {
      return 190;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchWeatherData();
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    final String currentLanguage = getCurrentLocaleLanguage(context);
    String formattedMinutes = minutes.toString().padLeft(2, '0');
    point = LatLng(_latitude, _longitude);
    return Scaffold(
      body: Center(
        child: Container(
          child: Column(
            children: [
              Flexible(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        onTap: (p, LatLng) async {
                          setState(() {
                            point = LatLng;
                            fetchWeatherData();
                          });
                        },
                        center: point,
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
                      left: getCurrentLocaleLanguageW(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              translation(context).weatherInformations,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                                '${translation(context).temp} ${temperature.toStringAsFixed(1)}°C'),
                            const SizedBox(height: 4),
                            Text(
                                '${translation(context).descMeteo} $weatherDescription'),
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
                    Positioned(
                      top: getCurrentLocaleLanguagedouble(context),
                      left: getCurrentLocaleLanguageleft(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              translation(context).currentTimeAndDate,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${translation(context).timeOfDay} ${TimeOfDay.now().hour}:$formattedMinutes',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${translation(context).date} ${DateFormat('d MMMM y', currentLanguage).format(DateTime.now())}',
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
