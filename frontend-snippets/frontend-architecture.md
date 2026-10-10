# KIRO Flutter Frontend Architecture & Directory Structure

This document outlines the clean, modular architecture of the **KIRO** mobile application frontend, built using **Flutter, Dart, Riverpod, Dio, and go_router**. 

The project follows a **Feature-First / Layered Hybrid Architecture**, ensuring high scalability, testability, separation of concerns, and clean state management.

---

## 📂 Complete Project Tree (`lib/`)

```text
lib/
│   ├── main.dart
│   │
+---app
│   │   app.dart
│   │
│   +---constants
│   │       ad_constants.dart
│   │       app_alerts.dart
│   │       app_dimensions.dart
│   │       app_music.dart
│   │
│   +---providers
│   │       ads_provider.dart
│   │       app_theme_provider.dart
│   │       app_version_provider.dart
│   │       avatar_management_provider.dart
│   │       bottom_navigation_provider.dart
│   │       collections_provider.dart
│   │       collection_filter_provider.dart
│   │       collection_reward_provider.dart
│   │       direction_provider.dart
│   │       games_provider.dart
│   │       leaderboard_provider.dart
│   │       locale_provider.dart
│   │       marketplace_sales_count_provider.dart
│   │       marketplace_trades_count_provider.dart
│   │       my_cards_provider.dart
│   │       rarities_provider.dart
│   │       settings_provider.dart
│   │       support_requests_provider.dart
│   │       support_requests_responded_count_provider.dart
│   │       user_feedback_provider.dart
│   │       user_provider.dart
│   │
│   +---router
│       │   app_constants_routes.dart
│       │   app_page_transitions.dart
│       │   app_router.dart
│       │
│   \---theme
│           app_colors.dart
│           app_theme_manager.dart
│           theme_factory.dart
│
+---core
│   +---errors
│   +---exceptions
│   │       api_exception.dart
│   │       api_exception_handler.dart
│   │
│   +---extensions
│       │   color_extensions.dart
│       │
│   +---network
│       │   api_client.dart
│       │   api_constants.dart
│       │   auth_interceptor.dart
│       │   network_interceptor.dart
│       │
│   +---services
│       │   ambient_music_service.dart
│       │   app_data_loader.dart
│       │   audio_manager.dart
│       │   background_music_service.dart
│       │   card_share_service.dart
│       │   device_id_service.dart
│       │   device_info_service.dart
│       │   facebook_auth_service.dart
│       │   google_auth_service.dart
│       │   socket_service.dart
│       │   sound_effect_service.dart
│       │
│   +---session
│       │   session_manager.dart
│       │   session_state_cleaner.dart
│       │
│   +---storage
│       │   audio_storage.dart
│       │   secure_last_read_times_service.dart
│       │   secure_storage_service.dart
│       │
│   +---utils
│       │   api_error_translator.dart
│       │   time_utils.dart
│       │
│       \---validators
│               email_validator.dart
│
+---features
│   │   main_page.dart
│   │
│   +---account (Modular feature: Security, Email, Password management)
│   +---app_version
│   +---auth (Login, Register, Reset Password)
│   +---avatar (Avatar Management & Selection)
│   +---card (Card Details, List, Burn Card & Interactive Widgets: Flip, Glow, 3D)
│   +---collection (Collection tracking & rewards)
│   +---earn_gems (Ads integration & daily rewards)
│   +---games (Mini-games platform: Block Puzzle, Match-Three engines & Verification)
│   +---home (Dashboard, Portals, Daily Packs & Navigation Hub)
│   +---leaderboard
│   +---marketplace (Buying, Selling, Listings, and Trade History)
│   +---open_pack (Pack opening mechanics & particle painters)
│   +---profile & public_profile
│   +---scan_pack (QR/Barcode scanning integration)
│   +---settings
│   +---splash
│   \---support (Help Center, Privacy Policy, Terms, and Contact Support)
│
+---l10n
│       app_ar.arb
│       app_en.arb
│       app_fr.arb
│       app_localizations.dart
│       (Localized delegates for AR, EN, FR)
│
\---shared
    +---dialogs
    +---enums
    +---models (Global Data Entities)
    +---repositories (API data source bridges)
    +---state_managers (State controllers)
    \---widgets (Reusable atomic components & custom frames)