import 'package:flutter/material.dart';
import '../../core/sync/sync_service.dart';

class SyncStatusWidget extends StatelessWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SyncService(),
      builder: (context, _) {
        final sync = SyncService();
        final status = sync.status;
        final pending = sync.pendingCount;
        final lastTime = sync.lastSyncTime;

        Color color;
        IconData icon;
        String label;

        switch (status) {
          case SyncStatus.syncing:
            color = const Color(0xFFF59E0B);
            icon = Icons.sync;
            label = 'Senkronize ediliyor...';
            break;
          case SyncStatus.success:
            color = const Color(0xFF10B981);
            icon = Icons.cloud_done_outlined;
            label = 'Senkron';
            break;
          case SyncStatus.error:
            color = const Color(0xFFEF4444);
            icon = Icons.cloud_off_outlined;
            label = 'Sync hatası';
            break;
          default:
            color = const Color(0xFF64748B);
            icon = Icons.cloud_outlined;
            label = 'Beklemede';
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              status == SyncStatus.syncing
                  ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: color))
                  : Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                  if (pending > 0)
                    Text('$pending bekleyen', style: TextStyle(fontSize: 8, color: color.withValues(alpha: 0.7))),
                  if (lastTime != null)
                    Text('Son: ${lastTime.hour.toString().padLeft(2, '0')}:${lastTime.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 8, color: color.withValues(alpha: 0.7))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class DataBroadcastScreen extends StatefulWidget {
  const DataBroadcastScreen({super.key});

  @override
  State<DataBroadcastScreen> createState() => _DataBroadcastScreenState();
}

class _DataBroadcastScreenState extends State<DataBroadcastScreen> {
  final _sync = SyncService();
  bool _isSending = false;
  bool _isReceiving = false;
  bool _isSyncing = false;
  SyncResult? _lastResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Veri Gönder / Al', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 20),
            _buildActionSection('Merkez → Şube (Veri Al)', 'Master data indir: Ürünler, fiyatlar, kategoriler, kampanyalar', [
              _actionBtn('Ürünler & Fiyatlar', Icons.inventory_2, const Color(0xFF3B82F6), _receiveMasterData),
              _actionBtn('Kategoriler', Icons.category, const Color(0xFF8B5CF6), _receiveMasterData),
              _actionBtn('Kampanyalar', Icons.campaign, const Color(0xFFF59E0B), _receiveMasterData),
              _actionBtn('Tümünü Al', Icons.cloud_download, const Color(0xFF10B981), _receiveMasterData),
            ]),
            const SizedBox(height: 16),
            _buildActionSection('Şube → Merkez (Veri Gönder)', 'Satış ve kasa verilerini merkeze gönder', [
              _actionBtn('Satışlar', Icons.receipt_long, const Color(0xFF10B981), _sendSalesData),
              _actionBtn('Kasa Hareketleri', Icons.point_of_sale, const Color(0xFF7C3AED), _sendSalesData),
              _actionBtn('Stok Hareketleri', Icons.swap_vert, const Color(0xFFF97316), _sendSalesData),
              _actionBtn('Tümünü Gönder', Icons.cloud_upload, const Color(0xFF2563EB), _sendSalesData),
            ]),
            const SizedBox(height: 16),
            _buildSyncSection(),
            if (_lastResult != null) ...[
              const SizedBox(height: 16),
              _buildResultCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return ListenableBuilder(
      listenable: _sync,
      builder: (context, _) {
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E40AF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.sync, color: Color(0xFF1E40AF), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Senkronizasyon Durumu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      Text('Bekleyen: ${_sync.pendingCount} kayıt', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      if (_sync.lastSyncTime != null)
                        Text('Son sync: ${_sync.lastSyncTime!.hour.toString().padLeft(2, '0')}:${_sync.lastSyncTime!.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
                const SyncStatusWidget(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionSection(String title, String desc, List<Widget> actions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: actions),
      ],
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, Future<void> Function() onTap) {
    return InkWell(
      onTap: (_isSending || _isReceiving) ? null : () async {
        await onTap();
      },
      child: Container(
        width: 140, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF1E40AF),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.sync, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tam Senkronizasyon', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  Text('Tüm verileri gönder ve al', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _isSyncing ? null : _fullSync,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF1E40AF)),
              child: _isSyncing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Şimdi Senkronize Et', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final r = _lastResult!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: r.errors > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(r.errors > 0 ? Icons.warning_amber : Icons.check_circle,
                color: r.errors > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Gönderilen: ${r.sent} | Alınan: ${r.received} | Hata: ${r.errors}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _receiveMasterData() async {
    setState(() => _isReceiving = true);
    final result = await _sync.sendMasterData();
    setState(() { _isReceiving = false; _lastResult = result; });
  }

  Future<void> _sendSalesData() async {
    setState(() => _isSending = true);
    final result = await _sync.receiveSalesData();
    setState(() { _isSending = false; _lastResult = result; });
  }

  Future<void> _fullSync() async {
    setState(() => _isSyncing = true);
    final result = await _sync.syncNow();
    setState(() { _isSyncing = false; _lastResult = result; });
  }
}
