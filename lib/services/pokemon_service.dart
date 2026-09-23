import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';

class PokemonService {
  static const String baseUrl = 'https://pokeapi.co/api/v2';

  // เก็บไว้ในหน่วยความจำ เปิดหน้าเดิมซ้ำจะได้ไม่ต้องโหลดใหม่
  static List<PokemonSummary>? _allCache;
  static final Map<int, PokemonDetail> _detailCache = {};
  static final Map<String, Set<int>> _typeCache = {};
  static final Map<String, String> _abilityCache = {};
  // ธาตุของ Pokémon แต่ละตัว (slot 1 อยู่หน้าเสมอ) ใช้โชว์บนการ์ด
  static final Map<int, List<String>> _typesById = {};

  // ชื่อธาตุทั้ง 18 ต้องตรงกับ key ใน typeColors (widgets/type_chip.dart)
  static const List<String> typeNames = [
    'normal', 'fire', 'water', 'electric', 'grass', 'ice',
    'fighting', 'poison', 'ground', 'flying', 'psychic', 'bug',
    'rock', 'ghost', 'dragon', 'dark', 'steel', 'fairy',
  ];

  //* โหลดรายชื่อทั้งหมดครั้งเดียว (~1,300 ตัว มีแค่ชื่อกับ url ไฟล์เล็ก)
  //  แล้วค่อย search / filter ในเครื่อง เพราะ PokeAPI ไม่มี search endpoint
  Future<List<PokemonSummary>> fetchAll() async {
    if (_allCache != null) return _allCache!;

    final response = await http.get(Uri.parse('$baseUrl/pokemon?limit=100000'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load Pokémon list (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _allCache = (data['results'] as List).map((e) {
      return PokemonSummary.fromApi(e);
    })
        .where((p) {
      return p.id < 10000;
    }).toList();
    return _allCache!;
  }

  //* โหลดข้อมูลเต็มของ Pokémon 1 ตัว
  Future<PokemonDetail> fetchDetail(int id) async {
    if (_detailCache.containsKey(id)) return _detailCache[id]!;

    final response = await http.get(Uri.parse('$baseUrl/pokemon/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load Pokémon #$id (${response.statusCode})');
    }

    final detail = PokemonDetail.fromApi(jsonDecode(response.body));
    _detailCache[id] = detail;
    return detail;
  }

  //* โหลด id ของ Pokémon ทุกตัวในธาตุนั้น (1 request ต่อธาตุ แล้วเก็บไว้)
  Future<Set<int>> fetchTypeIds(String type) async {
    if (_typeCache.containsKey(type)) return _typeCache[type]!;

    final response = await http.get(Uri.parse('$baseUrl/type/$type'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load type $type (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final ids = (data['pokemon'] as List).map((e) {
      return PokemonSummary.fromApi(e['pokemon']).id;
    }).toSet();
    _typeCache[type] = ids;
    return ids;
  }

  //* ธาตุของ Pokémon ทุกตัว โหลด 18 requests พร้อมกันครั้งเดียว
  //  (list endpoint ไม่มีธาตุมาให้ ถ้าโหลดทีละตัวจะ ~1,000 requests)
  Future<void> fetchAllTypes() async {
    if (_typesById.isNotEmpty) return;

    await Future.wait(typeNames.map((type) {
      return _loadType(type);
    }));
  }

  // โหลดธาตุเดียว เก็บผลไว้ 2 แบบ: id -> ธาตุ (ไว้โชว์บนการ์ด) และ ธาตุ -> id (ไว้กรอง)
  Future<void> _loadType(String type) async {
    final response = await http.get(Uri.parse('$baseUrl/type/$type'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load type $type (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final ids = <int>{};
    for (final entry in data['pokemon'] as List) {
      final id = PokemonSummary.fromApi(entry['pokemon']).id;
      ids.add(id);
      if (id >= 10000) continue; // ร่างพิเศษ ไม่ได้โชว์ในแอป

      final types = _typesById.putIfAbsent(id, () {
        return <String>[];
      });
      // โหลดพร้อมกัน 18 ธาตุ ธาตุหลัก (slot 1) อาจมาทีหลัง จึงแทรกไว้หน้าสุด
      if (entry['slot'] == 1) {
        types.insert(0, type);
      } else {
        types.add(type);
      }
    }
    _typeCache[type] = ids;
  }

  //* ธาตุของ Pokémon 1 ตัว (ว่าง = ยังโหลดไม่เสร็จ) การ์ดเรียกใช้ตรง ๆ ไม่ต้องรอ
  static List<String> typesOf(int id) {
    return _typesById[id] ?? const [];
  }

  //* คำอธิบาย ability แบบข้อความในเกม (อ่านง่ายกว่าคำอธิบายเชิงเทคนิค)
  //  1 request ต่อ 1 ability แล้วเก็บไว้ กดซ้ำไม่ต้องโหลดใหม่
  Future<String> fetchAbilityEffect(String name) async {
    if (_abilityCache.containsKey(name)) return _abilityCache[name]!;

    final response = await http.get(Uri.parse('$baseUrl/ability/$name'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load ability $name (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    // ข้อความในเกมก่อน ถ้าไม่มีค่อยใช้คำอธิบายเชิงเทคนิคแทน
    final text = _englishText(data['flavor_text_entries'] as List, 'flavor_text', newest: true) ??
        _englishText(data['effect_entries'] as List, 'short_effect') ??
        'No description available.';
    _abilityCache[name] = text;
    return text;
  }

  // หยิบข้อความภาษาอังกฤษออกจาก list ของ PokeAPI (newest = เอาของเกมล่าสุด)
  // แล้วรวบขึ้นบรรทัดใหม่ให้เป็นช่องว่างเดียว เพราะ PokeAPI ตัดบรรทัดมาให้แล้ว
  static String? _englishText(List entries, String key, {bool newest = false}) {
    final english = entries.where((e) {
      return e['language']['name'] == 'en';
    }).toList();
    if (english.isEmpty) return null;

    final entry = newest ? english.last : english.first;
    return (entry[key] as String).replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
