import 'dart:convert';
import 'dart:js_interop';

Future<List<Map<String, dynamic>>> queryWeb(
    String connectionString, String sql, List<dynamic> params) async {
  final paramsJson = jsonEncode(params);

  final promise = _neonQuery(
    connectionString.toJS,
    sql.toJS,
    paramsJson.toJS,
  );

  final JSString jsResult = await promise.toDart as JSString;
  final resultStr = jsResult.toDart;
  final decoded = jsonDecode(resultStr) as Map<String, dynamic>;

  if (decoded.containsKey('error')) {
    throw Exception(decoded['error'] as String);
  }

  final fields = (decoded['fields'] as List<dynamic>?)
          ?.map((f) => f.toString())
          .toList() ??
      [];
  final rows = decoded['rows'] as List<dynamic>? ?? [];

  if (fields.isEmpty) return [];

  return rows.map<Map<String, dynamic>>((row) {
    final map = <String, dynamic>{};
    if (row is List) {
      for (int i = 0; i < fields.length && i < row.length; i++) {
        map[fields[i]] = row[i];
      }
    } else if (row is Map) {
      for (final col in fields) {
        map[col] = row[col];
      }
    }
    return map;
  }).toList();
}

@JS('neonQuery')
external JSPromise _neonQuery(
    JSString connString, JSString sql, JSString paramsJson);
