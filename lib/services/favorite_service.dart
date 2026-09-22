import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pokemon.dart';

// โครงสร้างใน Firestore:
//  users/{uid}/favorites/{pokemonId}  ->  { id, name, addedAt }
class FavoriteService {
  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites');
  }

  Stream<List<PokemonSummary>> streamFavorites(String uid) {
    // เรียงตามเลข Pokedex ในเครื่อง (ไม่ใช้ orderBy เพื่อไม่ต้องรอ serverTimestamp)
    return _collection(uid).snapshots().map((snap) {
      final list = snap.docs.map((d) {
        return PokemonSummary.fromJson(d.data());
      }).toList();
      list.sort((a, b) {
        return a.id.compareTo(b.id);
      });
      return list;
    });
  }

  // ใช้ id ของ Pokemon เป็น document id -> กดซ้ำจะไม่เกิดข้อมูลซ้ำ
  Future<void> addFavorite(String uid, PokemonSummary pokemon) {
    return _collection(uid).doc('${pokemon.id}').set({
      ...pokemon.toJson(),
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFavorite(String uid, int pokemonId) {
    return _collection(uid).doc('$pokemonId').delete();
  }
}
