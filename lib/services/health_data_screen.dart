import 'dart:math';

import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:map/classes/language_constants.dart';

void main() => runApp(const HealthApp());

class HealthApp extends StatelessWidget {
  const HealthApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HealthDataScreen(),
    );
  }
}

class HealthDataScreen extends StatefulWidget {
  const HealthDataScreen({Key? key}) : super(key: key);

  @override
  _HealthDataScreenState createState() => _HealthDataScreenState();
}

class _HealthDataScreenState extends State<HealthDataScreen> {
  List<String> HealthProblems = [];
  bool hasHealthProblems = false;
  double dailySteps = 2600;

  String? heartRate;
  String? bp;
  String? steps;
  String? bodyTemp;
  String? bloodGlucose;
  String? respRate;
  String? bloodOxy;

  String? bloodPreSys;
  String? bloodPreDia;

  List<HealthDataPoint> healthData = [];

  HealthFactory health = HealthFactory();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _generateTestData();
    _checkForHealthProblems();
    _CalculateHealthWeight();
  }

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
              heartRate = "${h.value}";
            } else if (h.type == HealthDataType.BLOOD_PRESSURE_SYSTOLIC) {
              bloodPreSys = "${h.value}";
            } else if (h.type == HealthDataType.BLOOD_PRESSURE_DIASTOLIC) {
              bloodPreDia = "${h.value}";
            } else if (h.type == HealthDataType.STEPS) {
              steps = "${h.value}";
            } else if (h.type == HealthDataType.BODY_TEMPERATURE) {
              bodyTemp = "${h.value}";
            } else if (h.type == HealthDataType.BLOOD_GLUCOSE) {
              bloodGlucose = "${h.value}";
            } else if (h.type == HealthDataType.RESPIRATORY_RATE) {
              respRate = "${h.value}";
            } else if (h.type == HealthDataType.BLOOD_OXYGEN) {
              bloodOxy = "${h.value}";
            }
          }
          if (bloodPreSys != "null" && bloodPreDia != "null") {
            bp = "$bloodPreSys / $bloodPreDia mmHg";
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
    if (heartRate != "null") {
      double heartRatecheck = heartRate as double;
      if (heartRatecheck > 60.0) {
        HealthProblems.add("Heart Rate: $heartRate");
      }
    }
    if (bodyTemp != "null") {
      double bodyTempcheck = bodyTemp as double;
      if (bodyTempcheck > 38.0) {
        HealthProblems.add('Body Tempureture: $bodyTemp °C');
      }
    }
    if (respRate != "null") {
      double respRatecheck = respRate as double;
      if (respRatecheck > 12.0 && respRatecheck < 25.0) {
        HealthProblems.add('Respiratory Rate: $respRate');
      }
    }
    if (bloodPreDia != "null" && bloodPreSys != "null") {
      double bloodPreDiacheck = bloodPreDia as double;
      double bloodPreSyscheck = bloodPreSys as double;
      if ((bloodPreDiacheck > 60.0 && bloodPreDiacheck < 80.0) ||
          (bloodPreSyscheck > 90.0 && bloodPreSyscheck < 120.0)) {
        HealthProblems.add('Blood Pressure: $bloodPreSys / $bloodPreDia mmHg');
      }
    }
    if (HealthProblems.length > 3) {
      hasHealthProblems = true;
    }
  }

  // ignore: non_constant_identifier_names
  Future<double> _CalculateHealthWeight() async {
    double stepsWeight = steps as double;
    var w = 0.0;
    if (hasHealthProblems = false) {
      w = 0.6 * stepsWeight / dailySteps;
    }
    return w;
  }

  /// Generate random health data for testing.
  Future _generateTestData() async {
    final random = Random();

    heartRate = (60 + random.nextInt(40))
        .toString(); // Generates a heart rate between 60 and 100 bpm.
    bloodPreSys = (90 + random.nextInt(40))
        .toString(); // Generates a systolic blood pressure between 90 and 130 mmHg.
    bloodPreDia = (60 + random.nextInt(30))
        .toString(); // Generates a diastolic blood pressure between 60 and 90 mmHg.
    steps = (2000 + random.nextInt(8000))
        .toString(); // Generates a random number of steps between 2000 and 10000.
    bodyTemp = (35.5 + (random.nextDouble() * 2)).toStringAsFixed(
        1); // Generates a random body temperature between 35.5 and 37.5 degrees Celsius.
    bloodGlucose = (70 + random.nextInt(50))
        .toString(); // Generates a random blood glucose level between 70 and 120 mg/dL.
    respRate = (10 + random.nextInt(20))
        .toString(); // Generates a random respiratory rate between 10 and 30 breaths per minute.
    bloodOxy = (95 + random.nextInt(5))
        .toString(); // Generates a random blood oxygen level between 95% and 100%.

    bp =
        "$bloodPreSys / $bloodPreDia mmHg"; // Combines systolic and diastolic blood pressure.

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}

Widget healthCard({
  // ignore: non_constant_identifier_names
  required final List<String> HealthProblems,
  required final BuildContext context,
}) {
  return ScrollConfiguration(
    behavior: const ScrollBehavior().copyWith(
      overscroll: false,
    ),
    child: Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              translation(context).healthProblemsDetected,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(
              height: 10,
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: HealthProblems.length,
              itemBuilder: (context, index) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(HealthProblems[index]),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
