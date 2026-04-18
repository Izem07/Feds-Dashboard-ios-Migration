import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bot_path_drawer/bot_path_drawer.dart';
import '../models/auto_path_data.dart';
import '../services/data_service.dart';
import '../services/local_prefs.dart';
import '../theme.dart';
import '../widgets/team_data_column.dart';

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen>
    with SingleTickerProviderStateMixin {
  final List<int?> _selectedTeams = [null, null, null];
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final svc = context.read<DataService>();
      if (svc.dataSource == 'cache') _refresh();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final svc = context.read<DataService>();
    await svc.fetchAll();
    if (mounted && svc.scoutingByTeam.isNotEmpty) {
      LocalPrefs.saveData(
        eventKey: svc.eventKey,
        scoutingByTeam: svc.scoutingByTeam,
        scoutingColumns: svc.scoutingColumns,
        oprByTeam: svc.oprByTeam,
        epaByTeam: svc.epaByTeam,
      );
    }
  }

  void _pickTeam(int slot) {
    final svc = context.read<DataService>();
    final teams = svc.teamNumbers;
    if (teams.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _TeamPickerSheet(
        teams: teams,
        selected: _selectedTeams[slot],
        slotIndex: slot,
        onPicked: (t) {
          setState(() => _selectedTeams[slot] = t);
          Navigator.pop(context);
        },
        onCleared: () {
          setState(() => _selectedTeams[slot] = null);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _pickMatch() {
    final svc = context.read<DataService>();
    if (svc.matchEntries.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _MatchPickerSheet(
        entries: svc.matchEntries,
        onPicked: (teams) {
          setState(() {
            for (int i = 0; i < 3 && i < teams.length; i++) {
              _selectedTeams[i] = teams[i];
            }
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Map<String, TeamPaths> _buildTeamsMap(DataService svc) {
    final map = <String, TeamPaths>{};
    for (int i = 0; i < 3; i++) {
      final team = _selectedTeams[i];
      if (team == null) continue;
      final rows = svc.scoutingByTeam[team];
      if (rows == null || rows.isEmpty) continue;
      final routes = parsePathDraw(rows.first['pathdraw']);
      if (routes.isEmpty) continue;
      final pathsMap = <String, String>{};
      for (int j = 0; j < routes.length; j++) {
        var key = routes[j].displayName(j);
        if (pathsMap.containsKey(key)) key = '$key (${j + 1})';
        pathsMap[key] = routes[j].pathData;
      }
      map['$team'] = TeamPaths(paths: pathsMap, color: AppTheme.slotColors[i]);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<DataService>();
    final teamsMap = _buildTeamsMap(svc);
    final filledSlots = _selectedTeams.where((t) => t != null).length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            _AppBar(
              svc: svc,
              onRefresh: _refresh,
              onSettings: () => Navigator.of(context)
                  .pushReplacementNamed('/', arguments: {'autoLoad': false}),
            ),
            if (svc.error != null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: AppTheme.red.withValues(alpha: 0.10),
                child: Text(svc.error!,
                    style: const TextStyle(color: AppTheme.red, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),

            // ── Team selector row ──────────────────────────────────
            _TeamSelectorRow(
              selectedTeams: _selectedTeams,
              onTap: _pickTeam,
              onMatchTap: svc.matchEntries.isNotEmpty ? _pickMatch : null,
            ),

            // ── Tab bar ────────────────────────────────────────────
            Container(
              color: AppTheme.surface,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.accent,
                indicatorWeight: 2,
                labelStyle: AppTheme.mono(11),
                unselectedLabelStyle: AppTheme.mono(11),
                labelColor: AppTheme.accent,
                unselectedLabelColor: AppTheme.muted,
                tabs: [
                  const Tab(text: 'Field'),
                  Tab(
                      text: _selectedTeams[0] != null
                          ? '${_selectedTeams[0]}'
                          : 'T1'),
                  Tab(
                      text: _selectedTeams[1] != null
                          ? '${_selectedTeams[1]}'
                          : 'T2'),
                  Tab(
                      text: _selectedTeams[2] != null
                          ? '${_selectedTeams[2]}'
                          : 'T3'),
                ],
              ),
            ),

            // ── Tab content ────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Field tab
                  filledSlots == 0
                      ? const _EmptyState()
                      : _FieldTab(
                          teamsMap: teamsMap,
                          selectedTeams: _selectedTeams,
                        ),
                  // Team tabs
                  for (int i = 0; i < 3; i++)
                    _selectedTeams[i] == null
                        ? _EmptyTeamTab(slot: i, onTap: () => _pickTeam(i))
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(12),
                            child: TeamDataColumn(
                              teamNumber: _selectedTeams[i]!,
                              slotIndex: i,
                            ),
                          ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// App Bar
// ─────────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.svc,
    required this.onRefresh,
    required this.onSettings,
  });

  final DataService svc;
  final VoidCallback onRefresh;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.settings_rounded,
                    size: 20, color: AppTheme.muted),
                onPressed: onSettings,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              const Icon(Icons.radar_rounded, color: AppTheme.accent, size: 18),
              const SizedBox(width: 6),
              Text('Scout-Ops', style: AppTheme.mono(14, color: AppTheme.text)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(svc.eventKey,
                    style: AppTheme.mono(10, color: AppTheme.accent)),
              ),
              const Spacer(),
              if (svc.loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.accent),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      size: 20, color: AppTheme.accent),
                  onPressed: onRefresh,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Team selector row
// ─────────────────────────────────────────────────────────────────────

class _TeamSelectorRow extends StatelessWidget {
  const _TeamSelectorRow({
    required this.selectedTeams,
    required this.onTap,
    required this.onMatchTap,
  });

  final List<int?> selectedTeams;
  final void Function(int slot) onTap;
  final VoidCallback? onMatchTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: [
          // Match picker button
          GestureDetector(
            onTap: onMatchTap,
            child: Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: AppTheme.surfaceHi,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: onMatchTap != null
                      ? AppTheme.gold.withValues(alpha: 0.4)
                      : AppTheme.border,
                ),
              ),
              child: Icon(Icons.list_alt_rounded,
                  size: 16,
                  color: onMatchTap != null ? AppTheme.gold : AppTheme.muted),
            ),
          ),
          const SizedBox(width: 6),
          // 3 team slots
          for (int i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: _TeamChip(
                slotIndex: i,
                team: selectedTeams[i],
                onTap: () => onTap(i),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TeamChip extends StatelessWidget {
  const _TeamChip({
    required this.slotIndex,
    required this.team,
    required this.onTap,
  });

  final int slotIndex;
  final int? team;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.slotColors[slotIndex];
    final filled = team != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: filled ? color.withValues(alpha: 0.10) : AppTheme.surfaceHi,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: filled ? color.withValues(alpha: 0.4) : AppTheme.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: filled ? color : AppTheme.muted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              filled ? '$team' : 'T${slotIndex + 1}',
              style: AppTheme.mono(12, color: filled ? color : AppTheme.muted),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Field tab
// ─────────────────────────────────────────────────────────────────────

class _FieldTab extends StatelessWidget {
  const _FieldTab({
    required this.teamsMap,
    required this.selectedTeams,
  });

  final Map<String, TeamPaths> teamsMap;
  final List<int?> selectedTeams;

  @override
  Widget build(BuildContext context) {
    final config = BotPathConfig(
      backgroundImage: const AssetImage('assets/Aerna2026.png'),
      brightness: Brightness.dark,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Field viewer
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: teamsMap.isEmpty
                  ? const Center(
                      child: Text('No path data for selected teams',
                          style:
                              TextStyle(color: AppTheme.muted, fontSize: 12)),
                    )
                  : BotPathViewerWithSelector(
                      config: config,
                      teams: teamsMap,
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Legend
          Row(
            children: [
              for (int i = 0; i < 3; i++)
                if (selectedTeams[i] != null) ...[
                  if (i > 0) const SizedBox(width: 12),
                  _LegendDot(
                      team: selectedTeams[i]!, color: AppTheme.slotColors[i]),
                ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.team, required this.color});
  final int team;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('$team', style: AppTheme.mono(11, color: color)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Empty states
// ─────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.compare_arrows_rounded,
              size: 40, color: AppTheme.muted.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('Select teams to compare',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: AppTheme.muted)),
          const SizedBox(height: 4),
          Text('Tap the team chips above',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _EmptyTeamTab extends StatelessWidget {
  const _EmptyTeamTab({required this.slot, required this.onTap});
  final int slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.slotColors[slot];
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_add_rounded,
              size: 36, color: color.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('No team selected',
              style: AppTheme.mono(13, color: AppTheme.muted)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onTap,
            style: FilledButton.styleFrom(backgroundColor: color),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text('Pick Team ${slot + 1}',
                style: AppTheme.mono(12, color: AppTheme.bg)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Bottom sheet pickers
// ─────────────────────────────────────────────────────────────────────

class _TeamPickerSheet extends StatefulWidget {
  const _TeamPickerSheet({
    required this.teams,
    required this.selected,
    required this.slotIndex,
    required this.onPicked,
    required this.onCleared,
  });

  final List<int> teams;
  final int? selected;
  final int slotIndex;
  final void Function(int) onPicked;
  final VoidCallback onCleared;

  @override
  State<_TeamPickerSheet> createState() => _TeamPickerSheetState();
}

class _TeamPickerSheetState extends State<_TeamPickerSheet> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.slotColors[widget.slotIndex];
    final filtered = _filter.isEmpty
        ? widget.teams
        : widget.teams.where((t) => t.toString().contains(_filter)).toList();

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('Team ${widget.slotIndex + 1}',
                    style: AppTheme.mono(14, color: color)),
                const Spacer(),
                if (widget.selected != null)
                  TextButton(
                    onPressed: widget.onCleared,
                    child: Text('Clear',
                        style: AppTheme.mono(12, color: AppTheme.muted)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: true,
              keyboardType: TextInputType.number,
              style: AppTheme.mono(13),
              decoration: InputDecoration(
                hintText: 'Search team number…',
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: AppTheme.muted),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
          ),
          const SizedBox(height: 8),

          // List
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.35,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final t = filtered[i];
                final isSelected = t == widget.selected;
                return ListTile(
                  dense: true,
                  leading: isSelected
                      ? Icon(Icons.check_rounded, size: 16, color: color)
                      : const SizedBox(width: 16),
                  title: Text('$t', style: AppTheme.mono(13)),
                  tileColor: isSelected ? color.withValues(alpha: 0.08) : null,
                  onTap: () => widget.onPicked(t),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _MatchPickerSheet extends StatelessWidget {
  const _MatchPickerSheet({
    required this.entries,
    required this.onPicked,
  });

  final List entries;
  final void Function(List<int>) onPicked;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.list_alt_rounded,
                  size: 16, color: AppTheme.gold),
              const SizedBox(width: 8),
              Text('Pick a Match',
                  style: AppTheme.mono(14, color: AppTheme.gold)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.45,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: entries.length,
            itemBuilder: (_, i) {
              final e = entries[i];
              final isRed = e.alliance == 'red';
              return ListTile(
                dense: true,
                leading: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isRed ? AppTheme.red : const Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(e.label, style: AppTheme.mono(12)),
                onTap: () => onPicked(e.teamNumbers),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
