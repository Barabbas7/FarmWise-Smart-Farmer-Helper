import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;

class City {
  final String name;
  final double latitude;
  final double longitude;
  final String? country;
  final String? admin1; // State/Region

  City({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.country,
    this.admin1,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      country: json['country'] as String?,
      admin1: json['admin1'] as String?,
    );
  }
}

class WeatherData {
  final double temperatureC;
  final double? windSpeed;
  final String? weatherCodeLabel;
  final List<DailyForecast> daily;

  WeatherData({
    required this.temperatureC,
    this.windSpeed,
    this.weatherCodeLabel,
    required this.daily,
  });
}

class DailyForecast {
  final DateTime date;
  final double tempMaxC;
  final double tempMinC;
  final int? precipitationProb;
  final int? weatherCode;

  DailyForecast({
    required this.date,
    required this.tempMaxC,
    required this.tempMinC,
    this.precipitationProb,
    this.weatherCode,
  });
}

class WeatherService {
  // Default coordinates (Addis Ababa, Ethiopia) as fallback
  static const double defaultLat = 9.005401;
  static const double defaultLong = 38.763611;

  Future<WeatherData> fetchWeather({double? lat, double? long}) async {
    final latitude = lat ?? defaultLat;
    final longitude = long ?? defaultLong;

    final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current_weather=true&daily=weathercode,temperature_2m_max,temperature_2m_min,precipitation_probability_mean&timezone=auto');

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load weather');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;

    final current =
        data['current_weather'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final daily = data['daily'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final tempsMax = (daily['temperature_2m_max'] as List?)?.cast<num>() ?? [];
    final tempsMin = (daily['temperature_2m_min'] as List?)?.cast<num>() ?? [];
    final precip =
        (daily['precipitation_probability_mean'] as List?)?.cast<num>() ?? [];
    final weatherCodes = (daily['weathercode'] as List?)?.cast<num>() ?? [];
    final datesRaw = (daily['time'] as List?)?.cast<String>() ?? [];

    final forecasts = <DailyForecast>[];
    for (int i = 0; i < datesRaw.length; i++) {
      forecasts.add(DailyForecast(
        date: DateTime.parse(datesRaw[i]),
        tempMaxC: (i < tempsMax.length ? tempsMax[i].toDouble() : 0),
        tempMinC: (i < tempsMin.length ? tempsMin[i].toDouble() : 0),
        precipitationProb: (i < precip.length ? precip[i].toInt() : null),
        weatherCode: (i < weatherCodes.length ? weatherCodes[i].toInt() : null),
      ));
    }

    return WeatherData(
      temperatureC: (current['temperature'] as num?)?.toDouble() ?? 0,
      windSpeed: (current['windspeed'] as num?)?.toDouble(),
      weatherCodeLabel: _codeToLabel(current['weathercode'] as int?),
      daily: forecasts,
    );
  }

  Future<List<City>> searchCities(String query) async {
    if (query.length < 2) return [];

    final uri = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=$query&count=10&language=en&format=json');

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to search cities');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final results = data['results'] as List?;

    if (results == null) return [];

    return results.map((e) => City.fromJson(e)).toList();
  }

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<String?> getCityNameFromCoordinates(double lat, double long) async {
    try {
      List<geo.Placemark> placemarks =
          await geo.placemarkFromCoordinates(lat, long);
      if (placemarks.isNotEmpty) {
        return placemarks.first.locality ??
            placemarks.first.subAdministrativeArea ??
            placemarks.first.administrativeArea;
      }
    } catch (e) {
      // debugPrint('Failed to get placemark: $e');
    }
    return null;
  }

  /// Helper to guess coordinates from a city string using the geocoding search API
  Future<Map<String, double>?> getCoordinatesFromCityName(
      String cityName) async {
    try {
      final cities = await searchCities(cityName);
      if (cities.isNotEmpty) {
        return {
          'latitude': cities.first.latitude,
          'longitude': cities.first.longitude
        };
      }
    } catch (e) {
      // ignore error
    }
    return null;
  }

  static String? _codeToLabel(int? code) {
    if (code == null) return null;
    if (code == 0) return 'Clear';
    if (code == 1 || code == 2) return 'Partly Cloudy';
    if (code == 3) return 'Overcast';
    if (code == 45 || code == 48) return 'Fog';
    if (code == 51 || code == 53 || code == 55) return 'Drizzle';
    if (code == 61 || code == 63 || code == 65) return 'Rain';
    if (code == 71 || code == 73 || code == 75) return 'Snow';
    if (code == 80 || code == 81 || code == 82) return 'Showers';
    if (code == 95 || code == 96 || code == 99) return 'Thunderstorm';
    return 'Weather';
  }
}
