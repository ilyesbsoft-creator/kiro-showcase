import 'package:flutter/foundation.dart';
import '../models/collection_card_model.dart';
import '../models/collection_model.dart';
import '../repositories/cards_collection_repository.dart';

class CardsCollectionManager extends ChangeNotifier {
  final CardsCollectionRepository _repository = CardsCollectionRepository();

  // Map لتخزين البطاقات لكل مجموعة (المفتاح: collectionId، القيمة: قائمة البطاقات)
  final Map<int, List<CollectionCardModel>> _collectionsCards = {};

  // =========================================================
  // 📥 GETTERS & READERS
  // =========================================================

  /// الحصول على كافة البطاقات المحملة لمجموعة معينة (المملوكة والمقفولة)
  List<CollectionCardModel> getCards(int collectionId) {
    return _collectionsCards[collectionId] ?? [];
  }

  /// 🌟 البطاقات المملوكة فقط عبر **جميع المجموعات**
  List<CollectionCardModel> get allMyOwnedCards {
    return _collectionsCards.values
        .expand((cards) => cards)
        .where((card) => card.isOwned)
        .toList();
  }

  /// إرجاع البطاقات المملوكة فقط داخل **مجموعة معينة**
  List<CollectionCardModel> getOwnedCards(int collectionId) {
    return getCards(collectionId).where((e) => e.isOwned).toList();
  }

  /// التحقق مما إذا كانت بطاقات مجموعة معينة قد تم تحميلها سابقاً
  bool isLoaded(int collectionId) {
    return _collectionsCards.containsKey(collectionId) &&
        _collectionsCards[collectionId]!.isNotEmpty;
  }

  /// البحث عن بطاقة معينة باستخدام ID البطاقة داخل مجموعة معينة
  CollectionCardModel? findCardInCollection(int collectionId, int cardId) {
    final cards = getCards(collectionId);
    try {
      return cards.firstWhere((e) => e.card.id == cardId);
    } catch (_) {
      return null;
    }
  }

  /// حساب نسبة اكتمال المجموعة (من 0.0 إلى 1.0)
  double getCollectionProgress(int collectionId) {
    final cards = getCards(collectionId);
    if (cards.isEmpty) return 0.0;

    final ownedCount = cards.where((e) => e.isOwned).length;
    return ownedCount / cards.length;
  }

  // =========================================================
  // 🔄 FETCHING & MUTATIONS
  // =========================================================

  /// تحميل بطاقات مجموعة معينة إذا لم تكن محملة في الذاكرة
  Future<List<CollectionCardModel>> loadCollectionCards(int collectionId) async {
    if (isLoaded(collectionId)) {
      return _collectionsCards[collectionId]!;
    }

    final cards = await _repository.getUserCardsByCollectionId(collectionId);
    _collectionsCards[collectionId] = cards;
    notifyListeners();
    return cards;
  }

  /// تحميل بطاقات جميع المجموعات دفعة واحدة باستخدام قائمة المجموعات المحملة
  Future<void> loadAllCollectionsCards(List<CollectionModel> collections) async {
    if (collections.isEmpty) return;

    try {
      // جلب بطاقات كل المجموعات بالتوازي (Parallel Requests) لتوفير الوقت
      final futures = collections.map((collection) async {
        final cards = await _repository.getUserCardsByCollectionId(collection.id);
        return MapEntry(collection.id, cards);
      });

      final entries = await Future.wait(futures);

      // تخزين البطاقات في الـ Map
      for (var entry in entries) {
        _collectionsCards[entry.key] = entry.value;
      }

      notifyListeners();
    } catch (e) {
      // التعامل مع الأخطاء إن أردت
      rethrow;
    }
  }

  /// إعادة تحميل بطاقات مجموعة معينة من السيرفر لتحديث البيانات
  Future<List<CollectionCardModel>> refreshCollection(int collectionId) async {
    final cards = await _repository.getUserCardsByCollectionId(collectionId);
    _collectionsCards[collectionId] = cards;
    notifyListeners();
    return cards;
  }

  /// 🌟 إضافة أو تحديث بطاقة عند عمل Scan أو فتح حزمة (Local Optimistic Update)
  void addOrUpdateCard(int collectionId, CollectionCardModel newCard) {
    // ⚠️ حماية مهمة جداً:
    // إذا لم يقم المستخدم بفتح صفحة هذه المجموعة من قبل (أي لم تُحمل من السيرفر بعد)،
    // فلا تفعل شيئاً هنا. السيرفر سيجلبها مع البطاقات المقفولة عندما يفتح المستخدم الصفحة.
    if (!_collectionsCards.containsKey(collectionId)) return;

    final cards = _collectionsCards[collectionId]!;
    final index = cards.indexWhere((e) => e.card.id == newCard.card.id);

    if (index != -1) {
      // البطاقة موجودة في الذاكرة (رمادية)، نحدثها لتصبح ملونة ومملوكة
      final existingCard = cards[index];
      cards[index] = existingCard.copyWith(
        isOwned: true,
        quantity: existingCard.quantity + (newCard.quantity > 0 ? newCard.quantity : 1),
        obtainedFrom: newCard.obtainedFrom ?? existingCard.obtainedFrom,
        obtainedAt: newCard.obtainedAt ?? DateTime.now(),
      );
    } else {
      // في حالة نادرة جداً لو لم تكن البطاقة موجودة أصلاً في القائمة، نضيفها
      cards.add(newCard);
    }

    notifyListeners();
  }

  int get totalCardsCount {
    return _collectionsCards.values
        .fold(0, (sum, cards) => sum + cards.length);
  }

  int getOwnedCardsCountByRarity(int rarityId) {
    return _collectionsCards.values
        .expand((cards) => cards)
        .where((card) => card.isOwned && card.card.rarityId == rarityId)
        .length;
  }

  /// مسح كافة البيانات المحفوظة في الذاكرة (عند تسجيل الخروج مثلاً)
  void clear() {
    _collectionsCards.clear();
    notifyListeners();
  }
}