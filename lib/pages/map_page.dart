import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:map/classes/language.dart';
import 'dart:convert';
import 'package:map/classes/language_constants.dart';
import 'package:map/main.dart';
import 'package:map/pages/settings_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({
    super.key,
  });

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
  int hours = TimeOfDay.now().hour;

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

/*
  Future<LatLng> getStartLatLong() async {
    List<Location> startAddress = await locationFromAddress(start.text);

    var v1 = startAddress[0].latitude;
    var v2 = startAddress[0].longitude;

    return LatLng(v1, v2);
  }

  void moveMapToAddress(String address) async {
    if (address != _getCurrentLocation()) {
      List<Location> startAddress = await locationFromAddress(address);

      var v1 = startAddress[0].latitude;
      var v2 = startAddress[0].longitude;
      mapController.move(LatLng(v1, v2), 15.0);
    }
  }
*/
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
      return 150;
    } else {
      return 160;
    }
  }

  double getCurrentLocaleLanguageW(BuildContext context) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'en' || locale.languageCode == 'fr') {
      return 10;
    } else {
      return 175;
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

  Color _changeColorTheme() {
    final currentLanguage = getCurrentLocaleLanguage(context);

    if (currentLanguage == 'en') {
      return Colors.red.shade800;
    } else if (currentLanguage == 'fr') {
      return Colors.blue.shade800;
    } else if (currentLanguage == 'ar') {
      return Colors.green.shade800;
    }

    return Colors.green.shade800;
  }

  double getCurrentLocaleLanguageleftButton(BuildContext context) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'en' || locale.languageCode == 'fr') {
      return 290;
    } else {
      return 10;
    }
  }

  String changeText() {
    final currentLanguage = getCurrentLocaleLanguage(context);

    if (currentLanguage == 'en') {
      return "🇬🇧";
    } else if (currentLanguage == 'fr') {
      return "🇫🇷";
    } else {
      return "🇦🇪";
    }
  }

  Future<void> searchLocation(
      String address, MapController mapController) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        Location location = locations.first;
        LatLng point = LatLng(location.latitude, location.longitude);
        mapController.move(point, 15.0);
        // You can also add a marker at the searched location if needed.
      } else {
        print('Location not found for: $address');
      }
    } catch (e) {
      print('Error searching location: $e');
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
    String formattedHours = hours.toString().padLeft(2, '0');
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
                        /*onTap: (p, LatLng) async {
                          setState(() {
                            point = LatLng;
                            fetchWeatherData();
                          });
                        },*/
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
                              '${temperature.toStringAsFixed(1)}°C, $weatherDescription',
                            ),
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
                              '${DateFormat('d MMMM y', currentLanguage).format(DateTime.now())}, $formattedHours:$formattedMinutes',
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 45,
                      left: getCurrentLocaleLanguageleftButton(context),
                      child: FloatingActionButton(
                        onPressed: () {
                          // Navigate to the SettingsPage when the button is pressed
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SettingsPage()),
                          );
                        },
                        backgroundColor: _changeColorTheme(),
                        child: const Icon(Icons.settings),
                      ),
                    ),
                    Positioned(
                      top: 115,
                      left: getCurrentLocaleLanguageleftButton(context) + 5,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _changeColorTheme(),
                        ),
                        child: PopupMenuButton<Language>(
                          itemBuilder: (BuildContext context) {
                            return Language.languageList()
                                .map<PopupMenuEntry<Language>>(
                              (e) {
                                return PopupMenuItem<Language>(
                                  value: e,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: <Widget>[
                                      Text(e.flag),
                                    ],
                                  ),
                                );
                              },
                            ).toList();
                          },
                          onSelected: (Language? language) async {
                            // Do something when a language is selected
                            if (language != null) {
                              Locale _locale =
                                  await setLocale(language.languageCode);
                              MyApp.setLocale(context, _locale);
                            }
                          },
                          icon: const Icon(
                            Icons.flag_outlined,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // This button might change or go
                    Positioned(
                      top: 417,
                      left: getCurrentLocaleLanguageleftButton(context),
                      child: Transform.scale(
                        scale: .85,
                        child: FloatingActionButton(
                          onPressed: () {
                            // Navigate to the SettingsPage when the button is pressed
                            mapController.move(point, _zoomLevel);
                          },
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.my_location_outlined,
                            color: _changeColorTheme(),
                          ),
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
