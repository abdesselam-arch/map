import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart'; // For GeoPoint representation
//import 'package:http/http.dart' as http;
//import 'dart:convert';

enum TravelMean { WALKING, BIKING} // Define other travel means if required }

enum TravelPurpose { NONE }// Define other travel purposes if required }

class RouteInformation {
  
  getDuration() {
    return;
  }
  
  TravelMean getMode() {
    return TravelMean.BIKING;
  }
  
  getWeight() {
    
  }
  // Define the RouteInformation class if it doesn't already exist
}

class HealthParameters {
  // Define the HealthParameters class if it doesn't already exist
}

class WeatherInformation {
  // Define the WeatherInformation class if it doesn't already exist
}

class DirectionsViewModel with ChangeNotifier {
  // Constants
  static const int cMedical = 4;
  static const int cWeather = 3;
  static const int cDuration = 2;
  static const int cPurpose = 1;

  // Attributes
  // A list of routes
  List<RouteInformation> routeInformations = [];

  // Coordinates of start and destination of the route
  late LatLng origin, destination;
  late String originAddress, destinationAddress;

  // Travel purpose
  TravelPurpose purpose = TravelPurpose.NONE;

  // Destination weather information
  late WeatherInformation destinationWeather;

  // Medical weight (probability of going on foot or by bike)
  late double medicalWeight;

  // List of unordinary health parameters
  late List<HealthParameters> unhealthyParams;

  // Methods

  // Adds a route to the list
  void addRouteInformations(RouteInformation routeInformations) {
    this.routeInformations.add(routeInformations);
    notifyListeners();
  }

  // Find each mean's weight according to weather and purpose criteria
  Future<double> getProbabilities() async {
    // Calculate possibilities by transport purpose
    // purpose.getPossibleMeans(purposeRecomm); // Implement this method if needed

    // Calculate total duration
    double duration = 0;
    for (RouteInformation info in routeInformations) {
      duration += double.parse(info.getDuration());
    }

    // Calculate possibilities by weather
    // Implement the logic to fetch weather information using Flutter packages or APIs
    // WeatherInformation weather = await getWeatherByLocation(); // Implement this method

    // Keep destination weather information
    // destinationWeather = await getWeatherByCoord(destination.latitude, destination.longitude); // Implement this method

    // Return total duration
    return duration;
  }

  // Algorithm to choose the best recommendations
  Future<void> setBestRecommendations() async {
    // Find Mean possibility according to a criteria
    // HashMap<TravelMean, double> weatherRecomm = new HashMap<>();
    // HashMap<TravelMean, double> purposeRecomm = new HashMap<>();
    
    //double duration = await getProbabilities();

    // Calculate final possibilities
    // ignore: unused_local_variable
    for (RouteInformation route in routeInformations) {
      
      //TravelMean mode = route.getMode();
      
      // Implement the logic to calculate wWeather, wPurpose, wRoute, and wMedical
      // double wWeather = ...;
      // double wPurpose = ...;
      // double wRoute = ...;
      // double wMedical = ...;

      //route.setWeight(cMedical * wMedical + wWeather * cWeather + wPurpose * cPurpose + wRoute * cDuration);
      //print('Route ${route.getTranslatedMode(context)}: w $wWeather; p $wPurpose; d $wRoute; m $wMedical = ${route.getWeight()}');
    }

    // Apply order descending
    routeInformations.sort((a, b) => b.getWeight().compareTo(a.getWeight()));
    notifyListeners();
  }

  // Checks whether a user's health permits travel
  bool isHealthy() {
    return unhealthyParams.length < 3;
  }

  // Clear Attributes
  void clear() {
    
    /*
    origin = null;
    destination = null;
    originAddress = null;
    destinationAddress = null;
    destinationWeather = null;
    purpose = TravelPurpose.NONE;
    routeInformations.clear();
    notifyListeners();
    */
  }

  // Accessors
  // Implement accessors for all the attributes as needed
}

// Implement the rest of the classes (RouteInformation, HealthParameters, WeatherInformation) if they are not already defined in your Flutter project.
