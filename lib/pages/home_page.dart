import 'package:flutter/material.dart';
import 'package:map/classes/language_constants.dart';
import 'package:map/pages/map_page.dart';
import 'package:map/pages/search_page.dart';
import 'package:map/pages/settings_page.dart';
//import 'package:map/components/bottom_nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String getCurrentLocaleLanguage(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale
        .languageCode; // Returns the current language code (e.g., 'en' for English)
  }

  Color _changeColorTheme() {
    final currentLanguage = getCurrentLocaleLanguage(context);

    if (currentLanguage == 'en') {
      return Colors.red.shade700;
    } else if (currentLanguage == 'fr') {
      return Colors.blue.shade700;
    } else if (currentLanguage == 'ar') {
      return Colors.green.shade700;
    }

    return Colors.green.shade700;
  }

  final List<Widget> _pages = [
    const MapPage(),
    const SearchPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: _changeColorTheme(),
        currentIndex: _selectedIndex,
        onTap: _navigateBottomBar,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey.shade300,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home, size: 28,),
            label: translation(context).home.toString(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search, size: 28,),
            label: translation(context).search.toString(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings, size: 28,),
            label: translation(context).settings.toString(),
          ),
        ],
      ),
    );
  }
}
