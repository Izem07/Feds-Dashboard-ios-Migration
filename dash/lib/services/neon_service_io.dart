// Native platform stub — actual implementation is in NeonService._queryHttp
Future<List<Map<String, dynamic>>> queryWeb(
    String connectionString, String sql, List<dynamic> params) async {
  throw UnsupportedError('queryWeb is not available on native platforms');
}
