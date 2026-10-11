const crypto =
    require("crypto");

const AppError =
    require("../../core/errors/AppError");

const ERRORS =
    require("../../core/errors/errorCodes");

const {
    translateJson,
} = require("../../core/i18n/json_translate");

class GameEngineService {
    constructor(
        gamesRepository,
        gameSessionsRepository,
        gameRewardsRepository,
        gameUserDailyStatsRepository,
        usersRepository,
        gemTransactionsRepository,
        adsRepository,
        registry,
        db
    ) {
        this.gamesRepo =
            gamesRepository;

        this.sessionsRepo =
            gameSessionsRepository;

        this.rewardsRepo =
            gameRewardsRepository;

        this.dailyStatsRepo =
            gameUserDailyStatsRepository;

        this.usersRepo =
            usersRepository;

        this.gemTransactionsRepo =
            gemTransactionsRepository;

        this.adsRepo =
            adsRepository;

        this.registry =
            registry;

        this.db = db;
    }


    // =========================================================
    // 📺 CHECK GAME ENTRY ADS
    // =========================================================

    async checkEntryAds(
        userId,
        game
    ) {
        const entryAdsRequired =
            Number(
                game.entry_ads_required || 0
            );

        // =======================================================
        // 🟢 NO ADS REQUIRED
        // =======================================================

        if (
            entryAdsRequired <= 0
        ) {
            return {
                allowed: true,

                entry_ads_required: 0,

                ads_rewarded: 0,

                ads_remaining: 0,
            };
        }

        // =======================================================
        // 📅 TODAY
        // =======================================================

        const statDate =
            this.getStatDate();

        // =======================================================
        // 📺 GET TODAY'S AD STATS
        // =======================================================

        const adDailyStats =
            await this.adsRepo.findDailyStats(
                userId,
                statDate
            );

        const adsRewarded =
            Number(
                adDailyStats?.ads_rewarded || 0
            );

        // =======================================================
        // 📊 REMAINING ADS
        // =======================================================

        const adsRemaining =
            Math.max(
                0,
                entryAdsRequired -
                adsRewarded
            );

        // =======================================================
        // 🚫 NOT ENOUGH ADS
        // =======================================================

        if (
            adsRemaining > 0
        ) {
            throw new AppError(
                ERRORS.GAME_ENTRY_ADS_REQUIRED,
                403, {
                    ads_remaining: adsRemaining,
                }
            );
        }

        // =======================================================
        // 🟢 ALLOWED
        // =======================================================

        return {
            allowed: true,

            entry_ads_required: entryAdsRequired,

            ads_rewarded: adsRewarded,

            ads_remaining: 0,
        };
    }

    // =========================================================
    // ▶️ START GAME
    // =========================================================

