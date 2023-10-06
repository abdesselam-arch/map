import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final IconButton suffixIcon;
  final BuildContext context;

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.suffixIcon,
    required this.context,
  });

  String getCurrentLocaleLanguage(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale
        .languageCode; // Returns the current language code (e.g., 'en' for English)
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

  Color _changeColorTheme800() {
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

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: _changeColorTheme600(),
            ),
          ),
          suffixIcon: suffixIcon,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: _changeColorTheme800(),
            ),
          ),
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[500],
          )),
    );
  }
}
