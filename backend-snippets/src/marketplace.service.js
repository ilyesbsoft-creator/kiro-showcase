const AppError =
  require("../../core/errors/AppError");

const ERRORS =
  require("../../core/errors/errorCodes");
  
const {
  notifyUser,
} = require("../../core/websocket/socket.server");  

class MarketplaceService {
constructor(
  marketplaceRepository,
  userCardsRepository,
  gemTransactionsRepository,
  collectionsRepository,
  raritiesRepository,
  userCollectionProgressService,
  leaderboardsRepository,
  leaderboardEntriesRepository,
  db
) {
  this.repo =
    marketplaceRepository;

  this.userCardsRepo =
    userCardsRepository;

  this.gemTransactionsRepo =
    gemTransactionsRepository;

  this.collectionsRepo =
    collectionsRepository;

  this.raritiesRepo =
    raritiesRepository;

  this.collectionProgressService =
    userCollectionProgressService;

  this.leaderboardsRepo =
    leaderboardsRepository;

  this.leaderboardEntriesRepo =
    leaderboardEntriesRepository;

  this.db =
    db;
}

  // =========================================================
  // ➕ CREATE USER LISTING
  //
  // إذا كان هناك Listing نشط لنفس:
  // user + user_card + card + price
  //
  // يتم دمج الكمية معه.
  // =========================================================

  async createUserListing(
    userId,
    payload
  ) {
    const {
      user_card_id,
      price_gems,
      quantity = 1,
    } = payload;

    const listingQuantity =
      Number(quantity);

    const price =
      Number(price_gems);

    const userCardId =
      Number(user_card_id);

    // =======================================================
    // 🔢 BASIC VALIDATION
    // =======================================================

    if (
      !Number.isSafeInteger(
        userCardId
      ) ||
      userCardId <= 0
    ) {
      throw new AppError(
        ERRORS.USER_CARD_NOT_FOUND,
        404
      );
    }

    if (
      !Number.isSafeInteger(
        listingQuantity
      ) ||
      listingQuantity < 1
    ) {
      throw new AppError(
        ERRORS.INVALID_MARKETPLACE_QUANTITY,
        400
      );
    }

    if (
      !Number.isSafeInteger(price) ||
      price <= 0
    ) {
      throw new AppError(
        ERRORS.INVALID_MARKETPLACE_PRICE,
        400
      );
    }

    return this.db.transaction(
      async (trx) => {

        // ===================================================
        // 🔒 LOCK USER CARD
        // ===================================================

        const userCard =
          await this.userCardsRepo
            .findByIdForUpdate(
              userCardId,
              trx
            );

        if (!userCard) {
          throw new AppError(
            ERRORS.USER_CARD_NOT_FOUND,
            404
          );
        }

        // ===================================================
        // 👤 OWNERSHIP
        // ===================================================

        if (
          Number(
            userCard.user_id
          ) !== Number(userId)
        ) {
          throw new AppError(
            ERRORS.USER_CARD_NOT_OWNED,
            403
          );
        }

        // ===================================================
        // 📊 QUANTITY
        // ===================================================

        const ownedQuantity =
          Number(
            userCard.quantity || 0
          );

        const reservedQuantity =
          Number(
            userCard.reserved_quantity || 0
          );

const availableQuantity =
  ownedQuantity -
  reservedQuantity;

// 🔒 يجب الاحتفاظ بنسخة واحدة للـ Collection
const sellableQuantity =
  Math.max(
    0,
    availableQuantity - 1
  );

if (
  listingQuantity >
  sellableQuantity
) {
  throw new AppError(
    ERRORS.INSUFFICIENT_AVAILABLE_CARD_QUANTITY,
    400
  );
}

        // ===================================================
        // 🃏 CARD
        // ===================================================

        const card =
          await trx("cards")
            .where({
              id: userCard.card_id,
            })
            .first();

        if (!card) {
          throw new AppError(
            ERRORS.CARD_NOT_FOUND,
            404
          );
        }

        // ===================================================
        // 🟢 ACTIVE
        // ===================================================

        if (!card.is_active) {
          throw new AppError(
            ERRORS.CARD_NOT_ACTIVE,
            400
          );
        }

        // ===================================================
        // 🔄 TRADEABLE
        // ===================================================

        if (!card.is_tradeable) {
          throw new AppError(
            ERRORS.CARD_NOT_TRADEABLE,
            400
          );
        }

        // ===================================================
        // 🔒 RESERVE QUANTITY
        //
        // يتم الحجز قبل تعديل الـ Listing.
        // ===================================================

        await this.userCardsRepo
          .reserveQuantity(
            userCardId,
            listingQuantity,
            trx
          );

        // ===================================================
        // 🔎 FIND EXISTING LISTING
        // ===================================================

        const existingListing =
          await this.repo.findActiveUserListingForMerge(
            userId,
            userCardId,
            userCard.card_id,
            price,
            trx
          );

        const now =
          new Date();

        // ===================================================
        // 🔄 MERGE EXISTING LISTING
        // ===================================================

        if (existingListing) {

          const newQuantity =
            Number(
              existingListing.quantity
            ) +
            listingQuantity;

          if (
            !Number.isSafeInteger(
              newQuantity
            )
          ) {
            throw new AppError(
              ERRORS.INVALID_MARKETPLACE_QUANTITY,
              400
            );
          }

          await trx(
            "marketplace_listings"
          )
            .where({
              id: existingListing.id,
            })
            .increment(
              "quantity",
              listingQuantity
            )
			.increment("original_quantity", listingQuantity)
            .update({
              updated_at: now,
            });

          return this.repo.findListingById(
            existingListing.id,
            trx
          );
        }

        // ===================================================
        // ➕ CREATE NEW LISTING
        // ===================================================

        return this.repo.createListing(
          {
            seller_type:
              "user",

            seller_id:
              userId,

            user_card_id:
              userCardId,

            card_id:
              userCard.card_id,

            price_gems:
              price,

            quantity:
              listingQuantity,
			  
			original_quantity:
			  quantity,  

            status:
              "active",

            listed_at:
              now,

            created_at:
              now,

            updated_at:
              now,
          },
          trx
        );
      }
    );
  }