    async startGame(
        userId,
        gameCode,
        lang
    ) {
        // =======================================================
        // 🎮 GET ACTIVE GAME
        // =======================================================

        const game =
            await this.gamesRepo.findActiveByCode(
                gameCode
            );

        if (!game) {
            throw new AppError(
                ERRORS.GAME_NOT_FOUND,
                404
            );
        }

        // =======================================================
        // 📺 CHECK ENTRY ADS
        // =======================================================

        await this.checkEntryAds(
            userId,
            game
        );

        // =======================================================
        // 🧩 GET GAME HANDLER
        // =======================================================

        const handler =
            this.registry.get(
                game.code
            );

        if (!handler) {
            throw new AppError(
                ERRORS.GAME_ENGINE_NOT_FOUND,
                500
            );
        }

        // =======================================================
        // 📊 GET TODAY'S DAILY STATS
        // =======================================================

        const statDate =
            this.getStatDate();

        const dailyStat =
            await this.dailyStatsRepo.findByGameUserDate(
                game.id,
                userId,
                statDate
            );

        // =======================================================
        // 🎁 GET ACTIVE REWARDS
        // =======================================================

        const rewards =
            await this.rewardsRepo.findActiveByGame(
                game.id
            );

        // =======================================================
        // 🔐 GENERATE SESSION ID
        // =======================================================

        const sessionId =
            crypto.randomUUID();

        // =======================================================
        // 🎮 START GAME-SPECIFIC LOGIC
        // =======================================================

        const gameStart =
            await handler.start({
                game,
                userId,
                sessionId,
            });

        // =======================================================
        // 🕐 START TIME
        // =======================================================

        const startedAt =
            new Date();

        // =======================================================
        // 💾 CREATE SESSION
        // =======================================================

        const session =
            await this.sessionsRepo.create({
                game_id: game.id,
                user_id: userId,
                session_id: sessionId,

                seed: gameStart.seed ||
                    null,

                started_at: startedAt,

                status: "started",

                score: 0,

                reward_gems: 0,

                reward_status: "none",
            });

        // =======================================================
        // 🎁 PUBLIC REWARDS
        // =======================================================

        const publicRewards =
            rewards.map((reward) => ({
                score_threshold: reward.score_threshold,

                reward_type: reward.reward_type,

                reward_amount: reward.reward_amount,
            }));

        // =======================================================
        // 📦 RESPONSE
        // =======================================================

        return {
            session_id: session.session_id,

            game: {
                id: game.id,

                code: game.code,

                name: translateJson(
                    game.name,
                    lang
                ),

                config: game.config,
            },

            seed: gameStart.seed ||
                null,

            data: gameStart.data ||
                null,

            rewards: publicRewards,

            // =====================================================
            // 📊 TODAY'S PROGRESS
            // =====================================================

            daily_gems_earned: Number(
                dailyStat?.gems_earned || 0
            ),

            daily_best_score: Number(
                dailyStat?.best_score || 0
            ),

            max_daily_gems: Number(
                game.max_daily_gems || 0
            ),

            started_at: session.started_at,
        };
    }

    // =========================================================
    // 🔍 GET SESSION
    // =========================================================

    async getSession(
        userId,
        sessionId
    ) {
        const session =
            await this.sessionsRepo.findUserSession(
                userId,
                sessionId
            );

        if (!session) {
            throw new AppError(
                ERRORS.GAME_SESSION_NOT_FOUND,
                404
            );
        }

        return session;
    }

    // =========================================================
    // 🔎 VERIFY
    // =========================================================
    //
    // Verification does NOT grant reward.
    //
    // It only validates the game result.
    //
    // =========================================================

    async verifyGame(
        userId,
        sessionId,
        payload
    ) {
        const session =
            await this.sessionsRepo.findUserSession(
                userId,
                sessionId
            );

        if (!session) {
            throw new AppError(
                ERRORS.GAME_SESSION_NOT_FOUND,
                404
            );
        }

        if (
            session.status !==
            "started"
        ) {
            throw new AppError(
                ERRORS.GAME_SESSION_NOT_ACTIVE,
                400
            );
        }

        const game =
            await this.gamesRepo.findById(
                session.game_id
            );

        if (!game) {
            throw new AppError(
                ERRORS.GAME_NOT_FOUND,
                404
            );
        }

        const handler =
            this.registry.get(
                game.code
            );

        if (!handler) {
            throw new AppError(
                ERRORS.GAME_ENGINE_NOT_FOUND,
                500
            );
        }

        const verification =
            await handler.verify({
                game,
                session,
                payload,
            });

        if (
            !verification.valid
        ) {
            await this.sessionsRepo.invalidate(
                session.id, {
                    result: verification.result ||
                        null,
                }
            );

            throw new AppError(
                ERRORS.GAME_RESULT_INVALID,
                400
            );
        }

        return {
            valid: true,

            score: verification.score,

            result: verification.result ||
                null,
        };
    }

    // =========================================================
    // 🏁 COMPLETE GAME
    // =========================================================

