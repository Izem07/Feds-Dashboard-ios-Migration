import 'dart:convert';

import 'local_prefs_stub.dart' if (dart.library.html) 'local_prefs_web.dart';

/// Thin wrapper around browser localStorage for persisting config and data.
/// On non-web platforms all writes are no-ops and reads return null/empty.
class LocalPrefs {
  static const _kEventKey = 'scout_ops.eventKey';
  static const _kTableName = 'scout_ops.tableName';
  static const _kNeonConn = 'scout_ops.neonConn';
  static const _kTbaKey = 'scout_ops.tbaKey';
  static const _kCachedEvent = 'scout_ops.cachedEvent';
  static const _kCachedData = 'scout_ops.cachedData';
  static const _kLastUpdated = 'scout_ops.lastUpdated';

  // ── Config ──────────────────────────────────────────────────────────

  static void saveConfig({
    required String eventKey,
    required String tableName,
    required String neonConn,
    required String tbaKey,
  }) {
    try {
      final s = getLocalStorage();
      s[_kEventKey] = eventKey;
      s[_kTableName] = tableName;
      s[_kNeonConn] = neonConn;
      s[_kTbaKey] = tbaKey;
    } catch (_) {}
  }

  static ({
    String eventKey,
    String tableName,
    String neonConn,
    String tbaKey,
  })? resolveConfig() {
    try {
      final s = getLocalStorage();
      final neonConn = getQueryParam('neon') ?? s[_kNeonConn] ?? '';
      if (neonConn.isEmpty) return null;
      return (
        eventKey: getQueryParam('event') ?? s[_kEventKey] ?? '',
        tableName: getQueryParam('table') ?? s[_kTableName] ?? 'scouting_data',
        neonConn: neonConn,
        tbaKey: getQueryParam('tba') ?? s[_kTbaKey] ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  // ── Data cache ──────────────────────────────────────────────────────

  static void saveData({
    required String eventKey,
    required Map<int, List<Map<String, dynamic>>> scoutingByTeam,
    required List<String> scoutingColumns,
    required Map<int, double> oprByTeam,
    required Map<int, double> epaByTeam,
  }) {
    try {
      final s = getLocalStorage();
      s[_kCachedEvent] = eventKey;
      s[_kLastUpdated] = DateTime.now().toIso8601String();

      const dropCols = {'botimage1', 'botimage2', 'botimage3'};
      final teamData = scoutingByTeam.map(
        (k, v) => MapEntry(
          k.toString(),
          v
              .map((row) => Map.fromEntries(
                    row.entries.where((e) => !dropCols.contains(e.key)),
                  ))
              .toList(),
        ),
      );

      final encoded = json.encode({
        'scoutingByTeam': teamData,
        'scoutingColumns': scoutingColumns,
        'oprByTeam': oprByTeam.map((k, v) => MapEntry(k.toString(), v)),
        'epaByTeam': epaByTeam.map((k, v) => MapEntry(k.toString(), v)),
      });

      s[_kCachedData] = encoded;
    } catch (_) {}
  }

  static ({
    Map<int, List<Map<String, dynamic>>> scoutingByTeam,
    List<String> scoutingColumns,
    Map<int, double> oprByTeam,
    Map<int, double> epaByTeam,
  })? loadData(String eventKey) {
    try {
      final s = getLocalStorage();
      if (s[_kCachedEvent] != eventKey) return null;
      final raw = s[_kCachedData];
      if (raw == null || raw.isEmpty) return null;

      final decoded = json.decode(raw) as Map<String, dynamic>;
      final teamMap = (decoded['scoutingByTeam'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          int.parse(k),
          (v as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        ),
      );
      final columns =
          (decoded['scoutingColumns'] as List).cast<String>().toList();
      final opr = (decoded['oprByTeam'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(int.parse(k), (v as num).toDouble()));
      final epa = (decoded['epaByTeam'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(int.parse(k), (v as num).toDouble()));

      return (
        scoutingByTeam: teamMap,
        scoutingColumns: columns,
        oprByTeam: opr,
        epaByTeam: epa,
      );
    } catch (_) {
      return null;
    }
  }

  static DateTime? get lastUpdated {
    try {
      final raw = getLocalStorage()[_kLastUpdated];
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    } catch (_) {
      return null;
    }
  }

  static void clear() {
    try {
      final s = getLocalStorage();
      for (final k in [
        _kEventKey,
        _kTableName,
        _kNeonConn,
        _kTbaKey,
        _kCachedData,
        _kCachedEvent,
        _kLastUpdated,
      ]) {
        s.remove(k);
      }
    } catch (_) {}
  }
}
