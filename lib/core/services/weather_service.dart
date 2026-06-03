import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';

class WeatherData {
  final double temperature;
  final String condition;
  final String description;
  final int humidity;
  final String iconCode;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.description,
    required this.humidity,
    required this.iconCode,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final main = json['main'] ?? {};
    final weatherList = json['weather'] as List?;
    final weather = (weatherList != null && weatherList.isNotEmpty) ? weatherList[0] : {};

    return WeatherData(
      temperature: (main['temp'] as num?)?.toDouble() ?? 0.0,
      condition: weather['main'] ?? 'Clear',
      description: weather['description'] ?? 'clear sky',
      humidity: main['humidity'] ?? 0,
      iconCode: weather['icon'] ?? '01d',
    );
  }
}

class WeatherService {
  Future<WeatherData> fetchWeather(String city) async {
    const apiKey = ApiKeys.openWeatherApiKey;
    
    // Check if the API key has been filled out by the user
    if (apiKey == 'YOUR_OPENWEATHER_API_KEY_HERE' || apiKey.trim().isEmpty) {
      throw Exception('API_KEY_MISSING');
    }

    final encodedCity = Uri.encodeComponent(city);
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?q=$encodedCity&appid=$apiKey&units=metric',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('API_KEY_INVALID');
      } else if (response.statusCode == 404) {
        throw Exception('CITY_NOT_FOUND');
      } else {
        throw Exception('Failed to fetch weather: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('API_KEY') || e.toString().contains('CITY')) {
        rethrow;
      }
      throw Exception('Network error: check internet connection.');
    }
  }
}
