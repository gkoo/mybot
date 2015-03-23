# Description
#   Script for locating Willy
#
# Commands:
#   hubot where is willy? - gets willy's location
#   hubot i am <location descriptor> - if user is willy, saves his location
#
# Dependencies:
#   "underscore": "*"
module.exports = (robot) ->
  robot.respond /i am (.+)/i, (msg) ->
    if msg.message.user.name.toLowerCase() == 'willy'
      robot.brain.data.willyLocation = msg.match[1]

  robot.respond /where is willy\??/i, (msg) ->
    console.log('match! 2')
    willyLocation = robot.brain.data.willyLocation
    if !willyLocation
      msg.send "I don't know!"
    else
      msg.send "Willy is #{willyLocation}"

