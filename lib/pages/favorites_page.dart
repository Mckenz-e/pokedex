import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorite_provider.dart';
import '../widgets/pokemon_card.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoriteProvider>().favorites;

    return Scaffold(
      appBar: AppBar(title: Text('Favorites (${favorites.length})')),
      body: favorites.isEmpty
          ? const Center(
              child: Text('No favorites yet. Tap the heart on a Pokémon!'))
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, i) {
                return PokemonCard(pokemon: favorites[i], compact: true);
              },
            ),
    );
  }
}
