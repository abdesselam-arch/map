import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:map/model/weather_model.dart';

class weatherApiClient {
  Future<Weather>? getCurrentWeather(String? location) async {
    var endpoint = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?q=$location&appid=9288b0a87c194f099c4a28c2322ca8c0&units=metric");

    var response = await http.get(endpoint);
    var body = jsonDecode(response.body);
    print(Weather.fromJson(body));
    return Weather.fromJson(body);
  }
}
