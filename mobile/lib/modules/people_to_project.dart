import 'package:flutter/material.dart';
import '../api.dart';

// Modul People-to-Project (Faishal). Feed rekomendasi (UC06) + detail (UC07) + daftar (UC08).

// Warna badge mengikuti TA (hijau >=85, kuning 60-84, abu 30-59).
Color badgeColor(String badge) {
  switch (badge) {
    case 'hijau':
      return const Color(0xFF16A34A);
    case 'kuning':
      return const Color(0xFFD97706);
    default:
      return const Color(0xFF6B7280);
  }
}

class PeopleToProjectPage extends StatefulWidget {
  const PeopleToProjectPage({super.key});

  @override
  State<PeopleToProjectPage> createState() => _PeopleToProjectPageState();
}

class _PeopleToProjectPageState extends State<PeopleToProjectPage> {
  List<dynamic> _feed = [];
  bool _loading = false;
  String? _pesan;

  @override
  void initState() {
    super.initState();
    _muatFeed();
  }

  Future<void> _muatFeed() async {
    if (authToken == null) {
      setState(() => _pesan = 'Silakan login terlebih dahulu.');
      return;
    }
    setState(() {
      _loading = true;
      _pesan = null;
    });
    try {
      final res = await apiGet('/people-to-project/feed');
      final feed = (res is Map && res['feed'] is List) ? res['feed'] as List : [];
      setState(() {
        _feed = feed;
        if (feed.isEmpty) {
          _pesan = (res is Map ? res['error']?.toString() : null) ?? 'Belum ada kegiatan yang sesuai.';
        }
      });
    } catch (e) {
      setState(() => _pesan = 'Gagal memuat feed. Pastikan backend jalan.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekomendasi Kegiatan'),
        actions: [IconButton(onPressed: _muatFeed, icon: const Icon(Icons.refresh))],
      ),
      body: RefreshIndicator(
        onRefresh: _muatFeed,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _feed.isEmpty
                ? ListView(children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 120, left: 32, right: 32),
                      child: Column(children: [
                        Icon(Icons.search_off, size: 56, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 12),
                        Text(_pesan ?? 'Belum ada rekomendasi.', textAlign: TextAlign.center),
                      ]),
                    )
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _feed.length,
                    itemBuilder: (_, i) => _FeedCard(item: _feed[i] as Map),
                  ),
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final Map item;
  const _FeedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = badgeColor(item['badge']?.toString() ?? '');
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => DetailProjectPage(projectId: item['projectId'].toString()),
        )),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Icon(Icons.work_outline, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['judul']?.toString() ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    if ((item['kategori']?.toString() ?? '').isNotEmpty)
                      Text(item['kategori'].toString(), style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${item['skorPersen']}% cocok',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// UC07 Detail kegiatan + breakdown skor + daftar role (UC08)
class DetailProjectPage extends StatefulWidget {
  final String projectId;
  const DetailProjectPage({super.key, required this.projectId});

  @override
  State<DetailProjectPage> createState() => _DetailProjectPageState();
}

class _DetailProjectPageState extends State<DetailProjectPage> {
  Map<String, dynamic>? _project;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    final res = await apiGet('/people-to-project/projects/${widget.projectId}');
    setState(() {
      _project = res is Map ? Map<String, dynamic>.from(res) : null;
      _loading = false;
    });
  }

  Future<void> _daftar(String roleId) async {
    final res = await apiPost('/people-to-project/projects/${widget.projectId}/daftar', {'roleId': roleId});
    if (!mounted) return;
    final pesan = res is Map && res['error'] != null
        ? res['error'].toString()
        : 'Pendaftaran berhasil diajukan (menunggu konfirmasi).';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
    _muat();
  }

  final _labelAtribut = const {
    'skill': 'Keterampilan',
    'pengalaman': 'Pengalaman',
    'minat': 'Minat',
    'gayaKerja': 'Gaya kerja',
    'peran': 'Peran',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final p = _project;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Project tidak ditemukan')),
      );
    }
    final affinity = p['affinity'] as Map?;
    final breakdown = affinity?['breakdown'] as Map?;
    final roles = (p['roles'] as List?) ?? [];
    final kuotaPenuh = p['kuotaPenuh'] == true;
    final color = badgeColor(affinity?['badge']?.toString() ?? '');

    return Scaffold(
      appBar: AppBar(title: Text(p['judul']?.toString() ?? 'Detail')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header skor
          if (affinity != null)
            Card(
              color: color.withOpacity(0.08),
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Skor kecocokan', style: TextStyle(color: cs.onSurfaceVariant)),
                        Text('${affinity['skorPersen']}%',
                            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: color)),
                      ],
                    ),
                    const Spacer(),
                    Icon(Icons.verified, color: color, size: 40),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(p['deskripsi']?.toString() ?? '', style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 20),

          // Breakdown per atribut
          if (breakdown != null) ...[
            const Text('Rincian kecocokan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...breakdown.entries.map((e) {
              final skor = ((e.value as Map)['skor'] as num).toDouble();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_labelAtribut[e.key] ?? e.key),
                        Text('${(skor * 100).round()}%',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(value: skor, minHeight: 8),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
          ],

          // Role
          const Text('Role dibutuhkan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          ...roles.map((r) {
            final role = r as Map;
            final sisa = role['sisaKuota'] as int;
            final skills = (role['skillDicari'] as List?)?.cast<String>() ?? [];
            return Card(
              margin: const EdgeInsets.only(top: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(role['namaRole']?.toString() ?? '-',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        ),
                        Text('Sisa: $sisa',
                            style: TextStyle(color: sisa > 0 ? cs.primary : cs.error)),
                      ],
                    ),
                    if (skills.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: skills
                            .map((s) => Chip(
                                  label: Text(s, style: const TextStyle(fontSize: 12)),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed:
                            (sisa > 0 && !kuotaPenuh) ? () => _daftar(role['id'].toString()) : null,
                        child: Text(sisa > 0 ? 'Daftar' : 'Kuota penuh'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
