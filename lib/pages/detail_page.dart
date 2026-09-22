import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pokemon.dart';
import '../providers/favorite_provider.dart';
import '../services/pokemon_service.dart';
import '../widgets/type_chip.dart';

class DetailPage extends StatefulWidget {
  final PokemonSummary pokemon;
  const DetailPage({super.key, required this.pokemon});

  @override
  State<DetailPage> createState() {
    return _DetailPageState();
  }
}

class _DetailPageState extends State<DetailPage> {
  late Future<PokemonDetail> _futureDetail;

  static const Map<String, String> statLabels = {
    'hp': 'HP',
    'attack': 'ATK',
    'defense': 'DEF',
    'special-attack': 'SP.ATK',
    'special-defense': 'SP.DEF',
    'speed': 'SPD',
  };

  @override
  void initState() {
    super.initState();
    _futureDetail = PokemonService().fetchDetail(widget.pokemon.id);
  }

  //* กดชื่อ ability -> เปิดแผ่นด้านล่าง บอกว่าความสามารถนี้ทำอะไร
  void _showAbility(String ability) {
    // สร้าง Future ครั้งเดียวก่อนเปิด ไม่งั้นแผ่นวาดใหม่ทีไรจะยิง request ใหม่
    final future = PokemonService().fetchAbilityEffect(ability);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_pretty(ability),
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                FutureBuilder<String>(
                  future: future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Text(
                          'Could not load this ability. Check your internet.');
                    }
                    return Text(snapshot.data!,
                        style: Theme.of(context).textTheme.bodyLarge);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _pretty(String s) {
    return s.split('-').map((w) {
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pokemon;
    final isFav = context.select<FavoriteProvider, bool>((f) {
      return f.isFavorite(p.id);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('${p.displayName}  ${p.number}'),
        actions: [
          IconButton(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.red : null),
            onPressed: () {
              context.read<FavoriteProvider>().toggleFavorite(p);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Hero(
            tag: 'pokemon-${p.id}',
            child: CachedNetworkImage(
              imageUrl: p.imageUrl,
              height: 220,
              // ระหว่างรอรูปใหญ่ ใช้รูปเล็กที่โหลดไว้แล้วจากหน้า Grid -> Hero บินได้ลื่น ไม่ว่าง
              placeholder: (context, url) {
                return Image(
                  image: CachedNetworkImageProvider(p.spriteUrl),
                  height: 220,
                  filterQuality: FilterQuality.none,
                );
              },
            ),
          ),
          FutureBuilder<PokemonDetail>(
            future: _futureDetail,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Could not load details.'));
              }

              final d = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Wrap(
                      spacing: 8,
                      children: d.types.map((t) {
                        return TypeChip(type: t);
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _InfoTile(label: 'Height', value: '${d.heightM} m'),
                      _InfoTile(label: 'Weight', value: '${d.weightKg} kg'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Abilities',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: d.abilities.map((ability) {
                      return ActionChip(
                        avatar: const Icon(Icons.info_outline, size: 18),
                        label: Text(_pretty(ability)),
                        onPressed: () {
                          _showAbility(ability);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('Base Stats',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...d.stats.map((s) {
                    return _StatBar(
                      label: statLabels[s.name] ?? s.name,
                      value: s.value,
                      color: typeColors[d.types.first] ?? Colors.blue,
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatBar(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 64,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 36, child: Text('$value')),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: value / 255, // base stat สูงสุดคือ 255
                minHeight: 10,
                color: color,
                backgroundColor: color.withOpacity(0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
