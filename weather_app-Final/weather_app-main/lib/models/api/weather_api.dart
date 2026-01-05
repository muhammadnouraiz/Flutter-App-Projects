// lib/models/api/weather_api.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/weather_data.dart';

class WeatherApi {
  static const String _baseUrl = 'http://goweather.xyz/weather';

  static Future<WeatherData> fetchWeather(String cityName) async {
    final url = '$_baseUrl/$cityName';
    print('🌍 Fetching weather for: $url');

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return WeatherData.fromJson(json, cityName);
      } else if (response.statusCode == 404) {
        throw Exception('City not found');
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      throw Exception('Error fetching weather data: $e');
    }
  }
}