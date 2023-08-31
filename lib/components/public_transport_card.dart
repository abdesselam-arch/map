import 'package:flutter/material.dart';
import 'package:map/classes/language_constants.dart';
import '../pages/search_page.dart';

class TransitOptionsList extends StatelessWidget {
  final List<TransitOption> transitOptions;

  TransitOptionsList({required this.transitOptions});

  @override
  Widget build(BuildContext context) {
    // Filter unique options and limit to three
    final uniqueOptions = transitOptions.toSet().toList().take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
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
