//* ข้อมูลแบบย่อ ใช้แสดงในหน้า List / Favorites / Team
class PokemonSummary {
  final int id;
  final String name;

  PokemonSummary({required this.id, required this.name});

  // รูปดึงจาก id ได้เลย ไม่ต้องยิง API เพิ่ม
  String get imageUrl {
    return 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';
  }

  String get spriteUrl {
    return 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png';
  }

  String get displayName {
    return name.isEmpty ? '???' : name[0].toUpperCase() + name.substring(1);
  }

  String get number {
    return '#${id.toString().padLeft(4, '0')}';
  }

  // จาก PokeAPI: { "name": "bulbasaur", "url": ".../pokemon/1/" }
  factory PokemonSummary.fromApi(Map<String, dynamic> json) {
    final segments = Uri.parse(json['url']).pathSegments.where((s) {
      return s.isNotEmpty;
    });
    return PokemonSummary(id: int.parse(segments.last), name: json['name']);
  }

  // จาก / ไป Firestore (เก็บแค่ id กับ name)
  factory PokemonSummary.fromJson(Map<String, dynamic> json) {
    return PokemonSummary(id: json['id'] ?? 0, name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class PokemonStat {
  final String name;
  final int value;
  PokemonStat({required this.name, required this.value});
}

//* ข้อมูลเต็ม ใช้ในหน้า Detail (ไม่เก็บลง Firestore ดึงจาก API ทุกครั้ง)
class PokemonDetail {
  final int id;
  final String name;
  final List<String> types;
  final List<String> abilities;
  final List<PokemonStat> stats;
  final double heightM; // เมตร
  final double weightKg; // กิโลกรัม

  PokemonDetail({
    required this.id,
    required this.name,
    required this.types,
    required this.abilities,
    required this.stats,
    required this.heightM,
    required this.weightKg,
  });

  PokemonSummary get summary {
    return PokemonSummary(id: id, name: name);
  }

  factory PokemonDetail.fromApi(Map<String, dynamic> json) {
    return PokemonDetail(
      id: json['id'],
      name: json['name'],
      types: (json['types'] as List).map((t) {
        return t['type']['name'] as String;
      }).toList(),
      abilities: (json['abilities'] as List).map((a) {
        return a['ability']['name'] as String;
      }).toList(),
      stats: (json['stats'] as List).map((s) {
        return PokemonStat(name: s['stat']['name'], value: s['base_stat']);
      }).toList(),
      // API ให้ height เป็น decimetre และ weight เป็น hectogram
      heightM: (json['height'] as num) / 10,
      weightKg: (json['weight'] as num) / 10,
    );
  }
}