    async completeGame(
        userId,
        sessionId,
        payload
    ) {
        return this.db.transaction(
            async (trx) => {

                // ===================================================
                // 1️⃣ LOCK SESSION
                // ===================================================

                const session =
                    await this.sessionsRepo
                    .findUserSessionForUpdate(
                        userId,
                        sessionId,
                        trx
                    );

                if (!session) {
                    throw new AppError(
                        ERRORS.GAME_SESSION_NOT_FOUND,
                        404
                    );
                }

                if (
                    session.status !==
                    "started"
                ) {
                    throw new AppError(
                        ERRORS.GAME_SESSION_NOT_ACTIVE,
                        400
                    );
                }

                // ===================================================
                // 2️⃣ GAME
                // ===================================================

                const game =
                    await this.gamesRepo.findById(
                        session.game_id,
                        trx
                    );

                if (!game) {
                    throw new AppError(
                        ERRORS.GAME_NOT_FOUND,
                        404
                    );
                }

                const handler =
                    this.registry.get(
                        game.code
                    );

                if (!handler) {
                    throw new AppError(
                        ERRORS.GAME_ENGINE_NOT_FOUND,
                        500
                    );
                }

                // ===================================================
                // 3️⃣ VERIFY RESULT
                // ===================================================

                const verification =
                    await handler.verify({
                        game,
                        session,
                        payload,
                    });

                if (
                    !verification.valid
                ) {
                    await this.sessionsRepo.invalidate(
                        session.id, {
                            score: verification.score ||
                                0,

                            result: verification.result ||
                                null,
                        },
                        trx
                    );

                    throw new AppError(
                        ERRORS.GAME_RESULT_INVALID,
                        400
                    );
                }

                const score =
                    Number(
                        verification.score || 0
                    );

                // ===================================================
                // 4️⃣ DAILY STAT
                // ===================================================

                const statDate =
                    this.getStatDate();

                const dailyStat =
                    await this.dailyStatsRepo
                    .getOrCreateDailyStatForUpdate(
                        game.id,
                        userId,
                        statDate,
                        trx
                    );

                // ===================================================
                // 5️⃣ CALCULATE REWARD
                // ===================================================

                const reward =
                    await this.calculateReward({
                        game,
                        score,
                        dailyStat,
                        trx,
                    });

                // ===================================================
                // 6️⃣ UPDATE SESSION
                // ===================================================

                const finishedAt =
                    new Date();

                const durationMs =
                    finishedAt.getTime() -
                    new Date(
                        session.started_at
                    ).getTime();

                await this.sessionsRepo.complete(
                    session.id, {
                        finished_at: finishedAt,

                        score,

                        duration_ms: durationMs,

                        result: verification.result ||
                            null,

                        reward_gems: reward.gems,

                        reward_status: reward.gems > 0 ?
                            "granted" :
                            "none",
                    },
                    trx
                );

                // ===================================================
                // 7️⃣ UPDATE DAILY STAT
                // ===================================================

                await this.dailyStatsRepo
                    .recordPlayWithGems(
                        dailyStat.id,
                        score,
                        reward.gems,
                        trx
                    );

                // ===================================================
                // 8️⃣ ADD GEMS
                // ===================================================

                let updatedUser = null;

                if (
                    reward.gems > 0
                ) {
                    updatedUser =
                        await this.usersRepo.addGems(
                            userId,
                            reward.gems,
                            trx
                        );

                    const balanceAfter =
                        Number(
                            updatedUser.gems || 0
                        );

                    await this.gemTransactionsRepo.create({
                            user_id: userId,

                            amount: reward.gems,

                            type: "add",

                            reason: "game_reward",

                            reference_id: session.id,

                            balance_after: balanceAfter,
                        },
                        trx
                    );
                }

                // ===================================================
                // 9️⃣ RETURN
                // ===================================================

                return {
                    session_id: session.session_id,

                    status: "completed",

                    score,

                    reward_gems: reward.gems,

                    reward_details: reward.details,

                    daily_gems_earned: Number(
                            dailyStat.gems_earned || 0
                        ) +
                        reward.gems,

                    max_daily_gems: Number(
                        game.max_daily_gems || 0
                    ),

                    result: verification.result ||
                        null,
                };
            }
        );
    }

