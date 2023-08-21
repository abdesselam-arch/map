// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:health/health.dart';

class HealthIrregularityChecker extends StatefulWidget {
  const HealthIrregularityChecker({super.key});

  @override
  _HealthIrregularityCheckerState createState() =>
      _HealthIrregularityCheckerState();
}

class _HealthIrregularityCheckerState extends State<HealthIrregularityChecker> {
  HealthFactory health = HealthFactory(useHealthConnectIfAvailable: true);
  bool hasIrregularities = false;
  List<String> irregularities = [];
  double dailySteps = 2600;
  dynamic steps;
  dynamic heartRate;
  dynamic bodyTemp;
  dynamic bloodPreSys;
  dynamic bloodPreDia;
  dynamic bloodPressure;
  dynamic bloodGlucose;
  dynamic respRate;
  dynamic bloodOxy;

  @override
  void initState() {
    super.initState();
    _fetchHealthData();
    _createTestData();
    _CalculateHealthWeight();
    _checkForIrregularities();
  }

  // This function is gonna help us retrieve the health informations sunch as heart rate, steps, blood pressure ...etc
  Future<void> _fetchHealthData() async {
    try {
      DateTime now = DateTime.now();

      final types = [
        HealthDataType.HEART_RATE,
        HealthDataType.STEPS,
        HealthDataType.BLOOD_OXYGEN,
        HealthDataType.RESPIRATORY_RATE,
        HealthDataType.BLOOD_GLUCOSE,
        HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
        HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
        HealthDataType.BODY_TEMPERATURE,
      ];
      // ignore: unused_local_variable
      bool requested = await health.requestAuthorization(types);

      // fetch health data from the last 24 hours
      List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
          now.subtract(const Duration(days: 1)), now, types);

      if (requested) {
        if (healthData.isNotEmpty) {
          for (HealthDataPoint h in healthData) {
            if (h.type == HealthDataType.HEART_RATE) {
              heartRate = h.value;
            } else if (h.type == HealthDataType.BODY_TEMPERATURE) {
              bodyTemp = h.value;
            } else if (h.type == HealthDataType.STEPS) {
              steps = h.value;
            } else if (h.type == HealthDataType.BLOOD_GLUCOSE) {
              bloodGlucose = h.value;
            } else if (h.type == HealthDataType.BLOOD_OXYGEN) {
              bloodOxy = h.value;
            } else if (h.type == HealthDataType.BLOOD_PRESSURE_DIASTOLIC) {
              bloodPreDia = h.value;
            } else if (h.type == HealthDataType.BLOOD_PRESSURE_SYSTOLIC) {
              bloodPreSys = h.value;
            }
          }
          if (bloodPreDia != null && bloodPreSys != null) {
            bloodPressure = "$bloodPreSys / $bloodPreDia mmHg";
          }
        }
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void _createTestData() {
    // Generate testing data for heartRate, bloodPressure, etc.
    steps = 3000;
    heartRate = 70.0;
    bodyTemp = 37.5;
    bloodPreSys = 110.0;
    bloodPreDia = 70.0;
    bloodGlucose = 120.0;
    respRate = 18.0;
    bloodOxy = 98.0;
  }

  // Function to show the irregularities in a pop-up dialog
  void _showIrregularitiesDialog(List<dynamic> irregularities) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text('Health Irregularities Detected'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: irregularities.map((irregularity) {
              return ListTile(
                title: Text(
                  irregularity,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              );
            }).toList(),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkForIrregularities() async {
    if (heartRate != 0.0) {
      if (heartRate > 60.0) {
        irregularities.add('Heart Rate: $heartRate bpm');
      }
    }
    if (bodyTemp != 0.0) {
      if (bodyTemp > 38.0) {
        irregularities.add('Body Tempureture: $bodyTemp °C');
      }
    }
    if (respRate != 0.0) {
      if (respRate > 12.0 && respRate < 25.0) {
        irregularities.add('Respiratory Rate: $respRate');
      }
    }
    if (bloodPreDia != 0.0 && bloodPreSys != 0.0) {
      if ((bloodPreDia > 60.0 && bloodPreDia < 80.0) ||
          (bloodPreSys > 90.0 && bloodPreSys < 120.0)) {
        irregularities.add('Blood Pressure: $bloodPreSys / $bloodPreDia mmHg');
      }
    }
    if (irregularities.length > 3) {
      hasIrregularities = true;
      //show irregularites in a dialog
      _showIrregularitiesDialog(irregularities);
    }
  }

  // ignore: non_constant_identifier_names
  Future<double> _CalculateHealthWeight() async {
    double stepsWeight = steps as double;
    var w = 0.0;
    if (hasIrregularities = false) {
      w = 0.6 * stepsWeight / dailySteps;
    }
    return w;
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
