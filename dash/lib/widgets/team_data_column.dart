import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../theme.dart';

class TeamDataColumn extends StatelessWidget {
  const TeamDataColumn({
    super.key,
    required this.teamNumber,
    required this.slotIndex,
  });

  final int teamNumber;
  final int slotIndex;

  static const _hideCols = {
    'pathdraw',
    'id',
    'created_at',
    'team',
    'eventkey',
    'botimage1',
    'botimage2',
    'botimage3',
  };

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<DataService>();
    final color = AppTheme.slotColors[slotIndex];
    final opr = svc.oprByTeam[teamNumber];
    final epa = svc.epaByTeam[teamNumber];
    final rows = svc.scoutingByTeam[teamNumber] ?? [];
    final row = rows.isNotEmpty ? rows.first : <String, dynamic>{};

    final displayEntries = row.entries
        .where((e) => !_hideCols.contains(e.key.toLowerCase()))
        .toList();

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Text('$teamNumber', style: AppTheme.mono(18, color: color)),
              ],
            ),
            const SizedBox(height: 14),

            // ── OPR / EPA ───────────────────────────────────────────
            Row(
              children: [
                _MetricBadge(label: 'OPR', value: opr, color: AppTheme.accent),
                const SizedBox(width: 10),
                _MetricBadge(label: 'EPA', value: epa, color: AppTheme.gold),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // ── Scouting fields ─────────────────────────────────────
            if (displayEntries.isEmpty)
              const Text('No scouting data',
                  style: TextStyle(color: AppTheme.muted, fontSize: 13))
            else
              ...displayEntries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(
                            _formatCol(e.key),
                            style: const TextStyle(
                                color: AppTheme.muted, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              _displayVal(e.value),
                              style: AppTheme.mono(13),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  static String _formatCol(String col) => col
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  static String _displayVal(dynamic v) {
    if (v == null) return '—';
    if (v is double) return v.toStringAsFixed(2);
    final str = v.toString();
    if (str.length > 30) return '${str.substring(0, 27)}…';
    return str;
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double? value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Text(label,
                style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
              value != null ? value!.toStringAsFixed(1) : '—',
              style: AppTheme.mono(15, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