  // =========================================================
  // ➕ CREATE ADMIN LISTING
  //
  // إذا كان هناك عرض Admin نشط لنفس:
  // card + price
  //
  // يتم دمج الكمية معه.
  // =========================================================

  async createAdminListing(
    payload
  ) {
    const {
      card_id,
      price_gems,
      quantity = 1,
    } = payload;

    const cardId =
      Number(card_id);

    const listingQuantity =
      Number(quantity);

    const price =
      Number(price_gems);

    // =======================================================
    // 🔢 VALIDATION
    // =======================================================

    if (
      !Number.isSafeInteger(cardId) ||
      cardId <= 0
    ) {
      throw new AppError(
        ERRORS.CARD_NOT_FOUND,
        404
      );
    }

    if (
      !Number.isSafeInteger(
        listingQuantity
      ) ||
      listingQuantity < 1
    ) {
      throw new AppError(
        ERRORS.INVALID_MARKETPLACE_QUANTITY,
        400
      );
    }

    if (
      !Number.isSafeInteger(price) ||
      price <= 0
    ) {
      throw new AppError(
        ERRORS.INVALID_MARKETPLACE_PRICE,
        400
      );
    }

    // =======================================================
    // 🔒 ADMIN LISTING TRANSACTION
    // =======================================================

    return this.db.transaction(
      async (trx) => {

        // ===================================================
        // 🃏 LOCK CARD
        // ===================================================

        const card =
          await trx("cards")
            .where({
              id: cardId,
            })
            .first();

        if (!card) {
          throw new AppError(
            ERRORS.CARD_NOT_FOUND,
            404
          );
        }

        // ===================================================
        // 🟢 ACTIVE
        // ===================================================

        if (!card.is_active) {
          throw new AppError(
            ERRORS.CARD_NOT_ACTIVE,
            400
          );
        }

        // ===================================================
        // 🔄 TRADEABLE
        // ===================================================

        if (!card.is_tradeable) {
          throw new AppError(
            ERRORS.CARD_NOT_TRADEABLE,
            400
          );
        }

        // ===================================================
        // 🔎 FIND EXISTING ADMIN LISTING
        // ===================================================

        const existingListing =
          await this.repo.findActiveAdminListingForMerge(
            cardId,
            price,
            trx
          );

        const now =
          new Date();

        // ===================================================
        // 🔄 MERGE
        // ===================================================

        if (existingListing) {

          const newQuantity =
            Number(
              existingListing.quantity
            ) +
            listingQuantity;

          if (
            !Number.isSafeInteger(
              newQuantity
            )
          ) {
            throw new AppError(
              ERRORS.INVALID_MARKETPLACE_QUANTITY,
              400
            );
          }

          await trx(
            "marketplace_listings"
          )
            .where({
              id: existingListing.id,
            })
            .increment(
              "quantity",
              listingQuantity
            )
            .update({
              updated_at: now,
            });

          return this.repo.findListingById(
            existingListing.id,
            trx
          );
        }

        // ===================================================
        // ➕ CREATE
        // ===================================================

        return this.repo.createListing(
          {
            seller_type:
              "admin",

            seller_id:
              null,

            user_card_id:
              null,

            card_id:
              cardId,

            price_gems:
              price,

            quantity:
              listingQuantity,

            status:
              "active",

            listed_at:
              now,

            created_at:
              now,

            updated_at:
              now,
          },
          trx
        );
      }
    );
  }

// =========================================================
// 📋 GET MY LISTINGS
// =========================================================

async getMyListings(
  userId,
  query
) {
  return this.repo.findMyListings(
    userId,
    query
  );
}

