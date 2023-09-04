import 'package:flutter/material.dart';
import 'package:map/classes/language_constants.dart';

class RecommendedItem extends StatelessWidget {
  final double distance;
  final String departure_time;
  final String arrival_time;
  final String travelMean;
  final void Function()? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final String willArriveOnTime;

  const RecommendedItem({
    super.key,
    required this.distance,
    required this.departure_time,
    required this.arrival_time,
    required this.travelMean,
    required this.onPressed,
    required this.backgroundColor,
    required this.textColor,
    required this.willArriveOnTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.only(
        left: 15,
        bottom: 15,
      ),
      margin: const EdgeInsets.only(left: 20, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      translation(context).distance,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),
                    Text(
                      '$distance KM',
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      translation(context).depTime,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      departure_time,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      translation(context).arrTime,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          arrival_time,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(willArriveOnTime),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      translation(context).travelMean,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      travelMean,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onPressed,
                icon: Icon(
                  Icons.map_outlined,
                  color: textColor,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
