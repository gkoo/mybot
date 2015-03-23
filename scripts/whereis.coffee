# Description
#   Script for locating friends
#
# Commands:
#   hubot where is <name>? - gets location of a friend
#   hubot i am <location descriptor> - saves your location
#
# Dependencies:
#   "underscore": "*"
module.exports = (robot) ->
  robot.respond /i am (.+)/i, (msg) ->
    screenname = msg.message.user.name.toLowerCase()
    location = msg.match[1]
    robot.brain.data["#{screenname}Location"] = location
    msg.send "Okay, I'll remember that you are #{location}"

  robot.respond /where is (.+)\??/i, (msg) ->
    name = msg.match[1]
    if name == 'gordon'
      screenname = 'gkoo'
    else
      screenname = name.toLowerCase()
    location = robot.brain.data["#{screenname}Location"]
    if !location
      msg.send "I don't know!"
    else
      msg.send "#{name} is #{location}"
