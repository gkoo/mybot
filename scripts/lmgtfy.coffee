# Description:
#   Hubot googles things for you!
#   Hubot will first try to get smart results from Google. Otherwise, Hubot will run your search through lmgtfy.
#
# Commands:
#   hubot what is _______?

htmlparser = require "htmlparser"
Select     = require("soupselect").select

doLmgtfy = (msg, query) ->
  msg.send "Hey #{msg.message.user.name}, let me google that for you: http://lmgtfy.com?q=#{query}"

doSmartGoogle = (msg, query) ->
  msg.http("https://www.google.com/search")
    .query(q: query)
    .get() (err, resp, body) ->
      handler = new htmlparser.DefaultHandler()
      parser = new htmlparser.Parser(handler)
      parser.parseComplete(body)

      answer = Select handler.dom, "#aoba"
      if answer.length == 0
        doLmgtfy(msg, encodeURIComponent(query))
      else
        msg.send answer[0].children[0].raw

module.exports = (robot) ->
  robot.respond /what(\sis|'s)\s+([^\?]+)\??$/i, (msg) ->
    [_, _, query] = msg.match
    doSmartGoogle(msg, query)
