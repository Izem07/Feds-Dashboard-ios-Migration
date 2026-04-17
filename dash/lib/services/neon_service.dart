import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

// Web-only JS interop — only imported on web builds
import 'neon_service_web.dart' if (dart.library.io) 'neon_service_io.dart'
    as platform;

/// Queries a Neon PostgreSQL database.
///
/// On web: calls the `@neondatabase/serverless` JS driver loaded in index.html.
/// On iOS/native: uses Neon's HTTP API directly.
class NeonService {
  NeonService(this.connectionString);
  final String connectionString;

  Future<List<Map<String, dynamic>>> query(String sql,
      [List<dynamic> params = const []]) async {
    if (kIsWeb) {
      return platform.queryWeb(connectionString, sql, params);
    } else {
      return _queryHttp(sql, params);
    }
  }

  Future<List<Map<String, dynamic>>> _queryHttp(
      String sql, List<dynamic> params) async {
    final uri = Uri.parse(connectionString);
    final host = uri.host;
    final endpoint = Uri.https(host, '/sql');

    final response = await http.post(
      endpoint,
      headers: {
        'Content-Type': 'application/json',
        'Neon-Connection-String': connectionString,
      },
      body: jsonEncode({'query': sql, 'params': params}),
    );

    if (response.statusCode != 200) {
      throw NeonException('HTTP ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (decoded.containsKey('error')) {
      throw NeonException(decoded['error'] as String);
    }

    final fields = (decoded['fields'] as List<dynamic>?)
            ?.map((f) => (f as Map)['name'].toString())
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

  Future<List<Map<String, dynamic>>> fetchAll(String table) async {
    return query('SELECT * FROM "$table"');
  }

  Future<List<String>> columns(String table) async {
    final rows = await query(
      "SELECT column_name FROM information_schema.columns "
      "WHERE table_name = \$1 ORDER BY ordinal_position",
      [table],
    );
    return rows.map((r) => r['column_name'] as String).toList();
  }
}

class NeonException implements Exception {
  final String message;
  NeonException(this.message);
  @override
  String toString() => 'NeonException: $message';
}
