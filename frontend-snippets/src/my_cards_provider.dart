import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/state_managers/cards_collection_manager.dart';

/// 1️⃣ المزود الخاص بالبطاقات المملوكة عامةً (للصفحة الرئيسية / المحفظة)
/// 2️⃣ المزود الخاص بألبوم المجموعات (لتفاصيل كل مجموعة)
final cardsCollectionProvider = ChangeNotifierProvider<CardsCollectionManager>(
  (ref) => CardsCollectionManager(),
);
