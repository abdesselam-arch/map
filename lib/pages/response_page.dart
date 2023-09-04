import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ResponsePage extends StatefulWidget {
  final List<LatLng> routpoints;

  const ResponsePage({
    super.key,
    required this.routpoints,
  });

  @override
  State<ResponsePage> createState() => _ResponsePageState();
}

class _ResponsePageState extends State<ResponsePage> {
  @override
  Widget build(BuildContext context) {
    List<LatLng> routpoints = widget.routpoints;

    return FlutterMap(
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
              points: routpoints,
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
              point: routpoints[routpoints.length - 1], // Destination point
              builder: (ctx) => const Icon(
                Icons.location_on,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
