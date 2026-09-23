import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pokemon.dart';
import '../providers/settings_provider.dart';
import '../services/pokemon_service.dart';
import '../widgets/pokemon_card.dart';
import '../widgets/type_chip.dart';
import 'about_page.dart';
import 'favorites_page.dart';
import 'setting_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  final PokemonService _service = PokemonService();
  late Future<List<PokemonSummary>> _futureList;
  String _query = '';
  String? _selectedType; // null = ทุกธาตุ (ALL)
  Set<int>? _typeIds; // id ของธาตุที่เลือก, null = ไม่กรอง หรือกำลังโหลด

  @override
  void initState() {
    super.initState();
    _futureList = _loadHome();
  }

  //* โหลดรายชื่อ + ธาตุของทุกตัวไปพร้อมกัน (ธาตุเอาไว้โชว์บนการ์ด)
  Future<List<PokemonSummary>> _loadHome() async {
    final listFuture = _service.fetchAll(); // เริ่มโหลดทันที ไม่ต้องรอธาตุ
    try {
      await _service.fetchAllTypes();
    } catch (error) {
      // โหลดธาตุไม่ได้ ก็ยังดูรายชื่อได้ แค่การ์ดไม่มีป้ายธาตุ
      debugPrint('Could not load types: $error');
    }
    return listFuture;
  }

  void _retry() {
    setState(() {
      _futureList = _loadHome();
    });
  }

  //* กดเลือกธาตุ (null = ALL), กดธาตุเดิมซ้ำ = ยกเลิก
  Future<void> _selectType(String? type) async {
    final newType = _selectedType == type ? null : type;
    setState(() {
      _selectedType = newType;
      _typeIds = null;
    });
    if (newType == null) return;

    try {
      final ids = await _service.fetchTypeIds(newType);
      // ระหว่างรอ ถ้าผู้ใช้กดธาตุอื่นไปแล้ว ไม่ต้องใช้ผลนี้
      if (!mounted || _selectedType != newType) return;
      setState(() {
        _typeIds = ids;
      });
    } catch (e) {
      if (!mounted || _selectedType != newType) return;
      setState(() {
        _selectedType = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load $newType Pokémon. Check your internet.')),
      );
    }
  }

  // ค้นหาได้ทั้งชื่อ และเลข id + กรองตามธาตุที่เลือก
  List<PokemonSummary> _filter(List<PokemonSummary> all) {
    final q = _query.trim().toLowerCase();
    final typeIds = _typeIds;
    if (q.isEmpty && typeIds == null) return all;
    return all.where((p) {
      final matchesType = typeIds == null || typeIds.contains(p.id);
      final matchesQuery = q.isEmpty || p.name.contains(q) || p.id.toString() == q;
      return matchesType && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final showGrid = context.watch<SettingsProvider>().showGrid;

    return Scaffold(
      appBar: AppBar(
        // มุมซ้ายบน: เปิดหน้าข้อมูลผู้จัดทำ
        leading: IconButton(
          icon: const Icon(Icons.badge_outlined),
          tooltip: 'About me',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return const AboutPage();
                },
              ),
            );
          },
        ),
        title: const Text('Pokédex'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: 'Favorites',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const FavoritesPage();
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const SettingPage();
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name or number',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
            ),
          ),
          // แถบเลือกธาตุ: ALL + 18 ธาตุ (หน้าตาเดียวกับ TypeChip ในหน้า Detail)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              children: [null, ...typeColors.keys].map((type) {
                return _TypeFilterChip(
                  type: type,
                  selected: _selectedType == type,
                  dimmed: _selectedType != null && _selectedType != type,
                  onTap: () {
                    _selectType(type);
                  },
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<PokemonSummary>>(
              future: _futureList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                            'Could not load Pokémon. Check your internet.'),
                        TextButton(
                            onPressed: _retry, child: const Text('Retry')),
                      ],
                    ),
                  );
                }

                // เลือกธาตุแล้ว แต่รายชื่อของธาตุนั้นยังโหลดไม่เสร็จ
                if (_selectedType != null && _typeIds == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final list = _filter(snapshot.data!);
                if (list.isEmpty) {
                  return const Center(child: Text('No Pokémon found'));
                }

                // ListView.builder / GridView.builder สร้างเฉพาะที่เห็นบนจอ -> รูปโหลดทีละนิดเอง
                if (showGrid) {
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 180,
                      childAspectRatio: 0.78, // เผื่อที่ให้ป้ายธาตุใต้เลข
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      return PokemonCard(pokemon: list[i]);
                    },
                  );
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    return PokemonCard(pokemon: list[i], compact: true);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

//* ปุ่มเลือกธาตุ 1 ปุ่ม (type == null คือ ALL)
class _TypeFilterChip extends StatelessWidget {
  final String? type;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  const _TypeFilterChip({
    required this.type,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
          child: Opacity(
            opacity: dimmed ? 0.35 : 1,
            child: Center(child: TypeChip(type: type ?? 'all')),
          ),
        ),
      ),
    );
  }
}
