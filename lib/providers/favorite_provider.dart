import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../services/favorite_service.dart';

//* เก็บ Favorites ไว้ส่วนกลาง ทุกหน้า (Home, Detail, Favorites) เห็นค่าเดียวกัน
class FavoriteProvider with ChangeNotifier {
  final FavoriteService _service = FavoriteService();
  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<PokemonSummary>>? _favSub;

  String? _uid;
  List<PokemonSummary> _favorites = [];

  List<PokemonSummary> get favorites {
    return _favorites;
  }

  FavoriteProvider() {
    // login -> เริ่มฟัง favorites ของ user นั้น, logout -> ล้างค่า
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _favSub?.cancel();
      _uid = user?.uid;
      _favorites = [];
      notifyListeners();

      if (_uid != null) {
        _favSub = _service.streamFavorites(_uid!).listen((list) {
          _favorites = list;
          notifyListeners();
        });
      }
    });
  }

  bool isFavorite(int id) {
    return _favorites.any((p) {
      return p.id == id;
    });
  }

  Future<void> toggleFavorite(PokemonSummary pokemon) async {
    if (_uid == null) return;
    if (isFavorite(pokemon.id)) {
      await _service.removeFavorite(_uid!, pokemon.id);
    } else {
      await _service.addFavorite(_uid!, pokemon);
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _favSub?.cancel();
    super.dispose();
  }
}
