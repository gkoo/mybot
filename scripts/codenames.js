/* globals module */
// Description:
//   Codenames word game
//
// Dependencies:
//   None
//
// Configuration:
//   None
//
// Commands:
//   Hubot new codenames game - start a game
//
// Authors:
//   gordon

var Codenames = {
  Colors: {
    COLOR_BLUE: 0,
    COLOR_RED: 1,
    COLOR_BLACK: 2,
    COLOR_BROWN: 3
  },

  Game: function() {
    "use strict";

    this.players = {};

    this.STATE_INACTIVE = 0;
    this.STATE_PREGAME = 1;
    this.STATE_GAME = 1;

    this.newGame = function() {
      if (this.state !== this.STATE_INACTIVE) {
        throw "Couldn't start a new game because there is already a game in progress.";
      }

      this.state = this.STATE_PREGAME;
      this.players = {};
    };

    this.start = function(msg, robot) {
      var _this = this;
      if (this.state !== this.STATE_PREGAME) {
        throw "Something went wrong, expected state " + this.STATE_PREGAME + " but got state " + this.state;
      }
      if (Object.keys(this.players).length < 2) {
        throw "You can't play with less than two players!";
      }

      this.generateTeams(function(teams) {
        var team;
        msg.send("The teams are...");

        team = teams[0];
        msg.send(team.name);
        msg.send(team.players.map(function(teamPlayer) {
          return teamPlayer.handle + (teamPlayer.isSpymaster ? " (spymaster)" : "");
        }).join("\n") + "\n");

        team = teams[1];
        msg.send(team.name);
        msg.send(team.players.map(function(teamPlayer) { return teamPlayer.handle; }).join("\n"));
      });

      this.generateWordPool(function(wordPool) {
        var words = wordPool.getAllWords();
        var generalResponse = "The words are...\n" + words.map(function(word) {
          return word.word;
        }).join("\n");

        var spymasterMessage = "You are the spymaster! Here are your words\n";
        var redList = wordPool.getRedWords();
        var blueList = wordPool.getBlueWords();
        var brownList = wordPool.getBrownWords();
        var blackList = wordPool.getBlackWords();
        var redWords = "RED WORDS:\n" + redList.join("\n");
        var blueWords = "BLUE WORDS:\n" + blueList.join("\n");
        var brownWords = "BLUE WORDS:\n" + brownList.join("\n");
        var blackWords = "BLACK WORDS:\n" + blackList.join("\n");

        var redSpymasterMsg = [spymasterMessage, redWords, blueWords, brownWords, blackWords].join("\n\n");
        var blueSpymasterMsg = [spymasterMessage, blueWords, redWords, brownWords, blackWords].join("\n\n");

        // Normal spies
        msg.send(generalResponse);

        // Red spymaster
        robot.messageRoom(this.teams[0].spymaster.handle, redSpymasterMsg);

        // Blue spymaster
        robot.messageRoom(this.teams[1].spymaster.handle, blueSpymasterMsg);
      });
    };

    this.end = function() {
      this.state = this.STATE_INACTIVE;
    };

    this.inProgress = function() {
      return this.state !== this.STATE_INACTIVE;
    };

    this.generateTeams = function(cb) {
      this.teams = [];
      this.teams.push(new Codenames.Team({ id: 1, color: Codenames.Colors.COLOR_RED, name: "Red Team" }));
      this.teams.push(new Codenames.Team({ id: 2, color: Codenames.Colors.COLOR_BLUE, name: "Blue Team" }));

      // Randomly generate teams
      var playerHandles = Object.keys(this.players);
      var numPlayers = playerHandles.length;
      var maxTeamSize = numPlayers / 2;
      var i;
      var rand;
      var player;

      for (i = 0; i < numPlayers; ++i) {
        player = this.players[playerHandles[i]];
        rand = Math.random();
        if (rand < 0.5 && this.teams[0].getTeamSize() < maxTeamSize) {
          this.teams[0].addPlayer(player);
        } else {
          this.teams[1].addPlayer(player);
        }
      }

      this.teams[0].selectSpymaster();
      //this.team[1].selectSpymaster();

      cb(this.teams);
    };

    this.generateWordPool = function(cb) {
      this.wordPool = new Codenames.WordPool();
      this.wordPool.generateWords();
      cb(this.wordPool);
    };

    this.addPlayer = function(handle) {
      if (this.state === this.STATE_PREGAME) {
        this.players[handle] = new Codenames.Player({
          handle: handle
        });
      } else {
        throw "Couldn't add player because state of game is " + this.state;
      }
    };

    this.getColorName = function(color) {
      switch (color) {
        case Codenames.Colors.COLOR_BLUE:
          return "Blue";
        case Codenames.Colors.COLOR_RED:
          return "Red";
        case Codenames.Colors.COLOR_BROWN:
          return "Brown";
        case Codenames.Colors.COLOR_BLACK:
          return "Black";
      }
    };

    this.getPlayerByHandle = function(handle) {
      return this.players[handle];
    };

    this.state = this.STATE_INACTIVE;
  },

  WordPool: function() {
    "use strict";
    this.getWordsByColor = function(color) {
      return this.words.filter(function(word) {
        return word.color === color;
      });
    };

    this.generateWords = function() {
      var totalRed = 9;
      var totalBlue = 8;
      var totalBlack = 1;
      var numRedRemaining = totalRed;
      var numBlueRemaining = totalBlue;
      var numBlackRemaining = totalBlack;
      var wordChoices = [
        "cross",
        "strike",
        "kangaroo",
        "jack",
        "temple",
        "key",
        "drill",
        "tooth",
        "berlin",
        "atlantis",
        "pole",
        "paper",
        "chair",
        "hawk",
        "calf",
        "hero",
        "mandarin",
        "amazon",
        "glove",
        "well",
        // Here's where I'm adding random words from https://github.com/first20hours/google-10000-english/blob/master/20k.txt
        "video",
        "map",
        "hotel",
        "family",
        "website"
      ];
      var i;
      var numChoices;
      var words = [];
      var currWord;
      var colorRand;
      var color;

      // Pick color words
      for (i = 0, numChoices = wordChoices.length; i < numChoices; ++i) {
        currWord = wordChoices[i];
        colorRand = Math.floor(Math.random() * numChoices);

        if (colorRand < totalBlack && numBlackRemaining > 0) {
          // Assassin word
          --numBlackRemaining;
          color = Codenames.Colors.COLOR_BLACK;
        } else if (colorRand < totalBlack + totalRed && numRedRemaining > 0) {
          // Red word
          --numRedRemaining;
          color = Codenames.Colors.COLOR_RED;
        } else if (colorRand < totalBlack + totalRed + totalBlue && numBlueRemaining > 0) {
          // Blue word
          --numBlueRemaining;
          color = Codenames.Colors.COLOR_BLUE;
        } else {
          // Neutral word
          color = Codenames.Colors.COLOR_BROWN;
        }

        words.push(new Codenames.Word({
          word: currWord,
          color: color
        }));
      }

      this.words = words;
    };

    this.getAllWords = function() {
      return this.words;
    };

    this.getRedWords = function() {
      return this.getWordsByColor(Codenames.Colors.COLOR_RED);
    };

    this.getBlueWords = function() {
      return this.getWordsByColor(Codenames.Colors.COLOR_BLUE);
    };

    this.getBlackWords = function() {
      return this.getWordsByColor(Codenames.Colors.COLOR_BLACK);
    };

    this.getBrownWords = function() {
      return this.getWordsByColor(Codenames.Colors.COLOR_BROWN);
    };
  },

  Word: function(opt) {
    "use strict";
    this.word = opt.word;
    this.color = opt.color;
    this.discovered = false;
  },

  Team: function(opt) {
    "use strict";
    this.id = opt.id;
    this.name = opt.name;
    this.players = [];
    this.addPlayer = function(player) { this.players.push(player); };
    this.getTeamSize = function() { return this.players.length; };
    this.selectSpymaster = function(player) {
      if (player) {
        this.spymaster = player;
      }
      else {
        // Choose a random spymaster
        this.spymaster = this.players[Math.floor(Math.random() * this.getTeamSize())];
      }
      this.spymaster.isSpymaster = true;
    };
  },

  Player: function(opt) {
    "use strict";
    this.handle = opt.handle;
    this.name = opt.name;
    this.team = opt.team;
    this.isSpymaster = false;
  }
};

