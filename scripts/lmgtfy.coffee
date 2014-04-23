# Description:
#   Hubot googles things for you!
#
# Commands:
#   hubot what is _______?

module.exports = (robot) ->
  robot.respond /what(\sis|'s)\s+([^\?]+)\??$/i, (msg) ->
    [_, _, query] = msg.match
    str = encodeURIComponent(query)
    msg.send "Hey #{msg.message.user.name}, let me google that for you: http://lmgtfy.com?q=#{str}"
