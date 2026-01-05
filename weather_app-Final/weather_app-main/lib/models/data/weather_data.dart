// lib/models/data/weather_data.dart

class ForecastData {
  final String day;
  final String temperature;
  final String wind;

  ForecastData({
    required this.day,
    required this.temperature,
    required this.wind,
  });

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    return ForecastData(
      day: json['day'] ?? 'N/A',
      temperature: json['temperature'] ?? 'N/A',
      wind: json['wind'] ?? 'N/A',
    );
  }
}

class WeatherData {
  final String cityName;
  final String temperature;
  final String wind;
  final String description;
  final List<ForecastData> forecast;

  WeatherData({
    required this.cityName,
    required this.temperature,
    required this.wind,
    required this.description,
    required this.forecast,
  });

  factory WeatherData.fromJson(Map<String, dynamic>? json, String city) {
    if (json == null) {
      return WeatherData(
        cityName: city,
        temperature: 'N/A',
        wind: 'N/A',
        description: 'N/A',
        forecast: [],
      );
    }

    final forecastList = (json['forecast'] as List?)
        ?.map((f) => ForecastData.fromJson(f))
        .toList() ??
        [];

    return WeatherData(
      cityName: city,
      temperature: json['temperature'] ?? 'N/A',
      wind: json['wind'] ?? 'N/A',
      description: json['description'] ?? 'N/A',
      forecast: forecastList,
    );
  }
}