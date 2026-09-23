import 'package:flutter_cache_manager/flutter_cache_manager.dart';

final CacheManager pokedecImageCache = CacheManager(
  Config(
    'pokedecImages', // ชื่อที่เก็บ ต้องไม่ซ้ำกับของ package อื่น
    stalePeriod: const Duration(days: 30),
    maxNrOfCacheObjects: 1200,
  ),
);
