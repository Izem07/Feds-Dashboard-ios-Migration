// ignore: avoid_web_libraries_in_flutter
import 'dart:html' show window;

Map<String, String> getLocalStorage() => window.localStorage;
String? getQueryParam(String key) => Uri.base.queryParameters[key];
