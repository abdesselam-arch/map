import 'package:flutter/material.dart';
import 'package:map/pages/map_page.dart';
import 'package:map/pages/search_page.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
//import 'package:map/components/bottom_nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /*int _selectedIndex = 0;

  void _navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }*/

  String getCurrentLocaleLanguage(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale
        .languageCode; // Returns the current language code (e.g., 'en' for English)
  }

  final panelController = PanelController();
  //static const double fabHeightClosed = 116.0;
  //double fabHeight = fabHeightClosed;

  @override
  Widget build(BuildContext context) {
    final panelHeightClosed = MediaQuery.of(context).size.height * 0.35;
    final panelHeightOpen = MediaQuery.of(context).size.height * 0.8;
    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          SlidingUpPanel(
            controller: panelController,
            minHeight: panelHeightClosed,
            maxHeight: panelHeightOpen,
            parallaxEnabled: true,
            parallaxOffset: .5,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(18),
            ),
            body: const MapPage(),
            panelBuilder: (controller) => SearchPage(
              controller: controller,
              panelcontroller: panelController,
            ),
          ),
        ],
      ),
      /*
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
      ),*/
    );
  }
}
