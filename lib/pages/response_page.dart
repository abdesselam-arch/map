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
        zoom: 10,
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
      ],
    );
  }
}
