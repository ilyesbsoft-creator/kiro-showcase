part of '../profile_page.dart';

extension ProfileWidgets on _ProfilePageState {
  // خلفية بنفسجية متدرجة مع توهج علوي
  Widget buildBackground(Size size) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0F081D), Color(0xFF06030B), Color(0xFF020105)],
            ),
          ),
        ),
        Positioned(
          top: -AppDimensions.height(size, 80),
          left: 0,
          right: 0,
          child: Container(
            height: AppDimensions.height(size, 350),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x3D6B21A8), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // الهيدر العلوي (زر الرجوع + العنوان + زري الإشارات)
  Widget buildHeader(Size size, AppLocalizations tr) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.width(size, 16),
        vertical: AppDimensions.height(size, 8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                tr.profile_title,
                style: GoogleFonts.cinzel(
                  color: Colors.white,
                  fontSize: AppDimensions.font(size, 20),
                  fontWeight: FontWeight.bold,
                  letterSpacing: AppDimensions.width(size, 2.0),
                ),
              ),
              Text(
                tr.profile_subtitle,
                style: GoogleFonts.cinzel(
                  color: Colors.grey.shade400,
                  fontSize: AppDimensions.font(size, 9),
                  letterSpacing: AppDimensions.width(size, 1.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // القسم العلوي (الصورة الرمزية + الاسم + الجواهر والعملات)
  Widget buildProfileHeroSection(Size size, AppLocalizations tr) {
    final user = ref.watch(userProvider.notifier).currentUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              CachedNetworkImage(
                imageUrl: ApiConstants.baseImagesUrl + user!.avatarUrl!,
                width: AppDimensions.width(size, 100),
                height: AppDimensions.width(size, 100),
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: SizedBox(
                    width: AppDimensions.width(size, 24),
                    height: AppDimensions.width(size, 24),
                    child: CircularProgressIndicator(
                      strokeWidth: AppDimensions.width(size, 2),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.account_circle,
                  color: Colors.grey,
                  size: AppDimensions.icon(size, 50),
                ),
                fadeInDuration: const Duration(milliseconds: 200),
                fadeOutDuration: const Duration(milliseconds: 100),
              ),

              SizedBox(
                height: AppDimensions.width(size, 100),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: AppDimensions.height(size, 10.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.displayName ?? "",
                        style: GoogleFonts.cinzel(
                          color: AppColors.kiro_text_color,
                          fontSize: AppDimensions.font(size, 14),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: AppDimensions.height(size, 3)),
                      Text(
                        user.username ?? "",
                        style: GoogleFonts.cinzel(
                          color: AppColors.kiro_text_color.withValues(
                            alpha: 0.6,
                          ),
                          fontSize: AppDimensions.font(size, 10),
                          letterSpacing: AppDimensions.width(size, 1.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          Column(
            children: [
              GemBalanceWidget(gems: user.gems, clickable: true),

              SizedBox(height: 2),

              CoinBalanceWidget(coins: user.coins),
            ],
          ),
        ],
      ),
    );
  }

  // بطاقة Main Card الشاملة للأتتاك والديفينس
  Widget buildMainCardCard(Size size, AppLocalizations tr) {
    final user = ref.watch(userProvider).currentUser;
    final rarityManager = ref.watch(raritiesProvider);
    final cardCollectionManager = ref.watch(cardsCollectionProvider);

    final ownedCards = cardCollectionManager.allMyOwnedCards;

    CollectionCardModel? mainCard;

    if (ownedCards.isEmpty) {
      mainCard = null;
    } else if (user?.currentCardId == null) {
      mainCard = ownedCards.first;
    } else {
      try {
        mainCard = ownedCards.firstWhere(
          (card) => card.card.id == user!.currentCardId,
        );
      } catch (_) {
        mainCard = null; // أو null إذا كنت تفضل ذلك
      }
    }

    if (mainCard == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(AppDimensions.width(size, 12)),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0816).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppDimensions.width(size, 8)),
        border: Border.all(color: const Color(0xFF2A1C42)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.profile_main_card,
                  style: GoogleFonts.cinzel(
                    color: const Color(0xFFCBB26A),
                    fontSize: AppDimensions.font(size, 10),
                    fontWeight: FontWeight.bold,
                    letterSpacing: AppDimensions.width(size, 1.2),
                  ),
                ),
                SizedBox(height: AppDimensions.height(size, 6)),
                Text(
                  mainCard!.card.name,
                  style: GoogleFonts.cinzel(
                    color: Colors.white,
                    fontSize: AppDimensions.font(size, 14),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppDimensions.height(size, 6)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.width(size, 8),
                    vertical: AppDimensions.height(size, 2),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E1065),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.width(size, 4),
                    ),
                  ),
                  child: Text(
                    rarityManager.findById(mainCard.card.rarityId)!.name,
                    style: GoogleFonts.cinzel(
                      color: const Color(0xFFA78BFA),
                      fontSize: AppDimensions.font(size, 9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: AppDimensions.height(size, 16)),
                Row(
                  children: [
                    _buildStatValue(
                      tr.profile_market_price,
                      "${mainCard.card.marketPriceGems}",
                      "assets/images/global/gem.png",
                      size,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // صورة البطاقة الرئيسية
          Container(
            width: AppDimensions.width(size, 110),
            height: AppDimensions.height(size, 160),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.width(size, 5)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.45),
                  blurRadius: AppDimensions.width(size, 12),
                  spreadRadius: AppDimensions.width(size, 1.5),
                  offset: Offset(0, AppDimensions.height(size, 4)),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.width(size, 5)),
              child:
                  (mainCard.card.imageUrl != null &&
                      mainCard.card.imageUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl:
                          ApiConstants.baseImagesUrl + mainCard.card.imageUrl!,
                      placeholder: (context, url) => Center(
                        child: SizedBox(
                          width: AppDimensions.width(size, 20),
                          height: AppDimensions.width(size, 20),
                          child: CircularProgressIndicator(
                            strokeWidth: AppDimensions.width(size, 2),
                            color: const Color(0xFF8B5CF6),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFF140F24),
                        child: Icon(
                          Icons.style,
                          color: Colors.white54,
                          size: AppDimensions.icon(size, 32),
                        ),
                      ),
                      fadeInDuration: const Duration(milliseconds: 200),
                      fadeOutDuration: const Duration(milliseconds: 100),
                    )
                  : Container(
                      color: const Color(0xFF140F24),
                      child: Icon(
                        Icons.style,
                        color: Colors.white54,
                        size: AppDimensions.icon(size, 32),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatValue(
    String label,
    String value,
    String imagePath,
    Size size,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Image.asset(
              imagePath,
              width: AppDimensions.width(size, 16),
              height: AppDimensions.width(size, 16),
            ),
            SizedBox(width: AppDimensions.width(size, 2)),
            Text(
              label,
              style: GoogleFonts.cinzel(
                color: Colors.grey,
                fontSize: AppDimensions.font(size, 8),
              ),
            ),
          ],
        ),
        SizedBox(height: AppDimensions.height(size, 2)),
        Text(
          value,
          style: GoogleFonts.cinzel(
            color: Colors.white,
            fontSize: AppDimensions.font(size, 13),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // إحصائيات الحزم، البطاقات المجمعة والتداول
  Widget buildStatisticsGrid(Size size, AppLocalizations tr) {
    final collectionsManager = ref.watch(collectionsProvider);
    final cardsCollectionManager = ref.watch(cardsCollectionProvider);

    // حساب المجموعات المكتملة
    final completedCollectionsCount = collectionsManager.collections.where((
      collection,
    ) {
      final double progress = cardsCollectionManager.getCollectionProgress(
        collection.id,
      );
      return progress >= 1.0;
    }).length;

    final totalCollectionsCount = collectionsManager.collections.length;

    // نص الكولكشنات المكتملة المنسق
    final collectionsText =
        "$completedCollectionsCount / $totalCollectionsCount";

    final cardsNumbers =
        "${cardsCollectionManager.allMyOwnedCards.length} / ${cardsCollectionManager.totalCardsCount}";

    final tradesCount = ref.watch(marketplaceTradesCountProvider).tradesCount;

    return Container(
      padding: EdgeInsets.symmetric(vertical: AppDimensions.height(size, 12)),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0816).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppDimensions.width(size, 8)),
        border: Border.all(color: const Color(0xFF2A1C42)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatGridItem(
            cardsNumbers,
            tr.profile_cards_collected,
            "assets/images/profile/card_profile.png",
            size,
          ),
          _buildDivider(size),
          _buildStatGridItem(
            collectionsText,
            tr.profile_collections_completed,
            "assets/images/global/cards.png",
            size,
          ),
          _buildDivider(size),
          _buildStatGridItem(
            "$tradesCount",
            tr.profile_market_trades,
            "assets/images/global/marketplace.png",
            size,
          ),
        ],
      ),
    );
  }

  Widget _buildStatGridItem(
    String value,
    String label,
    String imagePath,
    Size size,
  ) {
    return Column(
      children: [
        Image.asset(
          imagePath,
          width: AppDimensions.icon(size, 25),
          height: AppDimensions.icon(size, 25),
        ),
        SizedBox(height: AppDimensions.height(size, 6)),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            value,
            style: GoogleFonts.cinzel(
              color: Colors.white,
              fontSize: AppDimensions.font(size, 13),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: AppDimensions.height(size, 2)),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.cinzel(
            color: Colors.grey,
            fontSize: AppDimensions.font(size, 7.5),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(Size size) {
    return Container(
      height: AppDimensions.height(size, 35),
      width: AppDimensions.width(size, 1),
      color: const Color(0xFF2A1C42),
    );
  }

  // شريط الإنجازات والصفة والمجموعة المفضلة
  Widget buildAchievementsAndLevelRow(Size size, AppLocalizations tr) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // قسم الإنجازات (Achievements)
        Expanded(
          flex: 5,
          child: Container(
            padding: EdgeInsets.all(AppDimensions.width(size, 10)),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0816).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(AppDimensions.width(size, 8)),
              border: Border.all(color: const Color(0xFF2A1C42)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr.profile_achievements,
                      style: GoogleFonts.cinzel(
                        color: const Color(0xFFCBB26A),
                        fontSize: AppDimensions.font(size, 9),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      tr.profile_view_all,
                      style: GoogleFonts.cinzel(
                        color: const Color(0xFFA78BFA),
                        fontSize: AppDimensions.font(size, 8),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppDimensions.height(size, 10)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBadgeItem(tr.badge_first_scan, size),
                    _buildBadgeItem(tr.badge_rich_collector, size),
                    _buildBadgeItem(tr.badge_100_packs, size),
                    _buildBadgeItem(tr.badge_royal_owner, size),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: AppDimensions.width(size, 10)),

        // قسم مستوى اللاعب والمجموعة المفضلة
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(AppDimensions.width(size, 8)),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0816).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.width(size, 8),
                  ),
                  border: Border.all(color: const Color(0xFF2A1C42)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr.profile_player_level,
                            style: GoogleFonts.cinzel(
                              color: const Color(0xFFCBB26A),
                              fontSize: AppDimensions.font(size, 8),
                            ),
                          ),
                          Text(
                            tr.profile_level_value("18"),
                            style: GoogleFonts.cinzel(
                              color: Colors.white,
                              fontSize: AppDimensions.font(size, 11),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppDimensions.height(size, 4)),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.width(size, 2),
                            ),
                            child: LinearProgressIndicator(
                              value: 0.6,
                              minHeight: AppDimensions.height(size, 4),
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF8B5CF6),
                              ),
                            ),
                          ),
                          Text(
                            tr.profile_coins_progress("7,250", "12,000"),
                            style: GoogleFonts.cinzel(
                              color: Colors.grey,
                              fontSize: AppDimensions.font(size, 7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: AppDimensions.width(size, 6)),
                    Icon(
                      Icons.shield,
                      color: Colors.purpleAccent,
                      size: AppDimensions.icon(size, 28),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppDimensions.height(size, 8)),
              Container(
                padding: EdgeInsets.all(AppDimensions.width(size, 8)),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0816).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.width(size, 8),
                  ),
                  border: Border.all(color: const Color(0xFF2A1C42)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr.profile_favorite_collection,
                            style: GoogleFonts.cinzel(
                              color: const Color(0xFFCBB26A),
                              fontSize: AppDimensions.font(size, 8),
                            ),
                          ),
                          Text(
                            "SHADOW NINJAS",
                            style: GoogleFonts.cinzel(
                              color: Colors.white,
                              fontSize: AppDimensions.font(size, 10),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            tr.profile_completion_percentage("37"),
                            style: GoogleFonts.cinzel(
                              color: Colors.grey,
                              fontSize: AppDimensions.font(size, 7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.auto_awesome,
                      color: Colors.purple,
                      size: AppDimensions.icon(size, 24),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeItem(String title, Size size) {
    return Column(
      children: [
        Container(
          width: AppDimensions.width(size, 32),
          height: AppDimensions.height(size, 32),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
            ),
            border: Border.all(color: const Color(0xFFCBB26A)),
          ),
          child: Icon(
            Icons.military_tech,
            color: Colors.amber,
            size: AppDimensions.icon(size, 18),
          ),
        ),
        SizedBox(height: AppDimensions.height(size, 4)),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.cinzel(
            color: Colors.grey,
            fontSize: AppDimensions.font(size, 7),
          ),
        ),
      ],
    );
  }

  // قسم آخر البطاقات المحصلة Recent Cards
  Widget buildRecentCardsSection(Size size, AppLocalizations tr) {
    final cardCollectionManager = ref.watch(cardsCollectionProvider);
    final ownedCards = cardCollectionManager.allMyOwnedCards;

    // جلب أحدث 6 بطاقات فقط (أو العدد المتاح إذا كان أقل من 6)
    final recentCards = ownedCards.take(6).toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr.profile_recent_cards,
              style: GoogleFonts.cinzel(
                color: const Color(0xFFCBB26A),
                fontSize: AppDimensions.font(size, 10),
                fontWeight: FontWeight.bold,
              ),
            ),
            AnimatedClickable(
              onTap: () {
                context.push(
                  AppRoutes.cardList,
                  extra: CardDetailsSource.profile,
                );
              },
              child: Text(
                tr.profile_view_all,
                style: GoogleFonts.cinzel(
                  color: const Color(0xFFA78BFA),
                  fontSize: AppDimensions.font(size, 9),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppDimensions.height(size, 8)),
        SizedBox(
          height: AppDimensions.height(size, 100),
          child: recentCards.isEmpty
              ? Center(
                  child: Text(
                    tr.profile_no_cards_yet,
                    style: GoogleFonts.cinzel(
                      color: Colors.grey,
                      fontSize: AppDimensions.font(size, 10),
                    ),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: recentCards.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(width: AppDimensions.width(size, 8)),
                  itemBuilder: (context, index) {
                    final card = recentCards[index].card;
                    final imageUrl = card.imageUrl;

                    return Container(
                      width: AppDimensions.width(size, 68),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.width(size, 6),
                        ),
                        border: Border.all(color: const Color(0xFF3B2D54)),
                        color: const Color(0xFF0F0B1A),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.width(size, 5),
                        ),
                        child: (imageUrl != null && imageUrl.isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: ApiConstants.baseImagesUrl + imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(
                                  child: SizedBox(
                                    width: AppDimensions.width(size, 16),
                                    height: AppDimensions.width(size, 16),
                                    child: CircularProgressIndicator(
                                      strokeWidth: AppDimensions.width(size, 2),
                                      color: const Color(0xFF8B5CF6),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Center(
                                  child: Icon(
                                    Icons.style,
                                    color: Colors.purple,
                                    size: AppDimensions.icon(size, 20),
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.style,
                                  color: Colors.purple,
                                  size: AppDimensions.icon(size, 20),
                                ),
                              ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // زر تغيير الصورة الرمزية Change Avatar
  Widget buildChangeAvatarButton(Size size, AppLocalizations tr) {
    return AnimatedClickable(
      onTap: () {
        context.push(AppRoutes.avatarManagement);
      },
      child: KiroFrame(
        frameImage: "assets/images/auth/kiro_button_frame.png",
        width: AppDimensions.width(size, 300),
        height: AppDimensions.height(size, 60),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/global/profile.png",
              width: AppDimensions.icon(size, 30),
            ),
            SizedBox(width: AppDimensions.width(size, 8)),
            Text(
              tr.profile_btn_change_avatar,
              style: GoogleFonts.cinzel(
                color: Colors.white,
                fontSize: AppDimensions.font(size, 12),
                fontWeight: FontWeight.bold,
                letterSpacing: AppDimensions.width(size, 1.5),
              ),
            ),
            SizedBox(width: AppDimensions.width(size, 8)),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: AppDimensions.icon(size, 12),
            ),
          ],
        ),
      ),
    );
  }

  // شبكة معلومات الحساب الإضافية (اللغة، معرف اللاعب، تاريخ الانضمام، الدعم، الإعدادات)
  Widget buildAccountInfoGrid(Size size, AppLocalizations tr) {
    final supportManager = ref.watch(supportRequestsRespondedCountProvider);

    final supportResponsesCount = supportManager.respondedCount;

    final user = ref.watch(userProvider.notifier).currentUser;

    return Container(
      padding: EdgeInsets.symmetric(vertical: AppDimensions.height(size, 12)),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0816).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppDimensions.width(size, 8)),
        border: Border.all(color: const Color(0xFF2A1C42)),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoGridItem(
              tr.profile_info_language,
              tr.profile_current_language,
              "assets/images/profile/lang_icon.png",
              size,
            ),
            _buildDivider(size),
            _buildInfoGridItem(
              tr.profile_info_player_id,
              user?.username != null ? user!.username! : "",
              "assets/images/profile/id_icon.png",
              size,
            ),
            _buildDivider(size),
            _buildInfoGridItem(
              tr.profile_info_joined,
              user?.createdAt != null
                  ? '${user?.createdAt!.day.toString().padLeft(2, '0')}/'
                        '${user?.createdAt!.month.toString().padLeft(2, '0')}/'
                        '${user?.createdAt!.year}'
                  : '-',
              "assets/images/profile/calunder_icon.png",
              size,
            ),
            _buildDivider(size),
            _buildInfoGridItem(
              tr.profile_info_support,
              "",
              "assets/images/profile/support_icon.png",
              size,
            ),
            _buildDivider(size),
            AnimatedClickable(
              onTap: () {
                context.push(AppRoutes.settings);
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildInfoGridItem(
                    tr.profile_info_settings,
                    "",
                    "assets/images/profile/setting_icon.png",
                    size,
                  ),

                  if (supportResponsesCount > 0)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$supportResponsesCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: AppDimensions.font(size, 8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGridItem(
    String label,
    String value,
    String imagePath,
    Size size,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          imagePath,
          width: AppDimensions.icon(size, 30),
          height: AppDimensions.icon(size, 30),
        ),
        SizedBox(height: AppDimensions.height(size, 4)),
        Text(
          label,
          style: GoogleFonts.cinzel(
            color: Colors.grey,
            fontSize: AppDimensions.font(size, 7.5),
          ),
        ),
        if (value.isNotEmpty) ...[
          SizedBox(height: AppDimensions.height(size, 2)),
          Text(
            value,
            style: GoogleFonts.cinzel(
              color: Colors.white,
              fontSize: AppDimensions.font(size, 8.5),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}
