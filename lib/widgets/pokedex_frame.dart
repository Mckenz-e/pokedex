import 'package:flutter/material.dart';

//* สีของตัวเครื่อง Pokédex (ใช้เฉพาะงานหน้าตา ไม่เกี่ยวกับ logic)
const Color _bodyRed = Color(0xFFC1272D);
const Color _bodyShadow = Color(0xFF8E1B20);
const Color _rimLight = Color(0xFFEB9A9A);
const Color _screenLight = Color(0xFFCFE3D6);
const Color _screenDark = Color(0xFF12302B);

//* ธีมของแอป: พื้นหลัง Scaffold = จอ Pokédex, AppBar โปร่งใสให้เห็นจอ
ThemeData pokedexTheme(Brightness brightness) {
  final bool isDark = brightness == Brightness.dark;

  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _bodyRed,
      brightness: brightness,
    ),
    scaffoldBackgroundColor: isDark ? _screenDark : _screenLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
  );
}

//* กรอบเครื่อง Pokédex ครอบทุกหน้าผ่าน MaterialApp.builder
class PokedexFrame extends StatelessWidget {
  final Widget child;

  const PokedexFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final Color screenColor = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      decoration: const BoxDecoration(
        color: _bodyRed,
        border: Border(
          bottom: BorderSide(color: _bodyShadow, width: 4),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const _StatusLights(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                child: ClipPath(
                  clipper: const _ScreenClipper(chamfer: 24, corner: 10),
                  child: ColoredBox(
                    color: _rimLight,
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: ClipPath(
                        clipper: const _ScreenClipper(chamfer: 22, corner: 9),
                        child: ColoredBox(color: screenColor, child: child),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//* ไฟหน้าเครื่อง: เลนส์ฟ้าดวงใหญ่ + ไฟเล็ก แดง/เหลือง/เขียว
class _StatusLights extends StatelessWidget {
  const _StatusLights();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4FC3F7),
              border: Border.all(color: Colors.white, width: 2.5),
            ),
          ),
          const SizedBox(width: 14),
          const _SmallLight(color: Color(0xFFE53935)),
          const SizedBox(width: 7),
          const _SmallLight(color: Color(0xFFFDD835)),
          const SizedBox(width: 7),
          const _SmallLight(color: Color(0xFF43A047)),
        ],
      ),
    );
  }
}

class _SmallLight extends StatelessWidget {
  final Color color;

  const _SmallLight({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: _bodyShadow, width: 1),
      ),
    );
  }
}

//* ตัดมุมจอให้เป็นเหลี่ยมแบบ Pokédex (มุมขวาบน/ซ้ายล่างตัดเยอะกว่า)
class _ScreenClipper extends CustomClipper<Path> {
  final double chamfer;
  final double corner;

  const _ScreenClipper({required this.chamfer, required this.corner});

  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.moveTo(corner, 0);
    path.lineTo(size.width - chamfer, 0);
    path.lineTo(size.width, chamfer);
    path.lineTo(size.width, size.height - corner);
    path.lineTo(size.width - corner, size.height);
    path.lineTo(chamfer, size.height);
    path.lineTo(0, size.height - chamfer);
    path.lineTo(0, corner);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _ScreenClipper oldClipper) {
    return oldClipper.chamfer != chamfer || oldClipper.corner != corner;
  }
}
