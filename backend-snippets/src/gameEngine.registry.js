const MemoryGame =
  require("./games/memory");

const PuzzleGame =
  require("./games/block_puzzle");

const MatchThreeGame =
  require("./games/match_three");

class GameEngineRegistry {
  constructor() {
    this.games = new Map();

    this.register(
      MemoryGame
    );

    this.register(
      PuzzleGame
    );

    this.register(
      MatchThreeGame
    );
  }

  // =========================================================
  // ➕ REGISTER GAME
  // =========================================================

  register(game) {
    if (!game?.code) {
      throw new Error(
        "GAME_CODE_REQUIRED"
      );
    }

    if (
      typeof game.start !==
      "function"
    ) {
      throw new Error(
        "GAME_START_HANDLER_REQUIRED"
      );
    }

    if (
      typeof game.verify !==
      "function"
    ) {
      throw new Error(
        "GAME_VERIFY_HANDLER_REQUIRED"
      );
    }

    this.games.set(
      game.code,
      game
    );
  }

  // =========================================================
  // 🔍 GET GAME
  // =========================================================

  get(code) {
    return this.games.get(code);
  }

  // =========================================================
  // ❓ EXISTS
  // =========================================================

  has(code) {
    return this.games.has(code);
  }

  // =========================================================
  // 📋 ALL
  // =========================================================

  all() {
    return Array.from(
      this.games.values()
    );
  }
}

module.exports =
  new GameEngineRegistry();