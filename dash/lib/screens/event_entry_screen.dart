import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/csv_picker_stub.dart'
    if (dart.library.html) '../services/csv_picker_web.dart';
import '../services/data_service.dart';
import '../services/local_prefs.dart';
import '../theme.dart';

class EventEntryScreen extends StatefulWidget {
  const EventEntryScreen({super.key, this.autoLoad = true});

  final bool autoLoad;

  @override
  State<EventEntryScreen> createState() => _EventEntryScreenState();
}

class _EventEntryScreenState extends State<EventEntryScreen>
    with SingleTickerProviderStateMixin {
  final _eventKeyCtl = TextEditingController(text: '2026micmp2');
  final _tableCtl = TextEditingController(text: 'states_data');
  final _neonCtl = TextEditingController(
      text:
          'postgresql://authenticator:npg_6PXzbmwu1FxY@ep-weathered-base-a5ilny8n-pooler.us-east-2.aws.neon.tech/data?sslmode=require&channel_binding=require');
  final _tbaCtl = TextEditingController(
      text: 'jLPUK4x0CTRqUx2l1TmYFFIDrl6MOxB0Cpf3YXXWfFXvCr7oxrosv5ZL5L2KEdx3');
  final _formKey = GlobalKey<FormState>();

  String? _csvFileName;
  String? _csvContent;

  late final AnimationController _fadeCtl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtl, curve: Curves.easeOut);
    _fadeCtl.forward();
    _restoreFromStorage();
    if (widget.autoLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryAutoLoad());
    }
  }

  void _restoreFromStorage() {
    final saved = LocalPrefs.resolveConfig();
    if (saved == null) return;
    if (saved.eventKey.isNotEmpty) _eventKeyCtl.text = saved.eventKey;
    if (saved.tableName.isNotEmpty) _tableCtl.text = saved.tableName;
    if (saved.neonConn.isNotEmpty) _neonCtl.text = saved.neonConn;
    if (saved.tbaKey.isNotEmpty) _tbaCtl.text = saved.tbaKey;
  }

  Future<void> _tryAutoLoad() async {
    if (_neonCtl.text.trim().isEmpty) return;
    if (_tableCtl.text.trim().isEmpty) return;
    await _loadNeon();
  }

  @override
  void dispose() {
    _fadeCtl.dispose();
    _eventKeyCtl.dispose();
    _tableCtl.dispose();
    _neonCtl.dispose();
    _tbaCtl.dispose();
    super.dispose();
  }

  void _pickCsv() {
    pickCsvFile((name, content) {
      setState(() {
        _csvFileName = name;
        _csvContent = content;
      });
    });
  }

  void _configureSvc(DataService svc) {
    svc.configure(
      eventKey: _eventKeyCtl.text.trim(),
      tableName: _tableCtl.text.trim(),
      neonConnString: _neonCtl.text.trim(),
      tbaApiKey: _tbaCtl.text.trim(),
    );
  }

  Future<void> _loadCsv() async {
    if (_csvContent == null) return;
    final svc = context.read<DataService>();
    _configureSvc(svc);
    svc.loadFromCsv(_csvContent!);
    await svc.fetchExternalOnly();
    if (!mounted) return;
    if (svc.scoutingByTeam.isEmpty) {
      _showError('No teams found in CSV');
    } else {
      _saveConfig();
      Navigator.of(context).pushReplacementNamed('/compare');
    }
  }

  Future<void> _loadNeon() async {
    if (_neonCtl.text.trim().isEmpty) {
      _showError('Enter a Neon connection string');
      return;
    }
    if (_tableCtl.text.trim().isEmpty) {
      _showError('Enter a table name');
      return;
    }
    final svc = context.read<DataService>();
    _configureSvc(svc);
    await svc.fetchAll();
    if (!mounted) return;
    if (svc.error != null && svc.scoutingByTeam.isEmpty) {
      _showError(svc.error!);
    } else {
      _saveConfig();
      LocalPrefs.saveData(
        eventKey: _eventKeyCtl.text.trim(),
        scoutingByTeam: svc.scoutingByTeam,
        scoutingColumns: svc.scoutingColumns,
        oprByTeam: svc.oprByTeam,
        epaByTeam: svc.epaByTeam,
      );
      Navigator.of(context).pushReplacementNamed('/compare');
    }
  }

  void _saveConfig() {
    LocalPrefs.saveConfig(
      eventKey: _eventKeyCtl.text.trim(),
      tableName: _tableCtl.text.trim(),
      neonConn: _neonCtl.text.trim(),
      tbaKey: _tbaCtl.text.trim(),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 5,
            overflow: TextOverflow.ellipsis),
        backgroundColor: AppTheme.red.withValues(alpha: 0.9),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
            label: 'DISMISS', textColor: Colors.white, onPressed: () {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select<DataService, bool>((s) => s.loading);

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Logo ────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.radar_rounded,
                            color: AppTheme.accent, size: 30),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Scout-Ops Dash',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall!
                                  .copyWith(color: AppTheme.text)),
                          Text('FRC 201 · The Feds',
                              style: AppTheme.mono(12, color: AppTheme.muted)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // ── Shared fields ──────────────────────────────────
                  _field(_eventKeyCtl, 'Event Key', '2026miket',
                      Icons.event_rounded),
                  const SizedBox(height: 14),
                  _field(_tbaCtl, 'TBA API Key', 'X-TBA-Auth-Key',
                      Icons.vpn_key_rounded,
                      obscure: true),
                  const SizedBox(height: 28),

                  // ── Divider ────────────────────────────────────────
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text('Load scouting data from',
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 20),

                  // ── CSV (web only) ─────────────────────────────────
                  if (kIsWeb) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(children: [
                              const Icon(Icons.upload_file_rounded,
                                  size: 20, color: AppTheme.accent),
                              const SizedBox(width: 10),
                              Text('CSV File',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                            ]),
                            const SizedBox(height: 14),
                            Row(children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceHi,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: Text(
                                    _csvFileName ?? 'No file selected',
                                    style: TextStyle(
                                      color: _csvFileName != null
                                          ? AppTheme.text
                                          : AppTheme.muted,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                onPressed: _pickCsv,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(80, 52),
                                  side: BorderSide(
                                      color: AppTheme.accent
                                          .withValues(alpha: 0.4)),
                                ),
                                child: const Text('Browse',
                                    style: TextStyle(
                                        color: AppTheme.accent, fontSize: 14)),
                              ),
                            ]),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              onPressed: (loading || _csvContent == null)
                                  ? null
                                  : _loadCsv,
                              icon: loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: AppTheme.bg))
                                  : const Icon(Icons.upload_rounded, size: 20),
                              label: const Text('Load CSV'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Neon Database ──────────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(children: [
                            const Icon(Icons.storage_rounded,
                                size: 20, color: AppTheme.gold),
                            const SizedBox(width: 10),
                            Text('Neon Database',
                                style: Theme.of(context).textTheme.titleMedium),
                          ]),
                          const SizedBox(height: 14),
                          _field(
                              _neonCtl,
                              'Connection String',
                              'postgresql://user:pass@host/db',
                              Icons.link_rounded,
                              obscure: true),
                          const SizedBox(height: 14),
                          _field(_tableCtl, 'Table Name', 'scouting_data',
                              Icons.table_chart_rounded),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: loading ? null : _loadNeon,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.gold),
                            icon: loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: AppTheme.bg))
                                : const Icon(Icons.cloud_download_rounded,
                                    size: 20),
                            label: const Text('Load from Neon'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
      TextEditingController ctl, String label, String hint, IconData icon,
      {bool obscure = false}) {
    return TextFormField(
      controller: ctl,
      obscureText: obscure,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 22, color: AppTheme.muted),
      ),
    );
  }
}
