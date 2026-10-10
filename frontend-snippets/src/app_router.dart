import 'package:go_router/go_router.dart';
import 'package:kiro/features/account/email/presentation/email_page.dart';
import 'package:kiro/features/account/security/presentation/security_page.dart';
import 'package:kiro/features/app_version/data/models/app_version_model.dart';
import 'package:kiro/features/app_version/presentation/app_version_page.dart';
import 'package:kiro/features/auth/register/presentation/register_page.dart';
import 'package:kiro/features/auth/reset_password/presentation/reset_password_page.dart';
import 'package:kiro/features/card/presentation/burn_card/burn_card_page.dart';
import 'package:kiro/features/card/presentation/card_list/card_list_page.dart';
import 'package:kiro/features/games/block_puzzle/presentation/block_puzzle_page.dart';
import 'package:kiro/features/games/data/models/game_model.dart';
import 'package:kiro/features/marketplace/data/models/marketplace_listing_model.dart';
import 'package:kiro/features/marketplace/listing/presentation/listing_details_page.dart';
import 'package:kiro/features/marketplace/sell/presentation/sell_card_page.dart';
import 'package:kiro/features/open_pack/open_pack/presentation/open_pack_page.dart';
import 'package:kiro/features/public_profile/presentation/public_profile_page.dart';
import 'package:kiro/features/scan_pack/presentation/scan_pack_page.dart';
import 'package:kiro/features/support/data/models/support_request_model.dart';
import 'package:kiro/features/support/presentation/contact_support/create_request/create_request_page.dart';
import 'package:kiro/features/support/presentation/contact_support/overview/contact_support_page.dart';
import 'package:kiro/features/support/presentation/contact_support/request_details/request_details_page.dart';
import 'package:kiro/features/support/presentation/contact_support/requests/requests_page.dart';
import 'package:kiro/features/support/presentation/help_center/help_center_page.dart';
import 'package:kiro/features/support/presentation/privacy_policy/privacy_policy_page.dart';
import 'package:kiro/features/support/presentation/terms_of_service/terms_of_service_page.dart';
import 'package:kiro/shared/models/card_model.dart';

import '../../features/auth/login/presentation/login_page.dart';
import '../../features/avatar/management/presentation/avatar_management_page.dart';
import '../../features/avatar/selection/presentation/avatar_selection_page.dart';
import '../../features/card/presentation/card_details/card_details_page.dart';
import '../../features/collection/presentation/collection_details/collection_details_page.dart';
import '../../features/earn_gems/presentation/earn_gems_page.dart';
import '../../features/games/match_three/presentation/match_three_page.dart';
import '../../features/main_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

import '../../shared/enums/Card_details_source.dart';
import '../../shared/models/collection_card_model.dart';
import '../../shared/models/collection_model.dart';
import 'app_constants_routes.dart';