    // =========================================================
    // 💎 CALCULATE REWARD
    // =========================================================

    async calculateReward({
        game,
        score,
        dailyStat,
        trx,
    }) {
        const maxDailyGems =
            Number(
                game.max_daily_gems || 0
            );

        // =======================================================
        // 🚫 NO DAILY LIMIT
        // =======================================================

        if (
            maxDailyGems <= 0
        ) {
            return {
                gems: 0,
                details: [],
            };
        }

        // =======================================================
        // 💎 CURRENT DAILY GEMS
        // =======================================================

        const currentDailyGems =
            Number(
                dailyStat.gems_earned || 0
            );

        // =======================================================
        // 💎 REMAINING DAILY GEMS
        // =======================================================

        const remaining =
            Math.max(
                0,
                maxDailyGems -
                currentDailyGems
            );

        // =======================================================
        // 🚫 DAILY LIMIT REACHED
        // =======================================================

        if (
            remaining <= 0
        ) {
            return {
                gems: 0,
                details: [],
            };
        }

        // =======================================================
        // 📊 PREVIOUS BEST SCORE
        // =======================================================

        const previousBestScore =
            Number(
                dailyStat.best_score || 0
            );

        // =======================================================
        // 🚫 SCORE DID NOT IMPROVE
        // =======================================================
        //
        // User must beat his previous best score
        // to unlock new rewards.
        //
        // =======================================================

        if (
            score <=
            previousBestScore
        ) {
            return {
                gems: 0,
                details: [],
            };
        }

        // =======================================================
        // 🎁 GET ACTIVE REWARDS
        // =======================================================

        const rewards =
            await this.rewardsRepo.findActiveByGame(
                game.id
            );

        let totalReward = 0;

        const details = [];

        // =======================================================
        // 🎯 ONLY NEW THRESHOLDS
        // =======================================================

        for (
            const reward of rewards
        ) {
            const threshold =
                Number(
                    reward.score_threshold
                );

            const amount =
                Number(
                    reward.reward_amount
                );

            // Reward is granted only when:
            //
            // previousBestScore < threshold <= new score
            //
            if (
                previousBestScore <
                threshold &&
                score >=
                threshold
            ) {
                totalReward +=
                    amount;

                details.push({
                    reward_id: reward.id,

                    score_threshold: threshold,

                    reward_type: reward.reward_type,

                    reward_amount: amount,
                });
            }
        }

        // =======================================================
        // 🛑 RESPECT DAILY GEM LIMIT
        // =======================================================

        totalReward =
            Math.min(
                totalReward,
                remaining
            );

        // =======================================================
        // 📦 RESULT
        // =======================================================

        return {
            gems: totalReward,

            details,
        };
    }

    // =========================================================
    // ⛔ ABANDON GAME
    // =========================================================

    async abandonGame(
        userId,
        sessionId
    ) {
        const session =
            await this.sessionsRepo.findUserSession(
                userId,
                sessionId
            );

        if (!session) {
            throw new AppError(
                ERRORS.GAME_SESSION_NOT_FOUND,
                404
            );
        }

        if (
            session.status !==
            "started"
        ) {
            throw new AppError(
                ERRORS.GAME_SESSION_NOT_ACTIVE,
                400
            );
        }

        return this.sessionsRepo.abandon(
            session.id, {
                finished_at: new Date(),
            }
        );
    }

    // =========================================================
    // 📅 STAT DATE
    // =========================================================

    getStatDate() {
        const now =
            new Date();

        return now
            .toISOString()
            .slice(0, 10);
    }
}

module.exports =
    GameEngineService;