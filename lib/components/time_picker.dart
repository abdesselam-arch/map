import 'package:flutter/material.dart';
import 'package:map/classes/language_constants.dart';
import 'package:numberpicker/numberpicker.dart';

class CustomTimePicker extends StatefulWidget {
  final Function(TimeOfDay) onChanged;
  final TimeOfDay initialTime;
  final String time;

  CustomTimePicker(
      {Key? key,
      required this.onChanged,
      required this.initialTime,
      required this.time})
      : super(key: key);

  @override
  _CustomTimePickerState createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  late int _hour;
  late int _minute;
  String timeFormat = "AM";

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

  @override
  void initState() {
    super.initState();
    _hour = TimeOfDay.now().hour;
    _minute = TimeOfDay.now().minute;
  }

  @override
  Widget build(BuildContext context) {
    String time = widget.time;
    return Container(
      height: 300,
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Colors.black,
                ),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              NumberPicker(
                zeroPad: true,
                infiniteLoop: true,
                itemWidth: 80,
                itemHeight: 60,
                value: _hour,
                minValue: 0,
                maxValue: 23,
                onChanged: (value) {
                  setState(() {
                    _hour = value;
                  });
                  widget.onChanged(_getTimeOfDay());
                },
                textStyle: const TextStyle(color: Colors.grey, fontSize: 20),
                selectedTextStyle:
                    const TextStyle(color: Colors.black, fontSize: 30),
                decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(
                        color: Colors.black,
                      ),
                      bottom: BorderSide(color: Colors.black)),
                ),
              ),
              NumberPicker(
                value: _minute,
                minValue: 0,
                maxValue: 59,
                zeroPad: true,
                infiniteLoop: true,
                itemWidth: 80,
                itemHeight: 60,
                onChanged: (value) {
                  setState(() {
                    _minute = value;
                  });
                  widget.onChanged(_getTimeOfDay());
                },
                textStyle: const TextStyle(color: Colors.grey, fontSize: 20),
                selectedTextStyle:
                    const TextStyle(color: Colors.black, fontSize: 30),
                decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(
                        color: Colors.black,
                      ),
                      bottom: BorderSide(color: Colors.black)),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ), // Add spacing between NumberPickers and buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  // Save button action
                  widget.onChanged(_getTimeOfDay());
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text(translation(context).save),
              ),
              SizedBox(width: 20), // Add spacing between buttons
              ElevatedButton(
                onPressed: () {
                  // Cancel button action
                  setState(() {
                    _minute = TimeOfDay.now().minute;
                    _hour = TimeOfDay.now().hour;
                  });
                  Navigator.of(context)
                      .pop(); // Close the dialog without saving
                },
                style: ElevatedButton.styleFrom(primary: Colors.red),
                child: Text(translation(context).cancel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TimeOfDay _getTimeOfDay() {
    return TimeOfDay(
      hour: _hour,
      minute: _minute,
    );
  }
}
