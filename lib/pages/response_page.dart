import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:map/classes/language_constants.dart';

class ResponsePage extends StatefulWidget {
  final List<LatLng> routpoints;
  final List<String> instructions;
  final double duration;
  final double distance;
  final String travelMean;
  final Icon TravelModeIcon;

  const ResponsePage({
    super.key,
    required this.routpoints,
    required this.instructions,
    required this.duration,
    required this.distance,
    required this.travelMean,
    required this.TravelModeIcon,
  });

  @override
  State<ResponsePage> createState() => _ResponsePageState();
}

class _ResponsePageState extends State<ResponsePage> {
  String getCurrentLocaleLanguage(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale
        .languageCode; // Returns the current language code (e.g., 'en' for English)
  }

  Color _changeColorTheme50() {
    final currentLanguage = getCurrentLocaleLanguage(context);

    if (currentLanguage == 'en') {
      return Colors.red.shade200;
    } else if (currentLanguage == 'fr') {
      return Colors.blue.shade200;
    } else if (currentLanguage == 'ar') {
      return Colors.green.shade200;
    }

    return Colors.green.shade200;
  }

  List<LatLng> updatePolylines(List<LatLng> routpoints) {
    List<LatLng> updatedRoutpoints = List.from(routpoints); // Create a copy

    Timer.periodic(Duration(seconds: 1), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // Check if the user's position matches any coordinate in updatedRoutpoints
        for (LatLng point in updatedRoutpoints.toList()) {
          double distanceInMeters = await Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            point.latitude,
            point.longitude,
          );

          // You can adjust the threshold distance as needed
          if (distanceInMeters < 10) {
            // Remove the matched point from updatedRoutpoints
            //updatedRoutpoints.remove(point);
            setState(() {
              updatedRoutpoints.remove(point);
            }); // Update the UI to reflect the changes
            break;
          }
        }
      } catch (e) {
        print(e);
      }
    });

    return updatedRoutpoints;
  }

  Icon directionsIcons(int index, List<String> instructions) {
    if (instructions[index].startsWith("Turn") ||
        instructions[index].startsWith("Tournez") ||
        instructions[index].startsWith("استمر") ||
        instructions[index].startsWith("اتجه")) {
      if (instructions[index].contains("right") ||
          instructions[index].contains("droite") ||
          instructions[index].contains("يمينا") ||
          instructions[index].contains("اليمين")) {
        return const Icon(Icons.turn_right);
      } else {
        return const Icon(Icons.turn_left);
      }
    } else if (instructions[index].startsWith("Keep") ||
        instructions[index].startsWith("استمر")) {
      if (instructions[index].contains("right") ||
          instructions[index].contains("يسارا") ||
          instructions[index].contains("اليسار")) {
        return const Icon(Icons.turn_right);
      } else {
        return const Icon(Icons.turn_left);
      }
    } else if (instructions[index].contains('Arrive') ||
        instructions[index].contains("Arrivée") ||
        instructions[index].contains("النهاية")) {
      return const Icon(Icons.location_searching);
    } else {
      return const Icon(Icons.straight);
    }
  }

  @override
  void initState() {
    super.initState();
    updatePolylines(widget.routpoints);
  }

  @override
  Widget build(BuildContext context) {
    List<LatLng> routpoints = widget.routpoints;
    double distance = widget.distance;
    double duration = widget.duration;
    String travelMean = widget.travelMean;

    return Material(
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              center: routpoints[0],
              zoom: 17,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              PolylineLayer(
                polylineCulling: false,
                polylines: [
                  Polyline(
                    points: updatePolylines(routpoints),
                    color: Colors.blue,
                    strokeWidth: 9,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40,
                    height: 40,
                    point: routpoints[0], // Departure point
                    builder: (ctx) => Container(
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  Marker(
                    width: 40,
                    height: 40,
                    point:
                        routpoints[routpoints.length - 1], // Destination point
                    builder: (ctx) => const Icon(
                      Icons.location_on,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 600,
            left: 30,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _changeColorTheme50(), // Background color
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info, // Add your desired icon here
                            color: Colors.white, // Icon color
                          ),
                          const SizedBox(width: 8),
                          Text(
                            translation(context).routeInfos,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on, // Add your desired icon here
                            color: Colors.grey.shade800, // Icon color
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${translation(context).distance} $distance ${translation(context).km}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.timer, // Add your desired icon here
                            color: Colors.grey.shade800, // Icon color
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${translation(context).duration} $duration ${translation(context).min}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            widget.TravelModeIcon
                                .icon, // Add your desired icon here
                            color: Colors.grey.shade800, // Icon color
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${translation(context).travelMean} $travelMean',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                                title: Text(
                                  translation(context).instructions,
                                ),
                                content: SizedBox(
                                  width: 350,
                                  height: 400,
                                  child: ListView.builder(
                                    itemCount: widget.instructions.length,
                                    itemBuilder: (context, index) {
                                      final instruction =
                                          widget.instructions[index];
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              _changeColorTheme50(),
                                          child: Icon(
                                            directionsIcons(
                                                    index, widget.instructions)
                                                .icon,
                                            color: Colors.white,
                                          ),
                                        ),
                                        title: Text(instruction),
                                      );
                                    },
                                  ),
                                ),
                              ));
                    },
                    icon: Icon(
                      Icons.route,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
