import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherService {
  
  static const String _weatherBaseUrl = "https://api.open-meteo.com/v1/forecast";
  static const String _geoBaseUrl = "https://geocoding-api.open-meteo.com/v1/search";
  
  // 根据经纬度，获取天气
  Future<Map<String, dynamic>> fetchWeather(double lat, double lon) async {
    
    final String url = 
        "$_weatherBaseUrl?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code,is_day&hourly=temperature_2m,weather_code,is_day&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return jsonDecode(response.body); 
      } else {
        throw Exception("天气服务错误: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("网络连接失败: $e");
    }
  }

  //根据城市名，搜索经纬度
  Future<Map<String, dynamic>?> searchCity(String cityName) async {
    final String url = "$_geoBaseUrl?name=$cityName&count=1&language=zh&format=json";

    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('results') && data['results'].isNotEmpty) {
          return data['results'][0]; 
        } else {
          return null; 
        }
      } else {
        throw Exception("搜索服务错误: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("搜索网络失败: $e");
    }
  }
}