import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pokemon.dart';
import '../pages/detail_page.dart';
import '../providers/favorite_provider.dart';
import '../services/pokemon_service.dart';
import 'type_chip.dart';

class PokemonCard extends StatelessWidget {
  final PokemonSummary pokemon;
  final bool compact; // true = แบบแถว (List), false = แบบการ์ด (Grid)

  const PokemonCard({super.key, required this.pokemon, this.compact = false});

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return DetailPage(pokemon: pokemon);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFav = context.select<FavoriteProvider, bool>((p) {
      return p.isFavorite(pokemon.id);
    });

    final image = Hero(
      tag: 'pokemon-${pokemon.id}',
      child: CachedNetworkImage(
        imageUrl: pokemon.spriteUrl,
        filterQuality: FilterQuality.none, // ขยาย pixel art ให้คม ไม่เบลอ
        placeholder: (context, url) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorWidget: (context, url, error) {
          return const Icon(Icons.catching_pokemon, size: 40);
        },
      ),
    );

    // ธาตุมาจากตารางที่โหลดไว้ตอนเปิดหน้า Home (ว่างได้ ถ้ายังโหลดไม่เสร็จ)
    final types = PokemonService.typesOf(pokemon.id);

    final favButton = IconButton(
      icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
          color: isFav ? Colors.red : null),
      onPressed: () {
        context.read<FavoriteProvider>().toggleFavorite(pokemon);
      },
    );

    if (compact) {
      return ListTile(
        leading: SizedBox(width: 56, height: 56, child: image),
        title: Text(pokemon.displayName),
        subtitle: Row(
          children: [
            Text(pokemon.number),
            ...types.map((type) {
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: TypeChip(type: type, small: true),
              );
            }),
          ],
        ),
        trailing: favButton,
        onTap: () {
          _openDetail(context);
        },
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          _openDetail(context);
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Expanded(child: image),
                  Text(pokemon.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(pokemon.number,
                      style: Theme.of(context).textTheme.bodySmall),
                  if (types.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: types.map((type) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: TypeChip(type: type, small: true),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(top: 0, right: 0, child: favButton),
          ],
        ),
      ),
    );
  }
}
