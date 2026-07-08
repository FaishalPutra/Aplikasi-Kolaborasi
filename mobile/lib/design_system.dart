import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:showcaseview/showcaseview.dart';

// Design system bersama — dipakai semua modul (People-to-People, People-to-Project,
// Team Formation, General Features) supaya tampilan konsisten satu gaya.
// Referensi: travel/marketplace app modern — pill hitam, kartu foto full-bleed,
// tipografi dua-nada (bold hitam + abu-abu), floating pill bottom nav.

// ---------- WARNA ----------
// Palet "Old Photograph": cream pucat -> khaki -> olive-taupe -> olive gelap.
// Rasio dibuat seperti foto lama asli: kertas/latar tetap netral (putih), warna
// hangatnya cuma jadi aksen (chip, teks di atas tombol gelap) — bukan mendominasi
// seluruh layar.
class DS {
  DS._();

  static const Color background = Color(0xFFFFFFFF);
  static const Color primaryText = Color(0xFF545333);
  static const Color secondaryText = Color(0xFF878672);
  static const Color active = Color(0xFF545333); // chip/nav/CTA aktif
  static const Color onActive = Color(0xFFFDFBD4);
  static const Color chipInactiveBg = Color(0xFFD9D7B6);
  static const Color infoCardBg = Color(0xFFD9D7B6);
  static const Color divider = Color(0xFFC9C7A0);

  // dipertahankan supaya kode lama yang masih pakai nama ini tidak perlu diganti semua
  static const Color danger = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color pink = Color(0xFFE11D48);
  static const Color pinkMuda = Color(0xFFFFF1F2);

  static TextStyle get font => GoogleFonts.inter();
  // Khusus teks hero di halaman cover (WelcomePage) — dipertahankan pakai serif
  // supaya nuansa "vintage" foto tetap dapat, sisanya app pakai Inter.
  static TextStyle get fontCover => GoogleFonts.ptSerif();
}

// ---------- TIPOGRAFI ----------
TextStyle dsHeroBold(double size) =>
    DS.font.copyWith(fontSize: size, fontWeight: FontWeight.w700, color: DS.primaryText, height: 1.15);
TextStyle dsHeroMuted(double size) =>
    DS.font.copyWith(fontSize: size, fontWeight: FontWeight.w400, color: DS.secondaryText, height: 1.15);
TextStyle dsValue(double size) =>
    DS.font.copyWith(fontSize: size, fontWeight: FontWeight.w700, color: DS.primaryText);
TextStyle dsLabel(double size) =>
    DS.font.copyWith(fontSize: size, fontWeight: FontWeight.w400, color: DS.secondaryText);
TextStyle dsBody({Color? color, FontWeight weight = FontWeight.w400}) =>
    DS.font.copyWith(fontSize: 14, fontWeight: weight, color: color ?? DS.primaryText, height: 1.4);

// ---------- PILL FILTER CHIP ----------
class DsChip extends StatelessWidget {
  final String label;
  final bool aktif;
  final VoidCallback onTap;
  // Dipakai untuk opsi yang sementara tidak bisa dipilih (mis. kuota penuh) —
  // tetap terlihat tapi diredupkan & tidak bisa ditekan.
  final bool enabled;
  const DsChip({super.key, required this.label, required this.aktif, required this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: !enabled
                ? DS.chipInactiveBg.withValues(alpha: 0.5)
                : (aktif ? DS.active : DS.chipInactiveBg),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label,
              style: DS.font.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: !enabled
                      ? DS.secondaryText.withValues(alpha: 0.6)
                      : (aktif ? DS.onActive : DS.primaryText))),
        ),
      );
}

// ---------- TOMBOL CTA PENUH-LEBAR (HITAM) ----------
class DsCtaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  const DsCtaButton({super.key, required this.label, this.onPressed, this.loading = false, this.icon});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          onPressed: loading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: DS.active,
            disabledBackgroundColor: const Color(0xFFCBD5E1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
          child: loading
              ? const SizedBox(
                  height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (icon != null) ...[Icon(icon, color: DS.onActive, size: 18), const SizedBox(width: 8)],
                  Text(label, style: DS.font.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: DS.onActive)),
                ]),
        ),
      );
}

