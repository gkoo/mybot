/* A way to interact with the Google Images API.
 *
 * s/<first>/<second> - replaces any instances of `first` with `second` in the most recent messages
 */
module.exports = function(robot) {
  var substitute_re = /^s\/([^/]+?)\/([^/]+)\/?$/,
      key = 'substitute_last_messages';

  robot.hear(/^.*$/, function(msg) {
    var maxMessages = 10,
        room = msg.envelope.room,
        message = msg.match[0],
        lastMsgsByRoom,
        lastMsgs;

    // Make sure we don't go down a recursive rabbithole.
    if (message && !message.match(substitute_re)) {
      lastMsgsByRoom = robot.brain.get(key);

      if (!lastMsgsByRoom) {
        lastMsgsByRoom = {};
      }

      lastMsgs = lastMsgsByRoom[room];

      if (lastMsgs && lastMsgs.length) {
        if (lastMsgs.length === maxMessages) {
          lastMsgs.shift();
        }
        lastMsgs.push(message);
      }
      else {
        lastMsgs = [message];
      }
      lastMsgsByRoom[room] = lastMsgs;

      robot.brain.set(key, lastMsgsByRoom);
    }
  });

  robot.hear(substitute_re, function(msg) {
    var first           = msg.match[1],
        second          = msg.match[2],
        lastMsgsByRoom  = robot.brain.get(key),
        lastMsgs        = lastMsgsByRoom[msg.envelope.room];

    if (lastMsgs && lastMsgs.length) {
      lastMsgs.forEach(function(message) {
        if (message.indexOf(first) >= 0) {
          msg.send(message.replace(new RegExp(first, 'g'), second));
        }
      });
    }
  });
};
