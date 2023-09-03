import 'package:flutter/material.dart';
import 'package:map/classes/language_constants.dart';
import '../pages/search_page.dart';

class TransitOptionsList extends StatelessWidget {
  final List<TransitOption> transitOptions;
  final BuildContext context;

  TransitOptionsList({required this.transitOptions, required this.context});

  String getCurrentLocaleLanguage(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale
        .languageCode; // Returns the current language code (e.g., 'en' for English)
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

  @override
  Widget build(BuildContext context) {
    // Filter unique options and limit to three
    final uniqueOptions = transitOptions.toSet().toList().take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _changeColorTheme50(),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            translation(context).publicTransport,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            itemCount: uniqueOptions.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(uniqueOptions[index].name),
                subtitle: Text(uniqueOptions[index].type),
              );
            },
          ),
        ],
      ),
    );
  }
}