// ---------- TOMBOL IKON BULAT MELAYANG (di atas foto) ----------
class DsCircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const DsCircleIconButton({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 20, color: DS.primaryText)),
        ),
      );
}

// ---------- BADGE FROSTED-GLASS DI ATAS FOTO ----------
Widget dsPhotoBadge(String label, {Widget? leading}) => ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(999)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (leading != null) ...[leading, const SizedBox(width: 6)],
            Text(label, style: DS.font.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: DS.primaryText)),
          ]),
        ),
      ),
    );

// ---------- GRADIENT GELAP DI BAWAH FOTO (supaya teks terbaca) ----------
BoxDecoration dsPhotoFade() => const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Color(0x99000000), Color(0xF2000000)],
        stops: [0.15, 0.55, 1.0],
      ),
    );

// ---------- DOT PAGINATION ----------
class DsDots extends StatelessWidget {
  final int jumlah;
  final int aktif;
  const DsDots({super.key, required this.jumlah, required this.aktif});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(jumlah, (i) {
          final on = i == aktif;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: on ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: on ? Colors.white : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(999),
            ),
          );
        }),
      );
}

// ---------- FACT CARD (ikon + label + value, grid horizontal) ----------
class DsFactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const DsFactCard({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: DS.infoCardBg, borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 20, color: DS.primaryText),
          const SizedBox(height: 10),
          Text(label, style: dsLabel(12)),
          const SizedBox(height: 2),
          Text(value, style: dsValue(14)),
        ]),
      );
}

// ---------- AVATAR STACK BERTUMPUK + BADGE JUMLAH ----------
class DsAvatarStack extends StatelessWidget {
  final List<String> inisial;
  final int lebih;
  const DsAvatarStack({super.key, required this.inisial, this.lebih = 0});

  Color _warna(String key) {
    const palette = [Color(0xFF2563EB), Color(0xFF16A34A), Color(0xFF9333EA), Color(0xFF0D9488), Color(0xFFDB2777)];
    var h = 0;
    for (final c in key.codeUnits) {
      h = (h + c) % palette.length;
    }
    return palette[h];
  }

  @override
  Widget build(BuildContext context) {
    final total = inisial.length + (lebih > 0 ? 1 : 0);
    return SizedBox(
      width: 28.0 + (total - 1) * 20.0,
      height: 32,
      child: Stack(
        children: [
          for (var i = 0; i < inisial.length; i++)
            Positioned(
              left: i * 20.0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _warna(inisial[i]),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(inisial[i].isNotEmpty ? inisial[i][0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          if (lebih > 0)
            Positioned(
              left: inisial.length * 20.0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: DS.primaryText, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                alignment: Alignment.center,
                child: Text('+$lebih', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------- FLOATING PILL BOTTOM NAV ----------
class DsNavItem {
  final IconData icon;
  final String label;
  // Opsional — dipakai tur onboarding (lihat main.dart) buat highlight tab ini.
  final GlobalKey? showcaseKey;
  final String? showcaseTitle;
  final String? showcaseDesc;
  const DsNavItem(this.icon, this.label, {this.showcaseKey, this.showcaseTitle, this.showcaseDesc});
}

class DsFloatingNavBar extends StatelessWidget {
  final int index;
  final List<DsNavItem> items;
  final ValueChanged<int> onTap;
  const DsFloatingNavBar({super.key, required this.index, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          // top:14 — kasih jarak jelas dari konten halaman di atasnya supaya
          // tidak kelihatan tumpang tindih/dempet dengan kartu di atasnya.
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: DS.active,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < items.length; i++) _item(i),
              ],
            ),
          ),
        ),
      );

  Widget _item(int i) {
    final aktif = i == index;
    final item = items[i];
    final tombol = GestureDetector(
      onTap: () => onTap(i),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: aktif ? 16 : 12, vertical: 10),
        decoration: BoxDecoration(
          color: aktif ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(item.icon, size: 22, color: aktif ? DS.active : Colors.white),
          if (aktif) ...[
            const SizedBox(width: 8),
            Text(item.label,
                style: DS.font.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: DS.active)),
          ],
        ]),
      ),
    );
    if (item.showcaseKey == null) return tombol;
    return Showcase(
      key: item.showcaseKey!,
      title: item.showcaseTitle,
      description: item.showcaseDesc ?? '',
      targetShapeBorder: const CircleBorder(),
      child: tombol,
    );
  }
}

// ---------- GAUGE CINCIN LINGKARAN PENUH (gradient, ujung membulat) ----------
// Dipakai untuk menampilkan skor kecocokan (persen) sebagai cincin lingkaran
// penuh dengan gradasi warna, ujung membulat (rounded-cap) — bukan segmen
// terpisah, satu busur mulus mengikuti nilai persennya.
class DsRadialGauge extends StatelessWidget {
  final num percent; // 0..100
  final double size;
  final Color filledColor;
  final Color emptyColor;
  final Widget? center;
  const DsRadialGauge({
    super.key,
    required this.percent,
    this.size = 160,
    this.filledColor = const Color(0xFF16A34A),
    this.emptyColor = const Color(0xFFE3EFE6),
    this.center,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _DsGaugePainter(percent: percent.toDouble(), filledColor: filledColor, emptyColor: emptyColor),
            ),
          ),
          if (center != null) center!,
        ]),
      );
}

