import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:map/classes/language_constants.dart';
import 'dart:convert';
import 'package:map/components/input_field.dart';
import 'package:map/components/recommended_tem.dart';
import 'package:map/pages/response_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final start = TextEditingController();
  final end = TextEditingController();
  bool isVisible = false;
  double distanceKM = 0;
  double durationMin = 0;
  List<LatLng> routpoints = [const LatLng(52.05884, -1.345583)];

  // user instance
  final currentUser = FirebaseAuth.instance.currentUser!;
  // collection instance
  CollectionReference requests =
      FirebaseFirestore.instance.collection('Requests');

  List<String> purposeOptions = [
    'Purpose',
    'Travel',
    'Education',
    'Medical Condition',
    'Work',
    'Vacation'
  ];
  String selectedPurpose = 'Purpose';

  void storeRequest() async {
    await requests.add({
      'UserEmail': currentUser.email,
      'Departure': start.text,
      'Arrival': end.text,
      'Purpose': selectedPurpose,
      'TimeStamp': Timestamp.now(),
    });
  }

  String getCurrentTime() {
    DateTime now = DateTime.now();
    String formattedTime = DateFormat('HH:mm:ss').format(now);
    return formattedTime;
  }

  String calculateArrivalTime(double durationMin) {
    DateTime now = DateTime.now();
    DateTime arrivalTime = now.add(Duration(minutes: durationMin.toInt()));
    String formattedArrivalTime = DateFormat('HH:mm:ss').format(arrivalTime);
    return formattedArrivalTime;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(
                  height: 20,
                ),
                myInput(
                  controler: start,
                  hint: translation(context).departure,
                ),
                const SizedBox(
                  height: 15,
                ),
                myInput(
                  controler: end,
                  hint: translation(context).arrival,
                ),
                const SizedBox(
                  height: 20,
                ),
                DropdownButton<String>(
                  value: selectedPurpose,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedPurpose = newValue!;
                    });
                  },
                  items: purposeOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    onPressed: () async {
                      storeRequest();

                      List<Location> start_l =
                          await locationFromAddress(start.text);
                      List<Location> end_l =
                          await locationFromAddress(end.text);

                      var v1 = start_l[0].latitude;
                      var v2 = start_l[0].longitude;
                      var v3 = end_l[0].latitude;
                      var v4 = end_l[0].longitude;

                      var url = Uri.parse(
                          'http://router.project-osrm.org/route/v1/driving/$v2,$v1;$v4,$v3?steps=true&annotations=true&geometries=geojson&overview=full');

                      var response = await http.get(url);
                      print(response.body);
                      setState(() {
                        routpoints = [];
                        var ruter = jsonDecode(response.body)['routes'][0]
                            ['geometry']['coordinates'];

                        final distance =
                            jsonDecode(response.body)['routes'][0]['distance'];
                        distanceKM = distance / 1000;

                        final duration =
                            jsonDecode(response.body)['routes'][0]['duration'];
                        durationMin = duration / 60;

                        for (int i = 0; i < ruter.length; i++) {
                          var reep = ruter[i].toString();
                          reep = reep.replaceAll("[", "");
                          reep = reep.replaceAll("]", "");
                          var lat1 = reep.split(',');
                          var long1 = reep.split(",");
                          routpoints.add(LatLng(
                              double.parse(lat1[1]), double.parse(long1[0])));
                        }
                        isVisible = !isVisible;
                        //print(routpoints);
                        print('trip distance : $distanceKM km');
                        print('trip duration : $durationMin mins');
                      });
                    },
                    child: Text(translation(context).submit)),
                const SizedBox(
                  height: 10,
                ),
                SizedBox(
                  height: 180,
                  width: 400,
                  child: Visibility(
                    visible: isVisible,
                    child: RecommendedItem(
                      distance: distanceKM,
                      departure_time: getCurrentTime(),
                      arrival_time: calculateArrivalTime(durationMin),
                      travelMean: "By Car",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ResponsePage(routpoints: routpoints), 
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
