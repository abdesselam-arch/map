import 'package:flutter/material.dart';

enum TravelMean {
  WALKING,
  BIKING,
  DRIVING
} // Define other travel means if required }

enum TravelPurpose { NONE } // Define other travel purposes if required }

class DirectionsModel with ChangeNotifier {
  // Constants
  static const double cMedical = 0.538;
  static const double cWeather = 0.2625;
  static const double cDuration = 0.121;
  static const double cPurpose = 0.077;
  // 0.538 + 0.2625 + 0.121 + 0.077 = 1
  // normalized weights calculated using fuzzy ahp to use with the wsm model

  // each criteria's calculated weight
  var WeatherW, HealthW, PurposeW, DurationW;

  TravelPurpose purpose = TravelPurpose.NONE;

  void WeatherWeight() {}

  void HealthWeight() {}

  void PurposeWeight() {
    // Calculate possibilities by transport purpose
    // ignore: unrelated_type_equality_checks
    if (purpose == 'Medical Condition') {
      if (TravelMean == TravelMean.BIKING) {
        // ignore: unused_local_variable
        double PurposeW = 0.15;
      } else if (TravelMean == TravelMean.WALKING) {
        // ignore: unused_local_variable
        double PurposeW = 0.09;
      } else if (TravelMean == TravelMean.DRIVING) {
        // ignore: unused_local_variable
        double PurposeW = 0.5;
      }
    } else if (purpose == 'Travel') {
      if (TravelMean == TravelMean.BIKING) {
        // ignore: unused_local_variable
        double PurposeW = 0.15;
      } else if (TravelMean == TravelMean.WALKING) {
        // ignore: unused_local_variable
        double PurposeW = 0.5;
      } else if (TravelMean == TravelMean.DRIVING) {
        // ignore: unused_local_variable
        double PurposeW = 0.09;
      }
    } else if (purpose == 'Education' || purpose == 'Work') {
      if (TravelMean == TravelMean.BIKING) {
        // ignore: unused_local_variable
        double PurposeW = 0.26;
      } else if (TravelMean == TravelMean.WALKING) {
        // ignore: unused_local_variable
        double PurposeW = 0.5;
      } else if (TravelMean == TravelMean.DRIVING) {
        // ignore: unused_local_variable
        double PurposeW = 0.09;
      }
    }
  }

  void Duration() {}
}
