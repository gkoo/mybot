/* globals module */
module.exports = function(robot) {
  "use strict";
  robot.respond(/hello/i, function(msg) {
    msg.send(JSON.stringify(msg.envelope));
    msg.send(JSON.stringify(msg.message));
  });
};
