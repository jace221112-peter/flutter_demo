import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../utils/weather_utils.dart';
import '../widgets/glass_card.dart';

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  // === 状态变量 ===
  bool _isLoading = true;
  String _errorMessage = "";
  
  // 默认位置：北京 (后面会被搜索结果覆盖)
  String _displayCityName = "北京市"; 
  double _lat = 39.9042;
  double _lon = 116.4074;

  // UI 天气数据
  String _currentTemp = "--";
  String _weatherCondition = "加载中";
  IconData _weatherIcon = Icons.cloud;
  String _highTemp = "--";
  String _lowTemp = "--";
  List<dynamic> _hourlyList = [];
  List<dynamic> _dailyList = [];

  // 服务类实例
  final WeatherService _weatherService = WeatherService(); 
  // 文本输入控制器 (用来获取用户输入的内容)
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWeatherData(); // 启动时加载默认城市
  }

  // === 核心逻辑 1: 加载天气 ===
  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true; // 开始转圈
      _errorMessage = ""; // 清空错误
    });

    try {
      // 调用 Service，传入当前的经纬度
      final data = await _weatherService.fetchWeather(_lat, _lon);

      // 解析数据 (和之前一样)
      final current = data['current'];
      final daily = data['daily'];

      setState(() {
        _currentTemp = current['temperature_2m'].round().toString();
        _weatherCondition = WeatherUtils.getWeatherDesc(current['weather_code']);
        _weatherIcon = WeatherUtils.getWeatherIcon(current['weather_code']);
        _highTemp = daily['temperature_2m_max'][0].round().toString();
        _lowTemp = daily['temperature_2m_min'][0].round().toString();

        // 小时数据逻辑
        _hourlyList.clear();
        int currentHour = DateTime.now().hour;
        List<dynamic> rawHourlyTemps = data['hourly']['temperature_2m'];
        List<dynamic> rawHourlyCodes = data['hourly']['weather_code'];
        List<dynamic> rawHourlyTimes = data['hourly']['time'];

        for (int i = currentHour; i < currentHour + 24; i++) {
          if (i < rawHourlyTemps.length) {
            _hourlyList.add({
              "time": rawHourlyTimes[i].toString().substring(11, 16),
              "temp": rawHourlyTemps[i].round().toString(),
              "code": rawHourlyCodes[i],
            });
          }
        }

        // 每日数据逻辑
        _dailyList.clear();
        for (int i = 0; i < 7; i++) {
           _dailyList.add({
             "date": WeatherUtils.formatDate(daily['time'][i]),
             "code": daily['weather_code'][i],
             "max": daily['temperature_2m_max'][i].round(),
             "min": daily['temperature_2m_min'][i].round(),
           });
        }
        _isLoading = false; // 加载完毕
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // === 核心逻辑 2: 搜索城市 ===
  Future<void> _doSearch() async {
    // 1. 获取输入框里的文字
    String input = _searchController.text.trim();
    if (input.isEmpty) return; // 如果没填东西，不处理

    // 收起键盘
    FocusScope.of(context).unfocus(); 

    setState(() => _isLoading = true); // 显示加载中

    try {
      // 2. 调用 Service 去搜坐标
      final result = await _weatherService.searchCity(input);

      if (result != null) {
        // 3. 如果搜到了，更新经纬度和城市名
        setState(() {
          _lat = result['latitude'];
          _lon = result['longitude'];
          _displayCityName = result['name']; // 获取 API 返回的标准地名
          _searchController.clear(); // 清空输入框
        });
        
        // 4. 用新坐标去查天气
        await _loadWeatherData();
        
      } else {
        // 没搜到
        setState(() {
          _isLoading = false;
          _errorMessage = "没找到这个城市，换个名字试试？";
        });
      }
    } catch (e) {
       setState(() {
          _isLoading = false;
          _errorMessage = "搜索出错: $e";
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 背景
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2E335A), Color(0xFF1C1B33)],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // --- 新增：搜索栏 ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: TextField(
                    controller: _searchController, // 绑定控制器
                    onSubmitted: (_) => _doSearch(), // 按下回车键时触发搜索
                    style: const TextStyle(color: Colors.white), // 输入文字颜色
                    decoration: InputDecoration( // 输入框样式
                      hintText: "输入城市名 (如: Shanghai)", // 提示文字
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54), // 左侧搜索图标
                      filled: true, // 填充背景
                      fillColor: Colors.white.withOpacity(0.1), // 半透明背景
                      border: OutlineInputBorder( // 圆角边框
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none, // 无边框线
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20), // 内容内边距
                    ),
                  ),
                ),

                // --- 原有的内容区域 ---
                // 使用 Expanded 让下面的内容占据剩余空间
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : _errorMessage.isNotEmpty 
                        ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
                        : RefreshIndicator(
                            onRefresh: _loadWeatherData,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                children: [
                                  const SizedBox(height: 20),
                                  // 显示城市名
                                  Text(_displayCityName, style: const TextStyle(fontSize: 32, color: Colors.white)),
                                  Text("$_currentTemp°", style: const TextStyle(fontSize: 90, color: Colors.white, fontWeight: FontWeight.w200)),
                                  Text(_weatherCondition, style: const TextStyle(fontSize: 20, color: Colors.white70)),
                                  Text("最高: $_highTemp°  最低: $_lowTemp°", style: const TextStyle(fontSize: 16, color: Colors.white)),
                                  
                                  const SizedBox(height: 40),

                                  // 小时卡片
                                  GlassCard(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("24小时预报", style: TextStyle(color: Colors.white54)),
                                        const Divider(color: Colors.white24),
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: _hourlyList.map((item) {
                                              return Padding(
                                                padding: const EdgeInsets.only(right: 20),
                                                child: Column(
                                                  children: [
                                                    Text(item['time'], style: const TextStyle(color: Colors.white)),
                                                    const SizedBox(height: 5),
                                                    Icon(WeatherUtils.getWeatherIcon(item['code']), color: Colors.white, size: 24),
                                                    const SizedBox(height: 5),
                                                    Text("${item['temp']}°", style: const TextStyle(color: Colors.white, fontSize: 18)),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // 每日预报卡片
                                  GlassCard(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("7日预报", style: TextStyle(color: Colors.white54)),
                                        const Divider(color: Colors.white24),
                                        ..._dailyList.map((item) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            child: Row(
                                              children: [
                                                SizedBox(width: 50, child: Text(item['date'], style: const TextStyle(color: Colors.white))),
                                                const Spacer(),
                                                Icon(WeatherUtils.getWeatherIcon(item['code']), color: Colors.white),
                                                const Spacer(),
                                                Text("${item['min']}°", style: const TextStyle(color: Colors.white54)),
                                                const SizedBox(width: 15),
                                                Text("${item['max']}°", style: const TextStyle(color: Colors.white)),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 50),
                                ],
                              ),
                            ),
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}