class _DsGaugePainter extends CustomPainter {
  final double percent;
  final Color filledColor;
  final Color emptyColor;
  _DsGaugePainter({required this.percent, required this.filledColor, required this.emptyColor});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.09;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // cincin latar (bagian belum terisi)
    final bgPaint = Paint()
      ..color = emptyColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // busur terisi — mulai dari jam 12, gradasi searah putaran
    final sweep = 2 * math.pi * (percent.clamp(0, 100) / 100);
    if (sweep > 0) {
      final fgPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + sweep,
          colors: [filledColor.withValues(alpha: 0.55), filledColor],
        ).createShader(rect);
      canvas.drawArc(rect, -math.pi / 2, sweep, false, fgPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DsGaugePainter oldDelegate) =>
      oldDelegate.percent != percent ||
      oldDelegate.filledColor != filledColor ||
      oldDelegate.emptyColor != emptyColor;
}

// ---------- PEMILIH JADWAL (7 hari x 4 waktu) ----------
// Dipakai bersama di halaman Profil, filter Rekomendasi, dan form Ajukan Proyek —
// supaya vocabulary ketersediaan waktu selalu sinkron di semua modul.
const List<String> dsHariOpsi = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const List<String> dsWaktuOpsi = ['Pagi', 'Siang', 'Sore', 'Malam'];

// 28 kombinasi "{Hari} {waktu}", format sama seperti data lama (mis. "Senin malam")
// supaya tidak perlu migrasi data yang sudah tersimpan.
final List<String> dsJadwalOpsiLengkap = [
  for (final h in dsHariOpsi) for (final w in dsWaktuOpsi) '$h ${w.toLowerCase()}',
];

// Grid kompak 7x4 (bukan Wrap 28 chip) supaya pemilihan tidak terlihat menumpuk.
// Baris = hari, kolom = waktu; sel ditekan untuk toggle satu slot.
class DsJadwalGrid extends StatelessWidget {
  final Set<String> value;
  final ValueChanged<String> onToggle;
  const DsJadwalGrid({super.key, required this.value, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          const SizedBox(width: 64),
          ...dsWaktuOpsi.map((w) => Expanded(
                child: Center(
                  child: Text(w,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DS.secondaryText)),
                ),
              )),
        ]),
        const SizedBox(height: 6),
        for (final h in dsHariOpsi)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              SizedBox(
                width: 64,
                child: Text(h,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DS.primaryText)),
              ),
              ...dsWaktuOpsi.map((w) {
                final slot = '$h ${w.toLowerCase()}';
                final aktif = value.contains(slot);
                return Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: () => onToggle(slot),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: aktif ? DS.active : DS.chipInactiveBg,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        alignment: Alignment.center,
                        child: aktif ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                      ),
                    ),
                  ),
                );
              }),
            ]),
          ),
      ],
    );
  }
}