  // =========================================================
  // 📋 GET MARKETPLACE
  // =========================================================

  async getListings(
    query
  ) {
    return this.repo.findAllListings(
      query
    );
  }

  // =========================================================
  // 🔍 GET LISTING
  // =========================================================

  async getListingById(
    id
  ) {
    const listing =
      await this.repo.findListingById(
        id
      );

    if (!listing) {
      throw new AppError(
        ERRORS.MARKETPLACE_LISTING_NOT_FOUND,
        404
      );
    }

    return listing;
  }

// =========================================================
// ✏️ UPDATE USER LISTING
// Quantity + Price
// =========================================================

async updateListing(
  userId,
  listingId,
  newQuantity,
  newPriceGems
) {
  const quantity =
    Number(newQuantity);

  const priceGems =
    Number(newPriceGems);

  const numericListingId =
    Number(listingId);

  // =======================================================
  // 🔢 QUANTITY VALIDATION
  // =======================================================

  if (
    !Number.isSafeInteger(quantity) ||
    quantity < 1
  ) {
    throw new AppError(
      ERRORS.INVALID_MARKETPLACE_QUANTITY,
      400
    );
  }

  // =======================================================
  // 💰 PRICE VALIDATION
  // =======================================================

  if (
    !Number.isSafeInteger(priceGems) ||
    priceGems <= 0
  ) {
    throw new AppError(
      ERRORS.INVALID_MARKETPLACE_PRICE,
      400
    );
  }

  // =======================================================
  // 🔢 LISTING ID VALIDATION
  // =======================================================

  if (
    !Number.isSafeInteger(
      numericListingId
    ) ||
    numericListingId <= 0
  ) {
    throw new AppError(
      ERRORS.MARKETPLACE_LISTING_NOT_FOUND,
      404
    );
  }

  return this.db.transaction(
    async (trx) => {

      // ===================================================
      // 🔒 LOCK LISTING
      // ===================================================

      const listing =
        await this.repo.findListingForUpdate(
          numericListingId,
          trx
        );

      if (!listing) {
        throw new AppError(
          ERRORS.MARKETPLACE_LISTING_NOT_FOUND,
          404
        );
      }

      // ===================================================
      // 🔐 STATUS
      // ===================================================

      if (
        listing.status !==
        "active"
      ) {
        throw new AppError(
          ERRORS.MARKETPLACE_LISTING_NOT_ACTIVE,
          400
        );
      }

      // ===================================================
      // 👤 USER LISTING ONLY
      // ===================================================

      if (
        listing.seller_type !==
        "user"
      ) {
        throw new AppError(
          ERRORS.USER_LISTING_ONLY,
          403
        );
      }

      // ===================================================
      // 👤 OWNER
      // ===================================================

      if (
        Number(
          listing.seller_id
        ) !== Number(userId)
      ) {
        throw new AppError(
          ERRORS.LISTING_NOT_OWNER,
          403
        );
      }

      // ===================================================
      // 🔢 CURRENT QUANTITY
      // ===================================================

      const currentQuantity =
        Number(
          listing.quantity || 0
        );

      if (
        !Number.isSafeInteger(
          currentQuantity
        ) ||
        currentQuantity < 1
      ) {
        throw new AppError(
          ERRORS.INVALID_MARKETPLACE_QUANTITY,
          409
        );
      }

      // ===================================================
      // 💰 CURRENT PRICE
      // ===================================================

      const currentPrice =
        Number(
          listing.price_gems
        );

      if (
        !Number.isSafeInteger(
          currentPrice
        ) ||
        currentPrice <= 0
      ) {
        throw new AppError(
          ERRORS.INVALID_MARKETPLACE_PRICE,
          409
        );
      }

      // ===================================================
      // 🔒 LOCK USER CARD
      // ===================================================

      const userCard =
        await this.userCardsRepo.findByIdForUpdate(
          listing.user_card_id,
          trx
        );

      if (!userCard) {
        throw new AppError(
          ERRORS.USER_CARD_NOT_FOUND,
          404
        );
      }

      // ===================================================
      // 👤 OWNERSHIP VALIDATION
      // ===================================================

      if (
        Number(
          userCard.user_id
        ) !== Number(userId)
      ) {
        throw new AppError(
          ERRORS.LISTING_OWNERSHIP_INVALID,
          409
        );
      }

      // ===================================================
      // 🃏 CARD MATCH
      // ===================================================

      if (
        Number(
          userCard.card_id
        ) !==
        Number(
          listing.card_id
        )
      ) {
        throw new AppError(
          ERRORS.LISTING_CARD_MISMATCH,
          409
        );
      }

      // ===================================================
      // 🔢 USER CARD QUANTITY
      // ===================================================

      const ownedQuantity =
        Number(
          userCard.quantity || 0
        );

      const reservedQuantity =
        Number(
          userCard.reserved_quantity || 0
        );

      if (
        !Number.isSafeInteger(
          ownedQuantity
        ) ||
        ownedQuantity < 0
      ) {
        throw new AppError(
          ERRORS.INSUFFICIENT_CARD_QUANTITY,
          409
        );
      }

      if (
        !Number.isSafeInteger(
          reservedQuantity
        ) ||
        reservedQuantity < 0
      ) {
        throw new AppError(
          ERRORS.INSUFFICIENT_RESERVED_QUANTITY,
          409
        );
      }

      // ===================================================
      // 🔐 LISTING / RESERVATION CONSISTENCY
      // ===================================================

      if (
        reservedQuantity <
        currentQuantity
      ) {
        throw new AppError(
          ERRORS.INSUFFICIENT_RESERVED_QUANTITY,
          409
        );
      }

      // ===================================================
      // 📉 DECREASE QUANTITY
      // ===================================================

      if (
        quantity <
        currentQuantity
      ) {

        const releaseQuantity =
          currentQuantity -
          quantity;

        // ===============================================
        // 🔓 RELEASE RESERVED
        // ===============================================

        await this.userCardsRepo
          .releaseReservedQuantity(
            listing.user_card_id,
            releaseQuantity,
            trx
          );
      }

      // ===================================================
      // 📈 INCREASE QUANTITY
      // ===================================================

      if (
        quantity >
        currentQuantity
      ) {

        const additionalQuantity =
          quantity -
          currentQuantity;

        // ===============================================
        // 📊 AVAILABLE QUANTITY
        // ===============================================

const availableQuantity =
  ownedQuantity - reservedQuantity;

// 🔒 الاحتفاظ بنسخة واحدة للـ Collection
const sellableQuantity =
  Math.max(
    0,
    availableQuantity - 1
  );

if (
  additionalQuantity >
  sellableQuantity
) {
  throw new AppError(
    ERRORS.INSUFFICIENT_AVAILABLE_CARD_QUANTITY,
    400
  );
}

        // ===============================================
        // 🔒 RESERVE ADDITIONAL
        // ===============================================

        await this.userCardsRepo
          .reserveQuantity(
            listing.user_card_id,
            additionalQuantity,
            trx
          );
      }

      // ===================================================
      // 💾 UPDATE LISTING
      // ===================================================

      const updatedListing =
        await this.repo.updateListing(
          listing.id,
          {
            quantity,
			original_quantity: quantity,
            price_gems: priceGems,
          },
          trx
        );

      // ===================================================
      // 📦 RESULT
      // ===================================================

      return updatedListing;
    }
  );
}

// =========================================================
// 🛒 PURCHASE
// =========================================================

async purchase(
  buyerId,
  listingId,
  quantity
) {
  const purchaseQuantity =
    Number(quantity);

  const numericListingId =
    Number(listingId);

  // =======================================================
  // 🔢 VALIDATION
  // =======================================================

  if (
    !Number.isSafeInteger(
      purchaseQuantity
    ) ||
    purchaseQuantity < 1
  ) {
    throw new AppError(
      ERRORS.INVALID_PURCHASE_QUANTITY,
      400
    );
  }

  if (
    !Number.isSafeInteger(
      numericListingId
    ) ||
    numericListingId <= 0
  ) {
    throw new AppError(
      ERRORS.MARKETPLACE_LISTING_NOT_FOUND,
      404
    );
  }
  let saleNotificationUserId = null;
  
  const result = await this.db.transaction(
    async (trx) => {

      // ===================================================
      // 🔒 LOCK LISTING
      // ===================================================

      const listing =
        await this.repo
          .findListingForUpdate(
            numericListingId,
            trx
          );

      if (!listing) {
        throw new AppError(
          ERRORS.MARKETPLACE_LISTING_NOT_FOUND,
          404
        );
      }

      // ===================================================
      // 🔐 STATUS
      // ===================================================

      if (
        listing.status !==
        "active"
      ) {
        throw new AppError(
          ERRORS.MARKETPLACE_LISTING_NOT_ACTIVE,
          400
        );
      }

      // ===================================================
      // 🚫 SELF PURCHASE
      // ===================================================

      if (
        listing.seller_type ==="user" &&
        Number(
          listing.seller_id
        ) === Number(buyerId)
      ) {
        throw new AppError(
          ERRORS.CANNOT_BUY_OWN_LISTING,
          400
        );
      }

      // ===================================================
      // 🔢 LISTING QUANTITY
      // ===================================================

      const availableListingQuantity =
        Number(
          listing.quantity || 0
        );

      if (
        !Number.isSafeInteger(
          availableListingQuantity
        ) ||
        availableListingQuantity < 1
      ) {
        throw new AppError(
          ERRORS.INSUFFICIENT_LISTING_QUANTITY,
          400
        );
      }

      if (
        purchaseQuantity >
        availableListingQuantity
      ) {
        throw new AppError(
          ERRORS.INSUFFICIENT_LISTING_QUANTITY,
          400
        );
      }

      // ===================================================
      // 💰 UNIT PRICE
      // ===================================================

      const unitPrice =
        Number(
          listing.price_gems
        );

      if (
        !Number.isSafeInteger(
          unitPrice
        ) ||
        unitPrice <= 0
      ) {
        throw new AppError(
          ERRORS.INVALID_MARKETPLACE_PRICE,
          400
        );
      }

      // ===================================================
      // 💰 TOTAL PRICE
      // ===================================================

      const totalPrice =
        unitPrice *
        purchaseQuantity;

      if (
        !Number.isSafeInteger(
          totalPrice
        ) ||
        totalPrice <= 0
      ) {
        throw new AppError(
          ERRORS.INVALID_MARKETPLACE_PRICE,
          400
        );
      }

      // ===================================================
      // 🃏 GET CARD
      // ===================================================

      const card =
        await trx("cards")
          .where({
            id: listing.card_id,
          })
          .first();

      if (!card) {
        throw new AppError(
          ERRORS.CARD_NOT_FOUND,
          404
        );
      }

      // ===================================================
      // 🟢 CARD ACTIVE
      // ===================================================

      if (!card.is_active) {
        throw new AppError(
          ERRORS.CARD_NOT_ACTIVE,
          400
        );
      }

      // ===================================================
      // 🔄 CARD TRADEABLE
      // ===================================================

      if (!card.is_tradeable) {
        throw new AppError(
          ERRORS.CARD_NOT_TRADEABLE,
          400
        );
      }

      // ===================================================
      // 🔒 LOCK BUYER
      // ===================================================

      const buyer =
        await this.repo
          .findUserForUpdate(
            buyerId,
            trx
          );

      if (!buyer) {
        throw new AppError(
          ERRORS.USER_NOT_FOUND,
          404
        );
      }

      // ===================================================
      // 💎 BUYER BALANCE
      // ===================================================

      const buyerGems =
        Number(
          buyer.gems || 0
        );

      if (
        buyerGems <
        totalPrice
      ) {
        throw new AppError(
          ERRORS.INSUFFICIENT_GEMS,
          400
        );
      }

      // ===================================================
      // 👤 USER SELLER
      // ===================================================

      let seller = null;
      let sellerCard = null;

      if (
        listing.seller_type ===
        "user"
      ) {

		saleNotificationUserId =
          Number(listing.seller_id);		
        // ===============================================
        // 🔒 LOCK SELLER CARD
        // ===============================================

        sellerCard =
          await this.userCardsRepo
            .findByIdForUpdate(
              listing.user_card_id,
              trx
            );

        if (!sellerCard) {
          throw new AppError(
            ERRORS.USER_CARD_NOT_FOUND,
            404
          );
        }

        // ===============================================
        // 👤 OWNERSHIP
        // ===============================================

        if (
          Number(
            sellerCard.user_id
          ) !==
          Number(
            listing.seller_id
          )
        ) {
          throw new AppError(
            ERRORS.LISTING_OWNERSHIP_INVALID,
            409
          );
        }

        // ===============================================
        // 🃏 CARD MATCH
        // ===============================================

        if (
          Number(
            sellerCard.card_id
          ) !==
          Number(
            listing.card_id
          )
        ) {
          throw new AppError(
            ERRORS.LISTING_CARD_MISMATCH,
            409
          );
        }

        // ===============================================
        // 🔒 RESERVED QUANTITY
        // ===============================================

        const sellerReservedQuantity =
          Number(
            sellerCard.reserved_quantity ||
              0
          );

        if (
          sellerReservedQuantity <
          purchaseQuantity
        ) {
          throw new AppError(
            ERRORS.INSUFFICIENT_RESERVED_QUANTITY,
            409
          );
        }

        // ===============================================
        // 🔢 OWNED QUANTITY
        // ===============================================

        const sellerOwnedQuantity =
          Number(
            sellerCard.quantity || 0
          );

        if (
          sellerOwnedQuantity <
          purchaseQuantity
        ) {
          throw new AppError(
            ERRORS.INSUFFICIENT_CARD_QUANTITY,
            409
          );
        }

        // ===============================================
        // 🔒 LOCK SELLER
        // ===============================================

        seller =
          await this.repo
            .findUserForUpdate(
              listing.seller_id,
              trx
            );

        if (!seller) {
          throw new AppError(
            ERRORS.USER_NOT_FOUND,
            404
          );
        }
      }

      // ===================================================
      // 🧮 TAX
      // ===================================================

      let taxGems = 0;

      let sellerReceivedGems = 0;

      if (
        listing.seller_type ===
        "user"
      ) {

        // 10% marketplace tax

        taxGems =
          Math.floor(
            totalPrice * 0.10
          );

        sellerReceivedGems =
          totalPrice -
          taxGems;

      } else {

        // =================================================
        // ADMIN SALE
        //
        // 100% burned
        // =================================================

        taxGems =
          totalPrice;

        sellerReceivedGems =
          0;
      }

// ===================================================
// 💎 BALANCE AFTER
// ===================================================

const buyerBalanceAfter =
  buyerGems - totalPrice;

let sellerBalanceAfter = null;

if (
  listing.seller_type ===
  "user"
) {
  const sellerGems =
    Number(
      seller.gems || 0
    );

  sellerBalanceAfter =
    sellerGems +
    sellerReceivedGems;
}

      // ===================================================
      // 💎 DEDUCT BUYER ATOMICALLY
      // ===================================================

      const buyerUpdated =
        await trx("users")
          .where({
            id: buyerId,
          })
          .where(
            "gems",
            ">=",
            totalPrice
          )
          .decrement(
            "gems",
            totalPrice
          );

      if (
        buyerUpdated !== 1
      ) {
        throw new AppError(
          ERRORS.INSUFFICIENT_GEMS,
          409
        );
      }

      // ===================================================
      // 💎 PAY USER SELLER
      // ===================================================

      if (
        listing.seller_type ===
          "user" &&
        sellerReceivedGems > 0
      ) {

        const sellerUpdated =
          await trx("users")
            .where({
              id:
                listing.seller_id,
            })
            .increment(
              "gems",
              sellerReceivedGems
            );

        if (
          sellerUpdated !== 1
        ) {
          throw new AppError(
            ERRORS.USER_NOT_FOUND,
            409
          );
        }
      }

      // ===================================================
      // 🃏 TRANSFER FROM USER SELLER
      // ===================================================

      if (
        listing.seller_type ===
        "user"
      ) {

        await this.userCardsRepo
          .decreaseQuantityForMarketplace(
            listing.user_card_id,
            purchaseQuantity,
            trx
          );
      }

      // ===================================================
      // 🔍 FIND BUYER CARD
      //
      // إذا كان اللاعب يملك البطاقة:
      // نزيد الكمية فقط.
      //
      // إذا لم يكن يملكها:
      // ننشئ user_card جديد.
      // ===================================================

      let buyerUserCard = null;

      const existingCard =
        await this.userCardsRepo
          .findUserCardForUpdate(
            buyerId,
            listing.card_id,
            trx
          );

      const now =
        new Date();

      // ===================================================
      // 🔁 EXISTING CARD
      // ===================================================

      if (existingCard) {

        await this.userCardsRepo
          .increaseQuantityForMarketplace(
            existingCard.id,
            purchaseQuantity,
            trx
          );

        // ===============================================
        // 🔄 GET UPDATED USER CARD
        // ===============================================

        buyerUserCard =
          await this.userCardsRepo
            .findByIdForUpdate(
              existingCard.id,
              trx
            );

      } else {

        // =================================================
        // 🆕 NEW CARD
        // =================================================

        buyerUserCard =
          await this.userCardsRepo.create(
            {
              user_id:
                buyerId,

              card_id:
                listing.card_id,

              quantity:
                purchaseQuantity,

              reserved_quantity:
                0,

              obtained_from:
                "marketplace",

              obtained_at:
                now,

              created_at:
                now,
            },
            trx
          );
		  
		  // ===================================================
// 🏆 COLLECTOR SCORE
//
// يتم احتساب الـ Collector فقط إذا كانت البطاقة
// جديدة بالنسبة للمشتري.
//
// شراء Duplicate:
// - لا يزيد unique_cards
// - لا يعطي rarity score
// - لا يعيد collection completion
// ===================================================

let completedCollections = [];

if (!existingCard) {

  // =================================================
  // 🎴 GET CARD RARITY
  // =================================================

  const rarity =
    await this.raritiesRepo.findById(
      card.rarity_id,
      trx
    );

  if (!rarity) {
    throw new AppError(
      ERRORS.RARITY_NOT_FOUND,
      500
    );
  }

  // =================================================
  // ⭐ RARITY SCORE
  // =================================================

  const rarityScore =
    Number(
      rarity.score_value || 0
    );

  // =================================================
  // 📦 COLLECTION PROGRESS
  // =================================================

  completedCollections =
    await this.collectionProgressService
      .checkAndUpdateProgress(
        buyerId,
        card,
        trx
      );

  // =================================================
  // 🎨 GET COLLECTION
  // =================================================

  const collection =
    await this.collectionsRepo.findById(
      card.collection_id,
      trx
    );

  if (!collection) {
    throw new AppError(
      ERRORS.COLLECTION_NOT_FOUND,
      500
    );
  }

  // =================================================
  // 🏆 COLLECTION COMPLETED
  // =================================================

  let collectionScore = 0;

  if (
    completedCollections.includes(
      card.collection_id
    )
  ) {
    collectionScore =
      Number(
        collection.score_value || 0
      );
  }

  // =================================================
  // 🧮 TOTAL SCORE
  // =================================================

  const totalScore =
    rarityScore +
    collectionScore;

  // =================================================
  // 🏆 GET ACTIVE GLOBAL COLLECTOR LEADERBOARD
  // =================================================

  const leaderboard =
    await this.leaderboardsRepo
      .findActiveGlobalCollector(
        trx
      );

  if (!leaderboard) {
    throw new AppError(
      ERRORS.LEADERBOARD_NOT_FOUND,
      500
    );
  }

  // =================================================
  // 👤 GET USER LEADERBOARD ENTRY
  // =================================================

  const leaderboardEntry =
    await this.leaderboardEntriesRepo
      .findByUser(
        leaderboard.id,
        buyerId,
        trx
      );

  // =================================================
  // ✏️ UPDATE EXISTING ENTRY
  // =================================================

  if (leaderboardEntry) {

    await this.leaderboardEntriesRepo.update(
      leaderboardEntry.id,
      {
        collector_score:
          Number(
            leaderboardEntry.collector_score || 0
          ) +
          totalScore,

        unique_cards:
          Number(
            leaderboardEntry.unique_cards || 0
          ) +
          1,

        completed_collections:
          Number(
            leaderboardEntry.completed_collections || 0
          ) +
          (
            collectionScore > 0
              ? 1
              : 0
          ),
      },
      trx
    );

  // =================================================
  // 🆕 CREATE LEADERBOARD ENTRY
  // =================================================

  } else {

    await this.leaderboardEntriesRepo.create(
      {
        leaderboard_id:
          leaderboard.id,

        user_id:
          buyerId,

        collector_score:
          totalScore,

        unique_cards:
          1,

        completed_collections:
          collectionScore > 0
            ? 1
            : 0,
      },
      trx
    );
  }
}
		  
      }

      // ===================================================
      // 📉 UPDATE LISTING
      // ===================================================

      const remainingQuantity =
        availableListingQuantity -
        purchaseQuantity;

      if (
        remainingQuantity ===
        0
      ) {

        // ===============================================
        // SOLD
        // ===============================================

        await this.repo
          .markListingSold(
            listing.id,
            now,
            trx
          );

      } else {

        // ===============================================
        // STILL ACTIVE
        // ===============================================

        await this.repo
          .decreaseListingQuantity(
            listing.id,
            purchaseQuantity,
            trx
          );
      }

      // ===================================================
      // 🧾 PURCHASE RECORD
      // ===================================================

      const purchase =
        await this.repo
          .createPurchase(
            {
              listing_id:
                listing.id,

              buyer_id:
                buyerId,

              seller_id:
                listing.seller_type ===
                "user"
                  ? listing.seller_id
                  : null,

              price_gems:
                totalPrice,

              quantity:
                purchaseQuantity,

              tax_gems:
                taxGems,

              seller_received_gems:
                sellerReceivedGems,

              purchased_at:
                now,

              created_at:
                now,
            },
            trx
          );
		  
// ===================================================
// 💎 BUYER GEM TRANSACTION
// ===================================================

await this.gemTransactionsRepo.create(
  {
    user_id: buyerId,

    amount: totalPrice,

    type: "subtract",

    reason: "card_purchase",

    reference_id: purchase.id,

    balance_after:
      buyerBalanceAfter,
  },
  trx
);

// ===================================================
// 💎 SELLER GEM TRANSACTION
// ===================================================

if (
  listing.seller_type === "user" &&
  sellerReceivedGems > 0
) {
  await this.gemTransactionsRepo.create(
    {
      user_id:
        listing.seller_id,

      amount:
        sellerReceivedGems,

      type: "add",

      reason: "card_sale",

      reference_id:
        purchase.id,

      balance_after:
        sellerBalanceAfter,
    },
    trx
  );
}		  

      // ===================================================
      // 📦 RESULT
      // ===================================================

      return {
        user_card: {
          id:
            buyerUserCard.id,

          user_id:
            buyerUserCard.user_id,

          card_id:
            buyerUserCard.card_id,

          quantity:
            buyerUserCard.quantity,

          obtained_from:
            buyerUserCard.obtained_from,

          obtained_at:
            buyerUserCard.obtained_at,
        },

        card: {
          ...card,
        },

        purchase: {
          id:
            purchase.id,

          quantity:
            purchase.quantity,

          price_gems:
            purchase.price_gems,
        },
      };
    }
  );
  // =========================================================
  // 🔔 REAL-TIME SELL NOTIFICATION
  //
  // يتم الإرسال فقط بعد نجاح الـ transaction والـ commit
  // =========================================================

  if (saleNotificationUserId) {
    notifyUser(
      saleNotificationUserId,
      "marketplace:sale"
    );
  }

  return result;
}

