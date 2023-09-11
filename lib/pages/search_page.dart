import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:map/classes/language.dart';
import 'package:map/classes/language_constants.dart';
import 'package:map/components/public_transport_card.dart';
import 'dart:convert';
import 'package:map/components/recommended_tem.dart';
import 'package:map/components/time_picker.dart';
import 'package:map/main.dart';
import 'package:map/pages/response_page.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:map/services/health_data_screen.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class TransitOption {
  final String name;
  final String type;

  TransitOption({required this.name, required this.type});
}

class SearchPage extends StatefulWidget {
  final ScrollController controller;
  final PanelController panelcontroller;

  const SearchPage({
    super.key,
    required this.controller,
    required this.panelcontroller,
  });

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

  List<String> HealthProblems = [];
  bool hasHealthProblems = false;
  double dailySteps = 2600;
  List<String> adviceList = [];
  List<String> searchHistory = [];

  // Fuzzy AHP Assigned weights for each Criteria
  final double healthCondition = 0.538;
  final double weatherCondition = 0.2625;
  final double purposeCondition = 0.077;
  final double durationCondition = 0.121;

  // Health Criteria weight
  double healthCriteriaWeight = 0.0;
  // Duration Criteria weight for each alternative choice
  double carDurationWeight = 0.0;
  double bikeDurationWeight = 0.0;
  double footDurationWeight = 0.0;
  // Purpose Criteria weight
  double carPurposeWeight = 0.0;
  double bikePurposeWeight = 0.0;
  double footPurposeWeight = 0.0;
  // Weather Criteria weight
  double weatherWeightCar = 0.35;
  double weatherWeightFoot = 0.35;
  double weatherWeightBike = 0.3;

  List<String> carDangerousWeather = [
    'thunderstorm with light rain',
    'thunderstorm with rain',
    'thunderstorm with heavy rain',
    'light thunderstorm',
    'thunderstorm',
    'heavy thunderstorm',
    'ragged thunderstorm',
    'thunderstorm with light drizzle',
    'thunderstorm with drizzle',
    'thunderstorm with heavy drizzle',
    'freezing rain',
    'heavy intensity shower rain',
    'ragged shower rain',
    'tornado',
  ];

  List<String> footDangerousWeather = [
    'heavy intensity drizzle rain',
    'shower rain and drizzle',
    'heavy intensity rain',
    'very heavy rain',
    'extreme rain',
    'freezing rain',
    'heavy intensity shower rain',
    'ragged shower rain',
    'tornado',
  ];

  List<String> bikeDangerousWeather = [
    'light intensity drizzle',
    'drizzle',
    'heavy intensity drizzle',
    'light intensity drizzle rain',
    'drizzle rain',
    'heavy intensity drizzle rain',
    'shower rain and drizzle',
    'heavy shower rain and drizzle',
    'shower drizzle',
    'light rain',
    'moderate rain',
    'heavy intensity rain',
    'very heavy rain',
    'extreme rain',
    'freezing rain',
    'heavy intensity shower rain',
    'ragged shower rain',
    'tornado',
  ];

  String weatherDescription = '';
  double temperature = 0;

