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
  Game: function() {
    "use strict";

    this.players = [];

    this.COLOR_BLUE = 0;
    this.COLOR_RED = 1;
    this.COLOR_BLACK = 2;
    this.COLOR_BROWN = 3;

    this.STATE_ACTIVE = 0;
    this.STATE_INACTIVE = 1;

    this.newGame = function() {
      if (this.state === this.STATE_ACTIVE) {
        throw "Couldn't start a new game because there is already a game in progress.";
      }

      this.generateTeams();
      this.generateWords();
      this.state = "active";
    };

    this.endGame = function() {
      this.state = "ended";
    };

    this.generateTeams = function() {
      this.teams = [];
      this.teams.push(new Codenames.Team({ id: 1 }));
      this.teams.push(new Codenames.Team({ id: 2 }));

      // Randomly generate teams
      var numPlayers = this.players.length;
      var maxTeamSize = numPlayers / 2;
      var i;
      var rand;
      var player;

      for (i = 0; i < numPlayers; ++i) {
        player = this.players[i];
        rand = Math.random();
        if (rand < 0.5 && this.teams[0].getTeamSize() < maxTeamSize) {
          this.teams[0].addPlayer(player);
        } else {
          this.teams[1].addPlayer(player);
        }
      }
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
        "tooth"
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
          color = this.COLOR_BLACK;
        } else if (colorRand < totalRed && numRedRemaining > 0) {
          // Red word
          --numRedRemaining;
          color = this.COLOR_RED;
        } else if (colorRand < totalBlue && numBlueRemaining > 0) {
          // Blue word
          --numBlueRemaining;
          color = this.COLOR_BLUE;
        } else {
          // Neutral word
          color = this.COLOR_BROWN;
        }

        words.push(new Codenames.Word({
          word: currWord,
          color: color
        }));
      }

      this.words = words;
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
    this.players = [];
    this.addPlayer = function(player) { this.players.push(player); };
    this.getTeamSize = function() { return this.players.length; };
  },

  Player: function(opt) {
    "use strict";
    this.handle = opt.handle;
    this.name = opt.name;
    this.team = opt.team;
  }
};

module.exports = function(robot) {
  "use strict";

  // the game "singleton". yuck.
  var game = new Codenames.Game();

  robot.hear(/new codenames game/, function(msg) {
    if (msg.envelope.room !== "codenames") {
      msg.send("Please join #codenames to start a game");
      return;
    }

    if (game.state === Codenames.Game.STATE_ACTIVE) {
      msg.send("There is already a game in progress. Either finish the game or end it by typing '" +
               robot.name + " end codenames game'.");
      return;
    }

    if (game.state === Codenames.Game.STATE_INACTIVE) {
      msg.send("Who's in? Respond with :hand:. When everyone's in, type " + robot.name + " everyone's in.");
    }
  });
};