module.exports = function(robot) {
  "use strict";

  // the game "singleton". yuck.
  var game = new Codenames.Game();
  //var roomName = "codenames";
  var roomName = "Shell";

  robot.respond(/new codenames game/i, function(msg) {
    if (msg.envelope.room !== roomName) {
      return msg.send("Please join #codenames.");
    }
    if (game.inProgress()) {
      return msg.send("There is already a game in progress. Either finish the game or end it " +
          "by typing '" + robot.name + " end codenames game'.");
    }

    if (!game.inProgress()) {
      game.newGame();
      msg.send("Who's in? Respond with :hand:. When everyone's in, type '" + robot.name + " everyone's in'");
    }
  });

  robot.respond(/end codenames game/i, function(msg) {
    if (msg.envelope.room !== roomName) {
      msg.send("Please join #codenames to end a game");
      return;
    }

    game.end();
  });

  robot.hear(/^:hand:$/i, function(msg) {
    if (msg.envelope.room === roomName) {
      try {
        game.addPlayer(msg.message.user.name);
      } catch (e) {
        msg.send(e);
      }
    }
  });

  robot.respond(/(who's|who is) playing/i, function(msg) {
    var response = "";
    if (msg.envelope.room === roomName) {
      if (game.inProgress()) {
        response += "Here's a list of who's playing:";
        Object.keys(game.players).forEach(function(playerHandle) {
          response += "\n" + playerHandle;
        });
        msg.send(response);
      }
      else {
        msg.send("There's no game in progress right now! To start a game, type '" + robot.name + " new codenames game'");
      }
    }
  });

  robot.respond(/everyone's in/i, function(msg) {
    try {
      game.start(msg, robot);
    } catch (e) {
      msg.send(e);
    }
  });
};