// ---------- IKON BANTUAN ATRIBUT PROFIL (tanda tanya kecil) ----------
// Dipakai lintas modul supaya penjelasan tiap atribut profil konsisten dan
// tidak ditulis ulang di tiap file — cukup tambah entri baru di sini.
class DsAtributInfo {
  final String judul;
  final String isi;
  const DsAtributInfo(this.judul, this.isi);
}

const Map<String, DsAtributInfo> dsAtribut = {
  'nama': DsAtributInfo('Nama',
      'Nama lengkapmu, ditampilkan ke pengguna lain saat mereka melihat profil, kartu rekomendasi, atau daftar anggota tim.'),
  'kampus': DsAtributInfo('Asal Kampus',
      'Institusi tempat kamu kuliah. Membantu calon partner atau tim mengenali latar belakangmu, dan bisa jadi kesamaan yang mempermudah kerja sama.'),
  'jurusan': DsAtributInfo('Jurusan',
      'Bidang studi yang kamu tekuni, jadi gambaran singkat keahlian akademismu bagi orang lain.'),
  'angkatan': DsAtributInfo('Angkatan',
      'Tahun kamu mulai kuliah, membantu memperkirakan tingkat pengalaman dan senioritasmu.'),
  'bio': DsAtributInfo('Bio',
      'Deskripsi singkat tentang dirimu, supaya orang lain lebih kenal kamu sebelum terhubung atau mengajakmu bergabung.'),
  'kontak': DsAtributInfo('Kontak Utama',
      'Cara orang lain menghubungimu. Baru terlihat setelah kalian saling terhubung atau diterima dalam suatu proyek/tim, tidak ditampilkan ke sembarang orang.'),
  'minat': DsAtributInfo('Minat',
      'Bidang yang kamu sukai atau ingin dalami, dipakai untuk mencocokkanmu dengan partner, proyek, atau tim yang minatnya sejalan denganmu.'),
  'skill': DsAtributInfo('Skill',
      'Kemampuan yang sudah kamu kuasai, dipakai untuk mencocokkanmu dengan proyek atau tim yang membutuhkan keahlian tersebut.'),
  'pengalaman': DsAtributInfo('Pengalaman',
      'Tingkat jam terbangmu dalam mengerjakan proyek atau organisasi, dipakai supaya kamu dicocokkan dengan proyek atau tim yang levelnya sesuai denganmu.'),
  'gayaKerja': DsAtributInfo('Gaya Kerja',
      'Cara kamu suka bekerja, terstruktur dengan rencana yang jelas atau fleksibel mengikuti keadaan. Dipakai supaya kamu dicocokkan dengan partner, proyek, atau tim yang gaya kerjanya cocok denganmu.'),
  'preferensiPeran': DsAtributInfo('Preferensi Peran',
      'Peran yang biasanya kamu ambil saat kerja tim, memimpin, mengeksekusi, atau mendukung. Dipakai supaya kombinasi peran dalam tim atau proyek lebih seimbang.'),
  'gayaKerjaPeran': DsAtributInfo('Gaya Kerja & Preferensi Peran',
      'Cara kerja (terstruktur/fleksibel) dan peran yang biasa diambil orang ini saat kerja tim (memimpin, mengeksekusi, atau mendukung). Dipakai untuk melihat seberapa cocok caranya bekerja dengan proyek atau timmu.'),
  'ketersediaanWaktu': DsAtributInfo('Ketersediaan Waktu',
      'Hari dan waktu kamu biasanya bisa berkontribusi, dipakai supaya kamu dicocokkan dengan partner, proyek, atau tim yang jadwalnya nyambung dengan jadwalmu.'),
  'proyekSkill': DsAtributInfo('Skill Dibutuhkan',
      'Kemampuan yang dicari pembuat proyek dari calon anggotanya. Semakin banyak skillmu yang cocok, semakin tinggi kecocokanmu dengan proyek ini.'),
  'proyekMinat': DsAtributInfo('Minat / Bidang',
      'Bidang yang berkaitan dengan proyek ini. Dipakai untuk mencari calon anggota yang minatnya sejalan dengan topik proyek.'),
  'proyekGayaKerja': DsAtributInfo('Gaya Kerja Kegiatan',
      'Cara kerja yang paling cocok untuk proyek ini, terstruktur dengan rencana jelas atau fleksibel mengikuti keadaan.'),
  'proyekPengalaman': DsAtributInfo('Pengalaman Disarankan',
      'Tingkat pengalaman yang disarankan pembuat proyek untuk calon anggota, supaya beban kerja proyek sesuai dengan jam terbang pendaftarnya.'),
  'proyekJadwal': DsAtributInfo('Jadwal Kegiatan',
      'Hari dan waktu kegiatan proyek ini biasanya berlangsung. Bukan penentu skor kecocokan, hanya dipakai sebagai syarat lolos supaya jadwalmu tidak bentrok.'),
};