// استيراد ملف الـ Transitions الجديد
import 'app_page_transitions.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      // السبلَاش تفتح بالـ Fade الهادئ
      pageBuilder: (context, state) =>
          FadeTransitionPage(key: state.pageKey, child: const SplashPage()),
    ),

    GoRoute(
      path: AppRoutes.updateApp, // مسار ثابت نظيف
      pageBuilder: (context, state) {
        // استقبال الرابط بأمان من الـ extra
        final appVersion = state.extra as AppVersionModel;

        return FadeTransitionPage(
          key: state.pageKey,
          child: AppVersionPage(appVersion: appVersion),
        );
      },
    ),

    GoRoute(
      path: AppRoutes.login,
      // صفحة تسجيل الدخول تنزلق من الأسفل إلى الأعلى مثلاً
      pageBuilder: (context, state) =>
          SlideUpTransitionPage(key: state.pageKey, child: const LoginPage()),
    ),

    GoRoute(
      path: AppRoutes.home,
      // الـ Home تفتح بـ Fade أو تأثير آخر مريح للعين
      pageBuilder: (context, state) =>
          FadeTransitionPage(key: state.pageKey, child: const MainPage()),
    ),

    GoRoute(
      path: AppRoutes.register,
      // صفحة التسجيل تنزلق من اليمين إلى اليسار (كأنها شاشة تالية)
      pageBuilder: (context, state) => SlideDownTransitionPage(
        key: state.pageKey,
        child: const RegisterPage(),
      ),
    ),

    GoRoute(
      path: AppRoutes.resetPassword,
      // صفحة التسجيل تنزلق من اليمين إلى اليسار (كأنها شاشة تالية)
      pageBuilder: (context, state) => SlideDownTransitionPage(
        key: state.pageKey,
        child: const ResetPasswordPage(),
      ),
    ),

    GoRoute(
      path: AppRoutes.selectionAvatar,
      // صفحة التسجيل تنزلق من اليمين إلى اليسار (كأنها شاشة تالية)
      pageBuilder: (context, state) => SlideLeftTransitionPage(
        key: state.pageKey,
        child: const AvatarSelectionPage(),
      ),
    ),

    GoRoute(
      path: AppRoutes.scanPack,
      // صفحة التسجيل تنزلق من اليمين إلى اليسار (كأنها شاشة تالية)
      pageBuilder: (context, state) => SlideUpTransitionPage(
        key: state.pageKey,
        child: const ScanPackPage(),
      ),
    ),

    GoRoute(
      path: AppRoutes.openPack, // مسار ثابت نظيف
      pageBuilder: (context, state) {
        // استقبال الرابط بأمان من الـ extra
        final card = state.extra as CardModel;

        return FadeTransitionPage(
          key: state.pageKey,
          child: OpenPackPage(card: card),
        );
      },
    ),

    GoRoute(
      path: AppRoutes.cardDetails,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;

        return FadeTransitionPage(
          key: state.pageKey,
          child: CardDetailsPage(
            card: extra['card'] as CardModel,
            source: extra['source'] as CardDetailsSource,
          ),
        );
      },
    ),

    GoRoute(
      path: AppRoutes.collectionList,
      pageBuilder: (context, state) {
        return SlideRightTransitionPage(
          key: state.pageKey,
          child: const MainPage(),
        );
      },
    ),

    GoRoute(
      path: AppRoutes.collectionDetails,
      pageBuilder: (context, state) {
        final collection = state.extra as CollectionModel;

        return SlideLeftTransitionPage(
          key: state.pageKey,
          child: CollectionDetailsPage(collection: collection),
        );
      },
    ),

    GoRoute(
      path: AppRoutes.profile,
      pageBuilder: (context, state) =>
          SlideDownTransitionPage(key: state.pageKey, child: const MainPage()),
    ),

    GoRoute(
      path: AppRoutes.settings,
      pageBuilder: (context, state) => SlideUpTransitionPage(
        key: state.pageKey,
        child: const SettingsPage(),
      ),
    ),

    GoRoute(
      path: AppRoutes.security,
      pageBuilder: (context, state) => SlideDownTransitionPage(
        key: state.pageKey,
        child: const SecurityPage(),
      ),
    ),

    GoRoute(
      path: AppRoutes.email,
      pageBuilder: (context, state) =>
          SlideUpTransitionPage(key: state.pageKey, child: const EmailPage()),
    ),

    GoRoute(
      path: AppRoutes.avatarManagement,
      pageBuilder: (context, state) => FadeTransitionPage(
        key: state.pageKey,
        child: const AvatarManagementPage(),
      ),
    ),

    GoRoute(
      path: AppRoutes.marketplace,
      pageBuilder: (context, state) =>
          FadeTransitionPage(key: state.pageKey, child: const MainPage()),
    ),

    GoRoute(
      path: AppRoutes.marketplaceListing, // مسار ثابت نظيف
      pageBuilder: (context, state) {
        // استقبال الرابط بأمان من الـ extra
        final listing = state.extra as MarketplaceListingModel;

        return FadeTransitionPage(
          key: state.pageKey,
          child: ListingDetailsPage(listing: listing),
        );
      },
    ),

    GoRoute(
      path: AppRoutes.cardList, // مسار ثابت نظيف
      pageBuilder: (context, state) {
        // استقبال الرابط بأمان من الـ extra
        final source = state.extra as CardDetailsSource;

        return FadeTransitionPage(
          key: state.pageKey,
          child: CardListPage(source: source),
        );
      },
    ),

    GoRoute(
      path: AppRoutes.marketplaceSell,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;

        return FadeTransitionPage(
          key: state.pageKey,
          child: SellCardPage(
            collectionCard: extra['collectionCard'] as CollectionCardModel,

            listing: extra['listing'] as MarketplaceListingModel?,
          ),
        );
      },
    ),

    GoRoute(
      path: AppRoutes.cardBurn, // مسار ثابت نظيف
      pageBuilder: (context, state) {
        // استقبال الرابط بأمان من الـ extra
        final collectionCard = state.extra as CollectionCardModel;

        return FadeTransitionPage(
          key: state.pageKey,
          child: BurnCardPage(collectionCard: collectionCard),
        );
      },
    ),

    GoRoute(
      path: AppRoutes.earnGems,
      pageBuilder: (context, state) =>
          FadeTransitionPage(key: state.pageKey, child: const EarnGemsPage()),
    ),

    GoRoute(
      path: AppRoutes.leaderboard,
      pageBuilder: (context, state) {
        return SlideRightTransitionPage(
          key: state.pageKey,
          child: const MainPage(),
        );
      },
    ),

    GoRoute(
      path: AppRoutes.helpCenter,
      pageBuilder: (context, state) {
        final startIndex = state.extra as int?;

        return SlideRightTransitionPage(
          key: state.pageKey,
          child: HelpCenterPage(startExpandedCategoryIndex: startIndex),
        );
      },
    ),

    GoRoute(
      path: AppRoutes.privacyPolicy,
      pageBuilder: (context, state) {
        return SlideRightTransitionPage(
          key: state.pageKey,
          child: const PrivacyPolicyPage(),
        );
      },
    ),

    GoRoute(
      path: AppRoutes.termsOfService,
      pageBuilder: (context, state) {
        return SlideRightTransitionPage(
          key: state.pageKey,
          child: const TermsOfServicePage(),
        );
      },
    ),

    GoRoute(
      path: AppRoutes.contactSupport,
      pageBuilder: (context, state) {
        return SlideRightTransitionPage(
          key: state.pageKey,
          child: const ContactSupportPage(),
        );
      },
    ),

    GoRoute(
      path: AppRoutes.createSupportRequest,
      pageBuilder: (context, state) {
        return SlideRightTransitionPage(
          key: state.pageKey,
          child: const CreateRequestPage(),
        );
      },
    ),

    GoRoute(
      path: AppRoutes.supportRequests,
      pageBuilder: (context, state) {
        return SlideRightTransitionPage(
          key: state.pageKey,
          child: const RequestsPage(),
        );
      },
    ),

    GoRoute(
      path: AppRoutes.supportRequestDetails, // مسار ثابت نظيف
      pageBuilder: (context, state) {
        // استقبال الرابط بأمان من الـ extra
        final request = state.extra as SupportRequestModel;

        return FadeTransitionPage(
          key: state.pageKey,
          child: RequestDetailsPage(request: request),
        );
      },
    ),

    GoRoute(
      path: AppRoutes.publicProfile, // مسار ثابت نظيف
      pageBuilder: (context, state) {
        // استقبال الرابط بأمان من الـ extra
        final userId = state.extra as int;

        return FadeTransitionPage(
          key: state.pageKey,
          child: PublicProfilePage(userId: userId),
        );
      },
    ),

    GoRoute(
      path: AppRoutes.blockPuzzle, // مسار ثابت نظيف
      pageBuilder: (context, state) {
        // استقبال الرابط بأمان من الـ extra
        final game = state.extra as GameModel;

        return FadeTransitionPage(
          key: state.pageKey,
          child: BlockPuzzlePage(game: game),
        );
      },
    ),

    GoRoute(
      path: AppRoutes.matchThree, // مسار ثابت نظيف
      pageBuilder: (context, state) {
        // استقبال الرابط بأمان من الـ extra
        final game = state.extra as GameModel;

        return FadeTransitionPage(
          key: state.pageKey,
          child: MatchThreePage(game: game),
        );
      },
    ),
  ],
);
