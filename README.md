# [实战] 我用 Flutter 在 Android 上复刻了 iPhone 天气 App：从零到一的完整复盘



## \## 项目演示

![动画](C:\Users\28254\Desktop\苹果式安卓天气app\动画.gif)

> **摘要**：本文记录了我使用 Flutter 开发一款高仿 iOS 风格天气 App 的全过程。涵盖了从 UI 还原（毛玻璃、细字体）、Open-Meteo 免费接口对接、到城市搜索逻辑实现的完整技术链路。同时也复盘了在异步编程、状态管理和项目架构上遇到的坑与解决方案。

------



##  一、 前言：为什么选择这个项目？



作为一个移动端开发学习者，我一直对 iOS 原生天气 App 那种沉浸式的体验、动态的渐变背景以及细腻的毛玻璃效果印象深刻。

既然 Flutter 号称“Pixel Perfect（像素级完美）”且能一套代码运行在 Android 和 iOS 上，我决定发起一个挑战：**在 Android 手机上，用 Flutter 完美复刻 iPhone 的天气体验。**

这不仅仅是一个 UI 练习，更是一次涵盖网络请求、JSON 解析、异步状态管理和代码重构的综合实战。

------



##  二、 项目架构：拒绝“面条代码”



在项目初期，我像很多新手一样，把所有代码都写在了 `main.dart` 里。随着功能增加，代码迅速膨胀到几百行，找一个变量都要翻半天。

为了模拟真实的工程开发，我对项目进行了**模块化重构**，采用了经典的 **MVC 分层思想**：

Plaintext

```dart
lib/
├── main.dart                  # [入口] 程序的启动点，负责配置主题和路由
├── pages/                     # [表现层] 负责页面展示和用户交互
│   └── weather_page.dart      # 天气主页
├── services/                  # [数据层] 负责与 API 通讯
│   └── weather_service.dart   # 网络请求封装
├── utils/                     # [工具层] 纯逻辑函数
│   └── weather_utils.dart     # 天气代码转中文、日期格式化
└── widgets/                   # [组件层] 可复用的 UI 零件
    └── glass_card.dart        # 封装“毛玻璃”
```

**💡 架构思考：** 我们将 UI（Pages）和数据（Services）分离。这就好比餐厅里，厨师（Service）只管做菜，服务员（Page）只管端菜，大家各司其职，改 Bug 时互不干扰。

------



## 🎨三、 核心 UI 实现：如何还原“果味”？



iOS 风格的核心在于：**沉浸感**与**通透感**。



### 1. 沉浸式渐变背景



为了摆脱 Android 默认的白色或灰色背景，我使用了 `Stack` 组件作为底层布局，并放置了一个全屏的 `Container`：

Dart

```dart
Container(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF2E335A), Color(0xFF1C1B33)], // 深靛蓝 -> 黑蓝
    ),
  ),
)
```



### 2. 毛玻璃效果 (Glassmorphism)



这是最关键的一步。在 Flutter 中实现半透明磨砂效果其实很简单，核心是颜色透明度与细边框的配合：

Dart

```
// lib/widgets/glass_card.dart
Container(
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.1), // 10% 透明度的白色
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white30, width: 0.5), // 极细的半透明边框
  ),
  child: ...
)
```



### 3. 极细字体



iOS 天气那个巨大的温度数字，秘诀在于 `fontWeight`：

Dart

```
Text(
  "19°", 
  style: TextStyle(
    fontSize: 90, 
    fontWeight: FontWeight.w200, // Thin 字体
    color: Colors.white
  )
)
```

------



## 四、 数据对接：Open-Meteo 与异步逻辑



本项目抛弃了需要繁琐注册 Key 的 API，选择了 **Open-Meteo**。它完全免费、无需 API Key，且支持中文。



### 1. 两步走搜索逻辑



难点在于：天气接口只接受**经纬度**，但用户输入的是**城市名**。 所以我实现了一个“链式调用”：

1. **Geocoding API**: 用户输入 "Beijing" -> 返回 `{lat: 39.9, lon: 116.4}`。
2. **Weather API**: 使用 `{lat, lon}` -> 获取温度、天气代码。



### 2. Service 层代码片段



Dart

```
// lib/services/weather_service.dart
Future<Map<String, dynamic>?> searchCity(String cityName) async {
  final url = "$_geoBaseUrl?name=$cityName&count=1&language=zh&format=json";
  final response = await http.get(Uri.parse(url));
  // ...解析 JSON 返回第一个结果...
}
```

------



## 五、 踩坑复盘：新手最容易犯的错



在开发过程中，我遇到了几个典型的“小白坑”，这里记录下来，希望大家能避雷。



### 坑点 1：异步加载导致的红屏报错



**现象**：刚启动 App 或搜索时，屏幕直接变红，提示 `RangeError` 或 `Null check operator used on a null value`。 **原因**：网络请求是异步的（需要时间），在数据还没回来时，UI 已经尝试去渲染变量（此时变量可能为空或列表长度为 0）。 **解决**：引入 `_isLoading` 状态标志位。

Dart

```
// build 方法中
child: _isLoading 
  ? CircularProgressIndicator() // 数据没来，转圈圈
  : Column(...)                 // 数据来了，显示内容
```



### 坑点 2：类型转换崩溃



**现象**：API 返回的温度有时是 `20` (int)，有时是 `20.5` (double)。如果强行用 `int` 接收 `20.5`，App 会崩溃。 **解决**：前端展示不追求小数点后几位，统一先四舍五入转字符串：

Dart

```
// 稳健的写法
String temp = json['current']['temperature_2m'].round().toString();
```



###  坑点 3：上下文 Context 传递问题



**现象**：在拆分文件后，想在 `weather_utils.dart` 里弹出一个提示框，却发现找不到 `context`。 **理解**：`Utils` 和 `Service` 类通常应该是纯逻辑的，不应该包含 UI 代码（如弹窗）。如果报错，应该通过 `throw Exception` 抛出，让 UI 层（Page）去捕获并决定如何提示用户。

------



## 六、 总结与展望



通过这个项目，我不仅学会了 `Stack`、`Column` 等基础布局，更深刻理解了 **“状态 (State)”** 在 Flutter 中的核心地位——**UI 只是数据的函数**，数据变了，UI 自然就变了。

**接下来的优化方向：**

1. **定位功能**：引入 `geolocator` 库，自动获取当前位置天气。
2. **状态管理升级**：目前的 `setState` 适合小项目，未来计划重构为 **Provider** 或 **Bloc** 模式，让代码更清晰。

如果你也想学习 Flutter，不妨从模仿这个天气 App 开始，它涵盖了几乎所有移动开发的基础知识点！