void dsJelaskanAtribut(BuildContext context, String key) {
  final info = dsAtribut[key];
  if (info == null) return;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(info.judul, style: const TextStyle(fontWeight: FontWeight.bold, color: DS.primaryText)),
      content: Text(info.isi, style: const TextStyle(color: DS.primaryText, height: 1.5)),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
    ),
  );
}

Widget dsBantuanIkon(BuildContext context, String key, {double size = 16}) => InkWell(
      onTap: () => dsJelaskanAtribut(context, key),
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(Icons.help_outline, size: size, color: DS.secondaryText),
      ),
    );

// ---------- DAFTAR CHIP YANG BISA DIPERSINGKAT (2 baris + lihat selengkapnya) ----------
// Dipakai untuk chip ketersediaan waktu/jadwal yang bisa sampai 28 item —
// disembunyikan sebagian setelah 2 baris supaya tidak terlihat menumpuk,
// dengan tombol untuk membuka/menutup sisanya.
class DsExpandableChips extends StatefulWidget {
  final List<String> items;
  final int maxLines;
  const DsExpandableChips({super.key, required this.items, this.maxLines = 2});

  @override
  State<DsExpandableChips> createState() => _DsExpandableChipsState();
}

class _DsExpandableChipsState extends State<DsExpandableChips> {
  bool _terbuka = false;

  static const _spacing = 8.0;
  static const _hPad = 14.0, _vPad = 9.0;
  static const _style = TextStyle(color: DS.primaryText, fontSize: 13, fontWeight: FontWeight.w500);

  Widget _chip(String s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: _vPad),
        decoration: BoxDecoration(color: DS.chipInactiveBg, borderRadius: BorderRadius.circular(999)),
        child: Text(s, style: _style),
      );

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const Text('Belum diisi', style: TextStyle(color: DS.secondaryText));
    return LayoutBuilder(builder: (context, constraints) {
      final maxWidth = constraints.maxWidth;
      final painter = TextPainter(textDirection: TextDirection.ltr);
      double lineWidth = 0;
      int line = 1;
      int cutoff = widget.items.length;
      var overflow = false;
      for (var i = 0; i < widget.items.length; i++) {
        painter.text = TextSpan(text: widget.items[i], style: _style);
        painter.layout();
        final chipWidth = painter.width + _hPad * 2;
        final addWidth = lineWidth == 0 ? chipWidth : lineWidth + _spacing + chipWidth;
        if (addWidth > maxWidth && lineWidth > 0) {
          line++;
          if (line > widget.maxLines) {
            cutoff = i;
            overflow = true;
            break;
          }
          lineWidth = chipWidth;
        } else {
          lineWidth = addWidth;
        }
      }
      final tampil = (_terbuka || !overflow) ? widget.items : widget.items.sublist(0, cutoff);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: _spacing, runSpacing: _spacing, children: tampil.map(_chip).toList()),
          if (overflow) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => setState(() => _terbuka = !_terbuka),
              child: Text(_terbuka ? 'Sembunyikan' : 'Lihat selengkapnya',
                  style: const TextStyle(color: DS.active, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ],
      );
    });
  }
}