  void fetchWeatherData(TextEditingController controller, DateTime date) async {
    const apiKey = '9288b0a87c194f099c4a28c2322ca8c0';
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    String location = controller.text;

    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$location&dt=$formattedDate&units=metric&appid=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        weatherDescription = data['weather'][0]['description'];
        temperature = data['main']['temp'];
        calculateWeatherWeights();
      });
    }
  }

  bool isDangerousForCar(String weatherDescription) {
    return carDangerousWeather.contains(weatherDescription.toLowerCase());
  }

  bool isDangerousForFoot(String weatherDescription, double tempurature) {
    return footDangerousWeather.contains(weatherDescription.toLowerCase()) &&
        (temperature < 15 || temperature > 30);
  }

  bool isDangerousForBike(String weatherDescription) {
    return bikeDangerousWeather.contains(weatherDescription.toLowerCase());
  }

  void calculateWeatherWeights() {
    bool dangerousCar = isDangerousForCar(weatherDescription);
    bool dangerousBike = isDangerousForBike(weatherDescription);
    bool dangerousFoot = isDangerousForFoot(weatherDescription, temperature);

    if (dangerousCar) {
      weatherWeightCar = 0.0;
      weatherWeightFoot = 0.5;
      weatherWeightBike = 0.5;
    }
    if (dangerousFoot) {
      weatherWeightFoot = 0.0;
      weatherWeightBike = 0.5;
      weatherWeightCar = 0.5;
    }
    if (dangerousBike) {
      weatherWeightCar = 0.5;
      weatherWeightBike = 0.0;
      weatherWeightFoot = 0.5;
    }

    if (!dangerousCar && !dangerousFoot && !dangerousBike) {
      // No dangerous weather conditions
      weatherWeightCar = 0.333;
      weatherWeightBike = 0.333;
      weatherWeightFoot = 0.333;
    }

    print('The weather weight using car: $weatherWeightCar');
    print('The weather weight using a bike: $weatherWeightBike');
    print('The weather weight on a walk: $weatherWeightFoot');
  }

  void getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;

        String street = placemark.street ?? '';
        String locality = placemark.locality ?? '';
        String subAdminArea = placemark.subAdministrativeArea ?? '';
        String adminArea = placemark.administrativeArea ?? '';

        String address = '$street, $locality, $subAdminArea, $adminArea';

        setState(() {
          start.text = address;
        });
      } else {
        print('No placemark available');
      }
    } catch (e) {
      print('Error getting user location: $e');
    }
  }

  void getCurrentLocationArrival() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;

        String street = placemark.street ?? '';
        String locality = placemark.locality ?? '';
        String subAdminArea = placemark.subAdministrativeArea ?? '';
        String adminArea = placemark.administrativeArea ?? '';

        String address = '$street, $locality, $subAdminArea, $adminArea';

        setState(() {
          end.text = address;
        });
      } else {
        print('No placemark available');
      }
    } catch (e) {
      print('Error getting user location: $e');
    }
  }

  List<double> DurationWeightList = [];

  List<double> CalculateDurationWeight() {
    double totalDuration = durationCar + durationFoot + durationBike;

    carDurationWeight = 1 - (durationCar / totalDuration);
    DurationWeightList.add(carDurationWeight);
    print('The car duration weight: $carDurationWeight');

    bikeDurationWeight = 1 - (durationBike / totalDuration);
    DurationWeightList.add(bikeDurationWeight);
    print('The bike duration weight: $bikeDurationWeight');

    footDurationWeight = 1 - (durationFoot / totalDuration);
    DurationWeightList.add(footDurationWeight);
    print('The walk duration weight: $footDurationWeight');

    return DurationWeightList;
  }

  // Function to calculate the purpose criteria weight
  double calculatePurposeWeight() {
    if (selectedPurpose == 'Medical condition') {
      carPurposeWeight = 0.5;
      footPurposeWeight = 0.2;
      bikePurposeWeight = 0.3;
    } else if (selectedPurpose == 'Vacation' ||
        selectedPurpose == 'Travel' ||
        selectedPurpose == 'Shopping' ||
        selectedPurpose == 'Visit') {
      carPurposeWeight = 0.2; // Moderate weight for car
      bikePurposeWeight = 0.4; // Moderate weight for biking
      footPurposeWeight = 0.4; // Higher weight for walking, ideal for exploring
    } else if (selectedPurpose == 'Work' ||
        selectedPurpose == 'Education' ||
        selectedPurpose == 'Other') {
      carPurposeWeight = 0.5; // Moderate weight for car
      footPurposeWeight = 0.25; // Moderate weight for walking
      bikePurposeWeight = 0.25; // Moderate weight for biking
    }
    print('the purpose criteria weight using a car: $carPurposeWeight');
    print('the purpose criteria weight on foot: $footPurposeWeight');
    print('the purpose criteria weight using a bike: $bikePurposeWeight');

    return carPurposeWeight;
  }

  double? heartRate;
  double? bp;
  double? steps;
  double? bodyTemp;
  double? bloodGlucose;
  double? respRate;
  double? bloodOxy;

  double? bloodPreSys;
  double? bloodPreDia;

  List<HealthDataPoint> healthData = [];

  HealthFactory health = HealthFactory();

  /// Fetch data points from the health plugin and show them in the app.
  Future _fetchData() async {
    // define the types to get
    final types = [
      HealthDataType.HEART_RATE,
      HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
      HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
      HealthDataType.STEPS,
      HealthDataType.BODY_TEMPERATURE,
      HealthDataType.BLOOD_OXYGEN,
      HealthDataType.RESPIRATORY_RATE,
      HealthDataType.BLOOD_GLUCOSE,
    ];

    // get data within the last 24 hours
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    // requesting access to the data types before reading them
    bool requested = await health.requestAuthorization(types);

    if (requested) {
      try {
        // fetch health data
        healthData = await health.getHealthDataFromTypes(yesterday, now, types);

        if (healthData.isNotEmpty) {
          for (HealthDataPoint h in healthData) {
            if (h.type == HealthDataType.HEART_RATE) {
              heartRate = h.value as double?;
            } else if (h.type == HealthDataType.BLOOD_PRESSURE_SYSTOLIC) {
              bloodPreSys = h.value as double?;
            } else if (h.type == HealthDataType.BLOOD_PRESSURE_DIASTOLIC) {
              bloodPreDia = h.value as double?;
            } else if (h.type == HealthDataType.STEPS) {
              steps = h.value as double?;
            } else if (h.type == HealthDataType.BODY_TEMPERATURE) {
              bodyTemp = h.value as double?;
            } else if (h.type == HealthDataType.BLOOD_GLUCOSE) {
              bloodGlucose = h.value as double?;
            } else if (h.type == HealthDataType.RESPIRATORY_RATE) {
              respRate = h.value as double?;
            } else if (h.type == HealthDataType.BLOOD_OXYGEN) {
              bloodOxy = h.value as double?;
            }
          }
          if (bloodPreSys != null && bloodPreDia != null) {
            bp = "$bloodPreSys / $bloodPreDia mmHg" as double?;
          }

          setState(() {});
        }
      } catch (error) {
        print("Exception in getHealthDataFromTypes: $error");
      }

      // filter out duplicates
      healthData = HealthFactory.removeDuplicates(healthData);
    } else {
      print("Authorization not granted");
    }
  }

  Future _checkForHealthProblems() async {
    if (heartRate != null) {
      if (heartRate! > 60.0) {
        HealthProblems.add("${translation(context).heartRate} $heartRate bpm");
        setState(() {});
      }
    }
    if (bodyTemp != null) {
      if (bodyTemp! > 37.0) {
        HealthProblems.add('${translation(context).bodyTemp} $bodyTemp °C');
      }
    }
    if (respRate != null) {
      if (respRate! > 12.0 && respRate! < 25.0) {
        HealthProblems.add('${translation(context).respRate} $respRate bpm');
      }
    }
    if (bloodPreDia != null && bloodPreSys != null) {
      if ((bloodPreDia! > 60.0 && bloodPreDia! < 80.0) ||
          (bloodPreSys! > 90.0 && bloodPreSys! < 120.0)) {
        HealthProblems.add(
            '${translation(context).bloodPressure} $bloodPreSys / $bloodPreDia mmHg');
      }
    }
    if (bloodOxy != null) {
      if (bloodOxy! < 92) {
        HealthProblems.add('${translation(context).bloodOxy} $bloodOxy %');
      }
    }
    if (bloodGlucose != null) {
      if (bloodGlucose! > 180) {
        HealthProblems.add(
            '${translation(context).bloodSugar} $bloodGlucose mg/dL');
      }
    }
    if (HealthProblems.length > 3) {
      setState(() {
        hasHealthProblems = true;
      });
    }
    if (HealthProblems.isEmpty) {
      HealthProblems.add(translation(context).noHealthProbs);
    }

    setState(() {});
  }

  // ignore: non_constant_identifier_names
  Future<double> _CalculateHealthWeight() async {
    if (!hasHealthProblems) {
      final double stepsRatio = steps! / dailySteps;

      // Ensure that the health weight doesn't exceed the maximum value
      healthCriteriaWeight = 1 / stepsRatio;

      print('Health criteria weight: $healthCriteriaWeight');
    } else {
      healthCriteriaWeight = 1;
    }
    return healthCriteriaWeight;
  }

  /// Generate random health data for testing.
  Future _generateTestData() async {
    heartRate = (60); // Generates a heart rate between 60 and 100 bpm.
    bloodPreSys =
        (90); // Generates a systolic blood pressure between 90 and 130 mmHg.
    bloodPreDia =
        (60); // Generates a diastolic blood pressure between 60 and 90 mmHg.
    steps =
        (8000); // Generates a random number of steps between 2000 and 10000.
    bodyTemp =
        (36.5); // Generates a random body temperature between 35.5 and 37.5 degrees Celsius.
    bloodGlucose =
        (70); // Generates a random blood glucose level between 70 and 120 mg/dL.
    respRate =
        (10); // Generates a random respiratory rate between 10 and 30 breaths per minute.
    bloodOxy =
        (98); // Generates a random blood oxygen level between 95% and 100%.

    bp = "$bloodPreSys / $bloodPreDia mmHg"
        as double?; // Combines systolic and diastolic blood pressure.

    setState(() {});
  }

  List<String> checkForAdvice() {
    if (heartRate! > 60) {
      adviceList.add(translation(context).heartRateAdvice);
    }
    if (bloodPreSys! > 90 || bloodPreDia! > 60) {
      adviceList.add(translation(context).bloodPressureAdvice);
    }
    if (bloodGlucose! > 180) {
      adviceList.add(translation(context).bloodGlucoseAdvice);
    }
    if (bloodOxy! < 95) {
      adviceList.add(translation(context).bloodOxyAdvice);
    }

    if (adviceList.isEmpty) {
      adviceList.add(translation(context).healthConditionnormal);
    }

    return adviceList;
  }

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
    String bestTravelMode = '';

    double carAlternativeWeight = 0.0;
    double footAlternativeWeight = 0.0;
    double bikeAlternativeWeight = 0.0;

    carAlternativeWeight = (carDurationWeight * durationCondition) +
        (carPurposeWeight * purposeCondition) +
        (healthCriteriaWeight * healthCondition) +
        (weatherWeightCar * weatherCondition);

    bikeAlternativeWeight = (bikeDurationWeight * durationCondition) +
        (bikePurposeWeight * purposeCondition) +
        (healthCriteriaWeight * healthCondition) +
        (weatherWeightBike * weatherCondition);

    footAlternativeWeight = (footDurationWeight * durationCondition) +
        (footPurposeWeight * purposeCondition) +
        (healthCriteriaWeight * healthCondition) +
        (weatherWeightFoot * weatherCondition);

    if (carAlternativeWeight >= bikeAlternativeWeight &&
        carAlternativeWeight >= footAlternativeWeight) {
      bestTravelMode = translation(context).byCar;
    } else if (footAlternativeWeight >= carAlternativeWeight &&
        footAlternativeWeight >= bikeAlternativeWeight) {
      bestTravelMode = translation(context).onFoot;
    } else {
      bestTravelMode = translation(context).byBike;
    }

    //carAlternativeWeight = 0.5;
    footAlternativeWeight = 0.8;
    //bikeAlternativeWeight = 0.7;

    return bestTravelMode;
  }

  String initialPurpose = '';

  List<String> _purposeList() {
    List<String> purposeOptions = [
      'Purpose',
      'Travel',
      'Education',
      'Visit',
      'Shopping',
      'Medical condition',
      'Work',
      'Vacation',
      'Other'
    ];

    initialPurpose = translation(context).purposeField;

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

  String calculateArrivalTime(double durationMin, String formattedTime) {
    final timeParts = formattedTime.split(':');
    if (timeParts.length != 3) {
      // Handle invalid formattedTime input here
      return 'Invalid Time';
    }

    final hours = int.parse(timeParts[0]);
    final minutes = int.parse(timeParts[1]);
    final seconds = int.parse(timeParts[2]);

    final totalSeconds = hours * 3600 + minutes * 60 + seconds;
    final arrivalTimeInSeconds = totalSeconds + (durationMin * 60).toInt();

    final arrivalHours = arrivalTimeInSeconds ~/ 3600;
    final arrivalMinutes = (arrivalTimeInSeconds % 3600) ~/ 60;
    final arrivalSeconds = arrivalTimeInSeconds % 60;

    final formattedArrivalTime =
        '${(arrivalHours % 24).toString().padLeft(2, '0')}:${arrivalMinutes.toString().padLeft(2, '0')}:${arrivalSeconds.toString().padLeft(2, '0')}';

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
    const baseUrl = 'https://nominatim.openstreetmap.org/search';
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

  List<TransitOption> TransitOptions = [];

  Future<List<TransitOption>> findPublicTransportOptions(
      TextEditingController dep, TextEditingController dest) async {
    String departureAddress = dep.text;
    String destinationAddress = dest.text;

    final transitlandBaseUrl = 'https://transit.land/api/v1/routes?';
    final apiKey = '650Xk1lrYxc1cCAthBndv12bWhhPCGry';

    final apiUrl = '$transitlandBaseUrl' +
        'origin_onestop_id=$departureAddress' +
        '&destination_onestop_id=$destinationAddress';

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {'Api-Key': apiKey},
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      List<Map<String, dynamic>> routes =
          (responseData['routes'] as List).cast<Map<String, dynamic>>();

      List<TransitOption> options = [];

      for (var route in routes) {
        final name = route['name'];
        final type = route['vehicle_type'];

        options.add(TransitOption(name: name, type: type));
      }

      return options;
    } else {
      throw Exception('Failed to fetch data');
    }
  }

  TimeOfDay _timeOfDay = TimeOfDay.now();

  void _showTimePicker() {
    CustomTimePicker(
      onChanged: (newTime) {
        setState(() {
          _timeOfDay = newTime;
        });
      },
      initialTime: TimeOfDay.now(),
      time: 'ff',
    );
  }

  Future<void> _showCustomTimePicker(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero, // Remove content padding
          content: SizedBox(
            width: 320,
            child: CustomTimePicker(
              onChanged: (value) {
                setState(() {
                  _timeOfDay = value;
                });
              },
              initialTime: TimeOfDay.now(),
              time: translation(context).selectArrTime,
            ),
          ),
        );
      },
    );
  }

  TimeOfDay _depTime = TimeOfDay.now();

  Future<void> _showCustomDepTimePicker(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero, // Remove content padding
          content: SizedBox(
            width: 320,
            child: CustomTimePicker(
              onChanged: (value) {
                setState(() {
                  _depTime = value;
                });
              },
              initialTime: TimeOfDay.now(),
              time: translation(context).selectDepTime,
            ),
          ),
        );
      },
    );
  }

  void _showDepTimePicker() {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              // change the border color
              primary: _changeColorTheme600(),
              // change the text color
              onSurface: _changeColorTheme600(),
            ),
            // button colors
            buttonTheme: ButtonThemeData(
              colorScheme: ColorScheme.light(
                primary: _changeColorTheme600(),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
          //child: child,
        );
      },
    ).then((value) {
      setState(() {
        _depTime = value!;
      });
    });
  }

  String formatDepTime(TimeOfDay time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    final seconds = '00'; // Since TimeOfDay doesn't include seconds
    return '$hours:$minutes:$seconds';
  }

  DateTime _departureDate = DateTime.now();

  void _showDepDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2026),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              // change the border color
              primary: _changeColorTheme600(),
              // change the text color
              onSurface: _changeColorTheme600(),
            ),
            // button colors
            buttonTheme: ButtonThemeData(
              colorScheme: ColorScheme.light(
                primary: _changeColorTheme600(),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
          //child: child,
        );
      },
    ).then((value) {
      setState(() {
        _departureDate = value!;
      });
    });
  }

  bool willArriveOnTime(String formattedArrivalTime) {
    TimeOfDay arrivalTime = TimeOfDay(
      hour: int.parse(formattedArrivalTime.split(':')[0]),
      minute: int.parse(formattedArrivalTime.split(':')[1]),
    );
    return _timeOfDay.hour > arrivalTime.hour ||
        (_timeOfDay.hour == arrivalTime.hour &&
            _timeOfDay.minute >= arrivalTime.minute);
  }

  String carArriveInTime() {
    String carArrivalTime =
        calculateArrivalTime(durationCar, formatDepTime(_depTime));
    bool willCarArriveOnTime = willArriveOnTime(carArrivalTime);

    if (willCarArriveOnTime) {
      return '🟢';
    } else {
      return '🔴';
    }
  }

  String bikeArriveInTime() {
    String bikeArrivalTime =
        calculateArrivalTime(durationBike, formatDepTime(_depTime));
    bool willBikeArriveOnTime = willArriveOnTime(bikeArrivalTime);

    if (willBikeArriveOnTime) {
      return '🟢';
    } else {
      return '🔴';
    }
  }

  String footArriveInTime() {
    String footArrivalTime =
        calculateArrivalTime(durationFoot, formatDepTime(_depTime));
    bool willfootArriveOnTime = willArriveOnTime(footArrivalTime);

    if (willfootArriveOnTime) {
      return '🟢';
    } else {
      return '🔴';
    }
  }

  List<String> arrivalTimeAdvice = [];

  List<String> _travelModesArrivingOnTime() {
    String carArrivalTime =
        calculateArrivalTime(durationCar, formatDepTime(_depTime));
    String bikeArrivalTime =
        calculateArrivalTime(durationBike, formatDepTime(_depTime));
    String footArrivalTime =
        calculateArrivalTime(durationFoot, formatDepTime(_depTime));

    bool willCarArriveOnTime = willArriveOnTime(carArrivalTime);
    bool willBikeArriveOnTime = willArriveOnTime(bikeArrivalTime);
    bool willFootArriveOnTime = willArriveOnTime(footArrivalTime);

    if (willCarArriveOnTime) {
      arrivalTimeAdvice.add("${translation(context).arriveincar} 🟢");
    } else {
      arrivalTimeAdvice.add("${translation(context).arriveincar} 🔴");
    }
    if (willBikeArriveOnTime) {
      arrivalTimeAdvice.add("${translation(context).arriveinbike} 🟢");
    } else {
      arrivalTimeAdvice.add("${translation(context).arriveinbike} 🔴");
    }
    if (willFootArriveOnTime) {
      arrivalTimeAdvice.add("${translation(context).arrivebywalk} 🟢");
    } else {
      arrivalTimeAdvice.add("${translation(context).arrivebywalk} 🔴");
    }

    return arrivalTimeAdvice;
  }

  Icon LocIcon(String suggestion) {
    if (searchHistory.contains(suggestion)) {
      return const Icon(Icons.redo_rounded);
    } else {
      return const Icon(Icons.location_on);
    }
  }

  @override
  void initState() {
    super.initState();
    start.addListener(onStartTextChanged);
    end.addListener(onEndTextChanged);
    _fetchData();
    _generateTestData();
    fetchWeatherData(end, _departureDate);
    //_checkForHealthProblems();
    //_CalculateHealthWeight();
  }

  String getCurrentLocaleLanguage(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale
        .languageCode; // Returns the current language code (e.g., 'en' for English)
  }

  double widthChanger() {
    final currentLanguage = getCurrentLocaleLanguage(context);

    if (currentLanguage == "en") {
      return 60;
    } else if (currentLanguage == "ar") {
      return 30;
    } else {
      return 80;
    }
  }

  double widthChanger2() {
    final currentLanguage = getCurrentLocaleLanguage(context);

    if (currentLanguage == "en") {
      return 95;
    } else if (currentLanguage == "ar") {
      return 120;
    } else {
      return 180;
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

  Color _changeColorTheme600() {
    final currentLanguage = getCurrentLocaleLanguage(context);

    if (currentLanguage == 'en') {
      return Colors.red.shade600;
    } else if (currentLanguage == 'fr') {
      return Colors.blue.shade600;
    } else if (currentLanguage == 'ar') {
      return Colors.green.shade600;
    }

    return Colors.green.shade600;
  }

  Color _changeColorTheme50() {
    final currentLanguage = getCurrentLocaleLanguage(context);

    if (currentLanguage == 'en') {
      return Colors.red.shade50;
    } else if (currentLanguage == 'fr') {
      return Colors.blue.shade50;
    } else if (currentLanguage == 'ar') {
      return Colors.green.shade50;
    }

    return Colors.green.shade50;
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

  bool showOptions = false;

  void toggleOptions() {
    setState(() {
      showOptions = !showOptions;
    });
  }

  @override
  Widget build(BuildContext context) {
    var controller = widget.controller;
    return Scaffold(
      backgroundColor: Colors.white,
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(
          overscroll: false,
        ),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              children: [
                buildDragHandle(),
                Row(
                  children: [
                    const SizedBox(
                      width: 2,
                    ),
                    Text(
                      translation(context).wherewego,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      width: widthChanger2(),
                    ),
                    Container(
                      alignment: Alignment.topRight,
                      child: DropdownButton<Language>(
                        hint: Text(translation(context).changeLanguages),
                        items: Language.languageList()
                            .map<DropdownMenuItem<Language>>(
                              (e) => DropdownMenuItem<Language>(
                                value: e,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: <Widget>[
                                    Text(e.flag),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (Language? language) async {
                          //do something
                          if (language != null) {
                            Locale _locale =
                                await setLocale(language.languageCode);
                            MyApp.setLocale(context, _locale);
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 20,
                ),

                TypeAheadField(
                  textFieldConfiguration: TextFieldConfiguration(
                    controller: start,
                    decoration: InputDecoration(
                      labelText: translation(context).departure,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.my_location),
                        onPressed: getCurrentLocation,
                      ),
                    ),
                  ),
                  suggestionsCallback: (pattern) async {
                    // Fetch auto-completion suggestions for departure
                    final suggestions =
                        await _getAutoCompletionSuggestions(pattern);
                    final combinedSuggestions = [
                      ...searchHistory,
                      ...suggestions
                    ];
                    return combinedSuggestions;
                  },
                  itemBuilder: (context, suggestion) {
                    final isHistoryItem = searchHistory.contains(suggestion);

                    return ListTile(
                      leading: LocIcon(suggestion),
                      title: Text(suggestion.toString()),
                      tileColor: isHistoryItem ? Colors.grey.shade500 : null,
                    );
                  },
                  onSuggestionSelected: (suggestion) {
                    start.text = suggestion.toString();

                    if (!searchHistory.contains(suggestion.toString())) {
                      searchHistory.add(suggestion.toString());
                    }
                  },
                  // Customize the suggestion box appearance
                  suggestionsBoxDecoration: SuggestionsBoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    elevation: 4.0,
                  ),
                  noItemsFoundBuilder: (context) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        translation(context).noitem,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors
                              .grey.shade700, // Adjust the color as needed
                        ),
                      ),
                    );
                  },
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.my_location),
                        onPressed: getCurrentLocationArrival,
                      ),
                    ),
                  ),
                  suggestionsCallback: (pattern) async {
                    // Fetch auto-completion suggestions for arrival
                    final suggestions =
                        await _getAutoCompletionSuggestions(pattern);
                    final combinedSuggestions = [
                      ...searchHistory,
                      ...suggestions
                    ];
                    return combinedSuggestions;
                  },
                  itemBuilder: (context, suggestion) {
                    final bool isHistoryItem =
                        searchHistory.contains(suggestion);
                    return ListTile(
                      leading: LocIcon(suggestion),
                      title: Text(suggestion.toString()),
                      tileColor: isHistoryItem ? Colors.grey.shade400 : null,
                    );
                  },
                  onSuggestionSelected: (suggestion) {
                    end.text = suggestion.toString();

                    if (!searchHistory.contains(suggestion.toString())) {
                      setState(() {
                        searchHistory.add(suggestion.toString());
                      });
                    }
                  },
                  noItemsFoundBuilder: (context) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        translation(context).noitem,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors
                              .grey.shade700, // Adjust the color as needed
                        ),
                      ),
                    );
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

                AnimatedSize(
                  curve: Curves.easeInOut,
                  duration: const Duration(milliseconds: 800),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _changeColorTheme50(),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              translation(context).options,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              width: widthChanger(),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: IconButton(
                                onPressed: toggleOptions,
                                icon: showOptions
                                    ? const Icon(Icons.keyboard_arrow_up)
                                    : const Icon(Icons.keyboard_arrow_down),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Visibility(
                          visible: showOptions,
                          maintainAnimation: true,
                          maintainState: true,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    MaterialButton(
                                      onPressed: _showDepDatePicker,
                                      color: _changeColorTheme(),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.calendar_month,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 5),
                                          Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Text(
                                              translation(context)
                                                  .departureDate,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    // Display chosen time
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        DateFormat('dd/MM/yyyy')
                                            .format(_departureDate),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    MaterialButton(
                                      onPressed: () {
                                        _showCustomDepTimePicker(context);
                                      },
                                      color: _changeColorTheme(),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.access_time,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 5),
                                          Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Text(
                                              translation(context)
                                                  .departureTime,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    // Display chosen time
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        _depTime.format(context).toString(),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    MaterialButton(
                                      onPressed: () {
                                        _showCustomTimePicker(context);
                                      },
                                      color: _changeColorTheme(),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.access_time,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 5),
                                          Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Text(
                                              translation(context).arrivalTime,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    // Display chosen time
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        _timeOfDay.format(context).toString(),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _changeColorTheme(),
                    ),
                    onPressed: () async {
                      storeRequest();
                      // Execute getRoute() for different travel modes
                      await getRouteForTravelMode('car'); // Car
                      await getRouteForTravelMode('bike'); // Bike
                      await getRouteForTravelMode('foot'); // Foot
                      _travelModesArrivingOnTime();

                      final options =
                          await findPublicTransportOptions(start, end);
                      setState(() {
                        TransitOptions = options;
                      });

                      //const HealthIrregularityChecker();
                      //_fetchData();
                      //_generateTestData();
                      _checkForHealthProblems();
                      _CalculateHealthWeight();
                      calculateWeatherWeights();

                      // ignore: use_build_context_synchronously
                      showDialog(
                        context: context,
                        builder: (context) => healthCard(
                          HealthProblems: HealthProblems,
                          context: context,
                        ),
                      );

                      checkForAdvice();
                      CalculateDurationWeight();
                      calculatePurposeWeight();
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
                          distance:
                              double.parse(distanceCar.toStringAsFixed(2)),
                          departure_time: formatDepTime(_depTime),
                          arrival_time: calculateArrivalTime(
                              durationCar, formatDepTime(_depTime)),
                          travelMean: '${translation(context).byCar} 🚗',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ResponsePage(
                                  routpoints: routpointsCar,
                                  duration: double.parse(
                                      durationCar.toStringAsFixed(0)),
                                  distance: double.parse(
                                      distanceCar.toStringAsFixed(2)),
                                  travelMean: translation(context).byCar,
                                ),
                              ),
                            );
                          },
                          backgroundColor: determineBestTravelMode() ==
                                  translation(context).byCar
                              ? _changeColorTheme600()
                              : _changeColorTheme50(),
                          textColor: determineBestTravelMode() ==
                                  translation(context).byCar
                              ? Colors.white
                              : Colors.black,
                          willArriveOnTime: carArriveInTime(),
                        ),

                        const SizedBox(
                          height: 15,
                        ),

                        // RecommendedItem for Bike
                        RecommendedItem(
                          distance:
                              double.parse(distanceBike.toStringAsFixed(2)),
                          departure_time: formatDepTime(_depTime),
                          arrival_time: calculateArrivalTime(
                              durationBike, formatDepTime(_depTime)),
                          travelMean: '${translation(context).byBike} 🚲',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ResponsePage(
                                  routpoints: routpointsBike,
                                  distance: double.parse(
                                      distanceBike.toStringAsFixed(2)),
                                  duration: double.parse(
                                      durationBike.toStringAsFixed(0)),
                                  travelMean: translation(context).byBike,
                                ),
                              ),
                            );
                          },
                          backgroundColor: determineBestTravelMode() ==
                                  translation(context).byBike
                              ? _changeColorTheme600()
                              : _changeColorTheme50(),
                          textColor: determineBestTravelMode() ==
                                  translation(context).byBike
                              ? Colors.white
                              : Colors.black,
                          willArriveOnTime: bikeArriveInTime(),
                        ),

                        const SizedBox(
                          height: 15,
                        ),

                        // RecommendedItem for Foot
                        RecommendedItem(
                          distance:
                              double.parse(distanceFoot.toStringAsFixed(2)),
                          departure_time: formatDepTime(_depTime),
                          arrival_time: calculateArrivalTime(
                              durationFoot, formatDepTime(_depTime)),
                          travelMean: '${translation(context).onFoot} 🚶',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ResponsePage(
                                  routpoints: routpointsFoot,
                                  duration: double.parse(
                                      durationFoot.toStringAsFixed(0)),
                                  distance: double.parse(
                                      distanceFoot.toStringAsFixed(2)),
                                  travelMean: translation(context).onFoot,
                                ),
                              ),
                            );
                          },
                          backgroundColor: determineBestTravelMode() ==
                                  translation(context).onFoot
                              ? _changeColorTheme600()
                              : _changeColorTheme50(),
                          textColor: determineBestTravelMode() ==
                                  translation(context).onFoot
                              ? Colors.white
                              : Colors.black,
                          willArriveOnTime: footArriveInTime(),
                        ),

                        const SizedBox(
                          height: 15,
                        ),

                        TransitOptions.isNotEmpty
                            ? TransitOptionsList(
                                transitOptions: TransitOptions,
                                context: context,
                              )
                            : const SizedBox(),

                        const SizedBox(
                          height: 15,
                        ),
                        /*
                        Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: _changeColorTheme50(),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            arrivalTimeAdvice.join("\n\n"),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
      
                        const SizedBox(
                          height: 15,
                        ),
      */

                        Text(
                          adviceList.join("\n\n"),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
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

  Widget buildDragHandle() => GestureDetector(
        child: Center(
          child: Container(
            width: 35,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        onTap: () {
          PanelController().isPanelOpen
              ? PanelController().close()
              : PanelController().open();
        },
      );
}
