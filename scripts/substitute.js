// Description:
//   replace text with other text
//
// Dependencies:
//   None
//
// Configuration:
//   None
//
// Commands:
//   Hubot s/<first>/<second> - replaces any instances of `first` with `second` in the most recent messages
//
// AutHors:
//   gordon

var substitute_re = /^s\/([^/]+?)\/([^/]+)\/?$/;
var cachedMessages = {};

function rememberMsg(msg, room) {
  var lastMsgs;
  var maxMessages = 10;

  // Make sure we don't go down a recursive rabbithole.
  if (msg && !msg.match(substitute_re)) {
    lastMsgs = cachedMessages[room];

    if (lastMsgs && lastMsgs.length) {
      if (lastMsgs.length === maxMessages) {
        lastMsgs.shift();
      }
      lastMsgs.push(msg);
    }
    else {
      lastMsgs = [msg];
    }
    cachedMessages[room] = lastMsgs;
  }
}

module.exports = function(robot) {
  robot.hear(/^.*$/, function(msg) {
    rememberMsg(msg.match[0], msg.envelope.room);
  });

  robot.hear(substitute_re, function(msg) {
    var first    = msg.match[1],
        second   = msg.match[2],
        lastMsgs = cachedMessages[msg.envelope.room],
        newMessage;

    if (lastMsgs && lastMsgs.length) {
      lastMsgs.forEach(function(message) {
        if (message.indexOf(first) >= 0) {
          // Let's do some replacin'!
          // prevent replaces from @channeling everyone
          newMessage = message.replace(new RegExp(first, 'g'), second).replace("@", "at-");
          // prevent idiotic spam
          newMessage = newMessage.substring(0, 500);

          msg.send(newMessage);
          rememberMsg(newMessage, msg.envelope.room);
        }
      });
    }
  });
};
