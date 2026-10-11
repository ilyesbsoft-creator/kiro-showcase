# KIRO Node.js Backend Architecture & Modules

This document details the backend infrastructure of the **KIRO** project, built with **Node.js, Express.js, MySQL, and Knex.js**. 

The backend follows a strict **Modular Layered Architecture**, providing robust security middleware, multi-language internationalization (`i18n`), centralized transaction handling, and dedicated game engine verification logic.

---

## 🏗️ Complete Backend Directory Tree (`src/`)

```text
src/
│   app.js
│   instrument.js
│   server.js
│
+---core
│   +---constants
│   │       systemRoles.js
│   +---database
│   │       knex.js
│   +---errors
│   │       AppError.js
│   │       errorCodes.js
│   +---i18n
│   │   │   index.js
│   │   │   json_translate.js
│   │   │   translator.js
│   │   │   │
│   │   +---ar / en / fr (Localized JSON dictionaries for system messages & responses)
│   +---middlewares
│   │       auth.middleware.js
│   │       clientIp.middleware.js
│   │       language.middleware.js
│   │       role.middleware.js
│   │       system.auth.middleware.js
│   │       upload.middleware.js
│   │       validate.middleware.js
│   +---sentry
│   │       captureError.js
│   +---services
│       │   cloudinary_service.js
│       │   \---email (Brevo & Email dispatch provider)
│   \---websocket
│           socket.server.js
│
+---jobs
│       cleanupRefreshTokens.js
│
+---loaders
│       modules.loader.js
│
\---modules (Domain-Driven Modules)
    +---ads
    +---app_versions
    +---auth
    +---auth_system
    +---avatars
    +---avatar_engine
    +---cards
    +---collections
    +---collection_rewards
    +---feedback
    +---games
    +---game_engine (Registry, Sessions, Daily Stats & Game Engines: Block Puzzle, Match-Three, Memory)
    +---game_rewards
    +---gem_transactions
    +---leaderboards & leaderboard_entries
    +---marketplace (Listings, Trades, Price controls & Atomic Transactions)
    +---packs & pack_rarities
    +---qr_batches & qr_codes (Batch & QR generation utils)
    +---rarities
    +---rewards & reward_claims (RewardResolverService)
    +---scan_engine & scan_logs
    +---settings
    +---support_requests
    +---users & user_cards
    +---user_collection_progress
    +---user_feedback
    +---user_packs
    \---verification
	
	
	
modules/marketplace/
├── index.js                  # Module router aggregator
├── marketplace.routes.js       # Endpoint URL mappings & middleware bindings
├── marketplace.controller.js   # HTTP request/response handling & status codes
├── marketplace.service.js      # Business logic & Database transaction orchestration
├── marketplace.repository.js   # Knex.js query builders & database data-access layer
└── marketplace.validation.js   # Request payload validation schemas (Joi/Validator)	