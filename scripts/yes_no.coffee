# Description:
#   Answer yes no questions.
#
# Commands:
#   hubot is/are/do/does/will/can/should/would/could _______?

module.exports = (robot) ->
  robot.respond /(is|are|was|were|do|does|did|will|can|should|would|could)\s.*\?$/i, (msg) ->
    if Math.random() < .5
      msg.send "Yes!"
    else
      msg.send "No!"