  // =========================================================
  // ❌ CANCEL USER LISTING
  // =========================================================

  async cancelListing(
    userId,
    listingId
  ) {
    return this.db.transaction(
      async (trx) => {

        // ===================================================
        // 🔒 LOCK LISTING
        // ===================================================

        const listing =
          await this.repo
            .findListingForUpdate(
              listingId,
              trx
            );

        if (!listing) {
          throw new AppError(
            ERRORS.MARKETPLACE_LISTING_NOT_FOUND,
            404
          );
        }

        // ===================================================
        // 🔐 STATUS
        // ===================================================

        if (
          listing.status !==
          "active"
        ) {
          throw new AppError(
            ERRORS.MARKETPLACE_LISTING_NOT_ACTIVE,
            400
          );
        }

        // ===================================================
        // 👤 USER LISTING ONLY
        // ===================================================

        if (
          listing.seller_type !==
          "user"
        ) {
          throw new AppError(
            ERRORS.ADMIN_LISTING_CANNOT_BE_CANCELLED,
            403
          );
        }

        // ===================================================
        // 👤 OWNER
        // ===================================================

        if (
          Number(
            listing.seller_id
          ) !== Number(userId)
        ) {
          throw new AppError(
            ERRORS.LISTING_NOT_OWNER,
            403
          );
        }

        // ===================================================
        // 🔒 LOCK USER CARD
        // ===================================================

        const userCard =
          await this.userCardsRepo
            .findByIdForUpdate(
              listing.user_card_id,
              trx
            );

        if (!userCard) {
          throw new AppError(
            ERRORS.USER_CARD_NOT_FOUND,
            404
          );
        }

        // ===================================================
        // 👤 OWNERSHIP
        // ===================================================

        if (
          Number(
            userCard.user_id
          ) !== Number(userId)
        ) {
          throw new AppError(
            ERRORS.LISTING_OWNERSHIP_INVALID,
            409
          );
        }

        // ===================================================
        // 🃏 CARD MATCH
        // ===================================================

        if (
          Number(
            userCard.card_id
          ) !==
          Number(
            listing.card_id
          )
        ) {
          throw new AppError(
            ERRORS.LISTING_CARD_MISMATCH,
            409
          );
        }

        // ===================================================
        // 🔐 RESERVED QUANTITY
        // ===================================================

        const reservedQuantity =
          Number(
            userCard.reserved_quantity ||
              0
          );

        const listingQuantity =
          Number(
            listing.quantity || 0
          );

        if (
          reservedQuantity <
          listingQuantity
        ) {
          throw new AppError(
            ERRORS.INSUFFICIENT_RESERVED_QUANTITY,
            409
          );
        }

        // ===================================================
        // 🔓 RELEASE RESERVATION
        // ===================================================

        await this.userCardsRepo
          .releaseReservedQuantity(
            listing.user_card_id,
            listingQuantity,
            trx
          );

        // ===================================================
        // ❌ CANCEL
        // ===================================================

        return this.repo.cancelListing(
          listing.id,
          new Date(),
          trx
        );
      }
    );
  }

  // =========================================================
  // 📜 PURCHASE HISTORY
  // =========================================================

  async getPurchases(
    filters
  ) {
    return this.repo.findPurchases(
      filters
    );
  }
  
// =========================================================
// 📜 TRADE HISTORY FOR USER
// =========================================================

async getTradeHistory(
  filters
) {
  return this.repo.findTradeHistory(
    filters
  );
}


// =========================================================
// 🔢 MARKETPLACE TRADES COUNT
// =========================================================

async getUserTradesCount(userId) {
  return this.repo.countUserTrades(userId);
}

async getUserSalesCountSince(
  userId,
  since
) {
  return this.repo.countUserSalesSince(
    userId,
    since
  );
}
    
}

module.exports =
  MarketplaceService;