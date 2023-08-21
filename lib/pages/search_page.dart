import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:map/classes/language_constants.dart';
import 'dart:convert';
import 'package:map/components/recommended_tem.dart';
import 'package:map/pages/response_page.dart';
import 'package:map/services/Health.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

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

  // Create variables for each travel mode
  double distanceCar = 0;
  double durationCar = 0;
  List<LatLng> routpointsCar = [const LatLng(52.05884, -1.345583)];

  double distanceBike = 0;
  double durationBike = 0;
  List<LatLng> routpointsBike = [const LatLng(52.05884, -1.345583)];

  double distanceFoot = 0;
  double durationFoot = 0;
  List<LatLng> routpointsFoot = [const LatLng(52.05884, -1.345583)];

  // function to determine the best travelMode (might be deleted later or modified)

  String determineBestTravelMode() {
    double minDistance = double.infinity;
    String bestTravelMode = '';

    if (distanceFoot < minDistance) {
      minDistance = distanceFoot;
      bestTravelMode = translation(context).onFoot;
    }

    if (distanceCar < minDistance) {
      minDistance = distanceCar;
      bestTravelMode = translation(context).byCar;
    }

    if (distanceBike < minDistance) {
      minDistance = distanceBike;
      bestTravelMode = translation(context).byBike;
    }

    return bestTravelMode;
  }

  List<String> _purposeList() {
    List<String> purposeOptions = [
      'Purpose',
      'Travel',
      'Education',
      'Medical Condition',
      'Work',
      'Vacation'
    ];

    return purposeOptions;
  }

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

  /*

  Future<void> getRoute(String travelMode) async {
    List<Location> start_l = await locationFromAddress(start.text);
    List<Location> end_l = await locationFromAddress(end.text);

    var v1 = start_l[0].latitude;
    var v2 = start_l[0].longitude;
    var v3 = end_l[0].latitude;
    var v4 = end_l[0].longitude;

    var url = Uri.parse(
        'http://router.project-osrm.org/route/v1/$travelMode/$v2,$v1;$v4,$v3?steps=true&annotations=true&geometries=geojson&overview=full');

    var response = await http.get(url);
    print(response.body);
    setState(() {
      routpoints = [];
      var ruter =
          jsonDecode(response.body)['routes'][0]['geometry']['coordinates'];

      final distance = jsonDecode(response.body)['routes'][0]['distance'];
      distanceKM = distance / 1000;

      final duration = jsonDecode(response.body)['routes'][0]['duration'];
      durationMin = duration / 60;

      for (int i = 0; i < ruter.length; i++) {
        var reep = ruter[i].toString();
        reep = reep.replaceAll("[", "");
        reep = reep.replaceAll("]", "");
        var lat1 = reep.split(',');
        var long1 = reep.split(",");
        routpoints.add(LatLng(double.parse(lat1[1]), double.parse(long1[0])));
      }
      isVisible = !isVisible;
      //print(routpoints);
      print('trip distance : $distanceKM km');
      print('trip duration : $durationMin mins');
    });
  }

  */

  Future<void> getRoute(String travelMode) async {
    List<Location> start_l = await locationFromAddress(start.text);
    List<Location> end_l = await locationFromAddress(end.text);

    var v1 = start_l[0].latitude;
    var v2 = start_l[0].longitude;
    var v3 = end_l[0].latitude;
    var v4 = end_l[0].longitude;

    String apiKey =
        "0fe097c8-8c66-402d-90fb-6cb9ebc27108"; // Replace this with your GraphHopper API key
    var url = Uri.parse(
        'https://graphhopper.com/api/1/route?point=$v1,$v2&point=$v3,$v4&vehicle=$travelMode&key=$apiKey&type=json&points_encoded=false');

    var response = await http.get(url);

    print('Response Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    setState(() {
      isVisible = true;

      Map<String, dynamic> data = jsonDecode(response.body);
      var paths = data['paths'];

      var path = paths[0];
      var distance = path['distance'];
      var duration = path['time'];

      List<LatLng> coordinates = [];
      List<dynamic> rawCoordinates = path['points']['coordinates'];

      for (var coord in rawCoordinates) {
        double latitude = coord[1];
        double longitude = coord[0];
        coordinates.add(LatLng(latitude, longitude));
      }

      routpoints = coordinates;

      print(routpoints);
      distanceKM = distance / 1000;
      print("distance of trip: $distanceKM km");
      durationMin = duration / 60000;
      print("duration of trip: $durationMin mins");
    });
  }

  // Helper function to get route for a specific travel mode
  Future<void> getRouteForTravelMode(String travelMode) async {
    // Call the getRoute() method with the specified travelMode
    await getRoute(travelMode);

    // Update the variables based on the travelMode
    if (travelMode == 'car') {
      distanceCar = distanceKM;
      durationCar = durationMin;
      routpointsCar = List.from(routpoints);
    } else if (travelMode == 'bike') {
      distanceBike = distanceKM;
      durationBike = durationMin;
      routpointsBike = List.from(routpoints);
    } else if (travelMode == 'foot') {
      distanceFoot = distanceKM;
      durationFoot = durationMin;
      routpointsFoot = List.from(routpoints);
    }
  }

  List<String> startSuggestions = [];
  List<String> endSuggestions = [];

  // The getAutoCompletionSuggestions function remains the same as provided in the question.
  // It fetches auto-completion suggestions using Nominatim.
  Future<List<String>> _getAutoCompletionSuggestions(String input) async {
    final baseUrl = 'https://nominatim.openstreetmap.org/search';
    final query =
        '?q=${input.replaceAll(' ', '%20')}&format=json&addressdetails=1';

    final response = await http.get(Uri.parse(baseUrl + query));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final List<String> suggestions =
          data.map((place) => place['display_name'] as String).toList();
      return suggestions;
    } else {
      throw Exception('Failed to fetch auto-completion suggestions');
    }
  }

  @override
  void initState() {
    super.initState();
    start.addListener(onStartTextChanged);
    end.addListener(onEndTextChanged);
  }

  void onStartTextChanged() {
    _updateStartSuggestions(start.text);
  }

  void onEndTextChanged() {
    _updateEndSuggestions(end.text);
  }

  Future<void> _updateStartSuggestions(String input) async {
    List<String> suggestions = await _getAutoCompletionSuggestions(input);
    setState(() {
      startSuggestions = suggestions;
    });
  }

  Future<void> _updateEndSuggestions(String input) async {
    List<String> suggestions = await _getAutoCompletionSuggestions(input);
    setState(() {
      endSuggestions = suggestions;
    });
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
                TypeAheadField(
                  textFieldConfiguration: TextFieldConfiguration(
                    controller: start,
                    decoration: InputDecoration(
                      labelText: translation(context).departure,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  suggestionsCallback: (pattern) async {
                    // Fetch auto-completion suggestions for departure
                    return await _getAutoCompletionSuggestions(pattern);
                  },
                  itemBuilder: (context, suggestion) {
                    return ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(suggestion.toString()),
                    );
                  },
                  onSuggestionSelected: (suggestion) {
                    start.text = suggestion.toString();
                  },
                  // Customize the suggestion box appearance
                  suggestionsBoxDecoration: SuggestionsBoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    elevation: 4.0,
                  ),
                ),
/*
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<String>.empty();
                    } else {
                      return startSuggestions.where((String option) {
                        return option
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase());
                      });
                    }
                  },
                  onSelected: (String selection) {
                    start.text = selection;
                  },
                  fieldViewBuilder: (
                    BuildContext context,
                    TextEditingController fieldController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted,
                  ) {
                    return myInput(
                      controler: start,
                      hint: translation(context).departure,
                    );
                  },
                ),

                myInput(
                  controler: start,
                  hint: translation(context).departure,
                ),*/
                const SizedBox(
                  height: 15,
                ),

                // Search input for arrival with auto-completion
                TypeAheadField(
                  textFieldConfiguration: TextFieldConfiguration(
                    controller: end,
                    decoration: InputDecoration(
                      labelText: translation(context).arrival,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  suggestionsCallback: (pattern) async {
                    // Fetch auto-completion suggestions for arrival
                    return await _getAutoCompletionSuggestions(pattern);
                  },
                  itemBuilder: (context, suggestion) {
                    return ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(suggestion.toString()),
                    );
                  },
                  onSuggestionSelected: (suggestion) {
                    end.text = suggestion.toString();
                  },
                ),
/*
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<String>.empty();
                    } else {
                      return endSuggestions.where((String option) {
                        return option
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase());
                      });
                    }
                  },
                  onSelected: (String selection) {
                    end.text = selection;
                  },
                  fieldViewBuilder: (
                    BuildContext context,
                    TextEditingController fieldController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted,
                  ) {
                    return myInput(
                      controler: end,
                      hint: translation(context).arrival,
                    );
                  },
                ),

                myInput(
                  controler: end,
                  hint: translation(context).arrival,
                ),*/
                const SizedBox(
                  height: 20,
                ),
                DropdownButton<String>(
                  value: selectedPurpose,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedPurpose = newValue!;
                      print('selectedPurpose variable changed');
                    });
                  },
                  items: _purposeList().map((String value) {
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
                      // Execute getRoute() for different travel modes
                      await getRouteForTravelMode('car'); // Car
                      await getRouteForTravelMode('bike'); // Bike
                      await getRouteForTravelMode('foot'); // Foot

                      const HealthIrregularityChecker();
                    },
                    child: Text(translation(context).submit)),
                const SizedBox(
                  height: 10,
                ),
                SizedBox(
                  child: Visibility(
                    visible: isVisible,
                    child: Column(
                      children: [
                        // RecommendedItem for Car
                        RecommendedItem(
                          distance: distanceCar,
                          departure_time: getCurrentTime(),
                          arrival_time: calculateArrivalTime(durationCar),
                          travelMean: translation(context).byCar,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ResponsePage(routpoints: routpointsCar),
                              ),
                            );
                          },
                          backgroundColor: determineBestTravelMode() ==
                                  translation(context).byCar
                              ? Colors.grey.shade600
                              : Colors.grey.shade200,
                          textColor: determineBestTravelMode() ==
                                  translation(context).byCar
                              ? Colors.white
                              : Colors.black,
                        ),

                        const SizedBox(
                          height: 15,
                        ),

                        // RecommendedItem for Bike
                        RecommendedItem(
                          distance: distanceBike,
                          departure_time: getCurrentTime(),
                          arrival_time: calculateArrivalTime(durationBike),
                          travelMean: translation(context).byBike,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ResponsePage(routpoints: routpointsBike),
                              ),
                            );
                          },
                          backgroundColor: determineBestTravelMode() ==
                                  translation(context).byBike
                              ? Colors.grey.shade600
                              : Colors.grey.shade200,
                          textColor: determineBestTravelMode() ==
                                  translation(context).byBike
                              ? Colors.white
                              : Colors.black,
                        ),

                        const SizedBox(
                          height: 15,
                        ),

                        // RecommendedItem for Foot
                        RecommendedItem(
                          distance: distanceFoot,
                          departure_time: getCurrentTime(),
                          arrival_time: calculateArrivalTime(durationFoot),
                          travelMean: translation(context).onFoot,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ResponsePage(routpoints: routpointsFoot),
                              ),
                            );
                          },
                          backgroundColor: determineBestTravelMode() ==
                                  translation(context).onFoot
                              ? Colors.grey.shade600
                              : Colors.grey.shade200,
                          textColor: determineBestTravelMode() ==
                                  translation(context).onFoot
                              ? Colors.white
                              : Colors.black,
                        ),

                        const SizedBox(
                          height: 15,
                        ),

                        const Text(
                          'The optimal choice is highlited in dark grey!',
                        ),

                        const SizedBox(
                          height: 5,
                        ),
                      ],
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
