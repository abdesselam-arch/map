class Weather {
  String? cityName;
  double? tempurature;
  int? pressure;
  double? windSpeed;
  double? windDegree;
  int? humidity;
  double? clouds;

  Weather(
      {this.cityName,
      this.tempurature,
      this.pressure,
      this.windSpeed,
      this.windDegree,
      this.humidity,
      this.clouds});

  // now build a function to parse the json file into the model   OwmJSONParser.java

  Weather.fromJson(Map<String, dynamic> json) {
    cityName = json["name"];
    tempurature = json["current"]["temp"];
    pressure = json["current"]["pressure"];
    windSpeed = json["current"]["wind_speed"];
    windDegree = json["current"]["wind_deg"];
    humidity = json["current"]["humidity"];
    clouds = json["current"]["clouds"];
  }
}
