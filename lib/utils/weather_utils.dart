import 'package:flutter/material.dart';

class WeatherUtils {
  // 数字转中文
  static String getWeatherDesc(int code) {
    if (code == 0) return "晴朗";
    if (code >= 1 && code <= 3) return "多云";
    if (code >= 45 && code <= 48) return "雾";
    if (code >= 51 && code <= 67) return "阴雨";
    if (code >= 71 && code <= 77) return "下雪";
    if (code >= 95) return "雷暴";
    return "未知";
  }

  // 数字转图标
  static IconData getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code >= 1 && code <= 3) return Icons.wb_cloudy;
    if (code >= 51 && code <= 67) return Icons.umbrella;
    if (code >= 71 && code <= 77) return Icons.ac_unit;
    if (code >= 95) return Icons.flash_on;
    return Icons.cloud;
  }

  // 日期格式化 (截取月-日)
  static String formatDate(String dateStr) {
    if (dateStr.length > 5) {
      return dateStr.substring(5);
    }
    return dateStr;
  }
}