# Description:
#   Get the latest Invisible Bread
#
# Dependencies:
#   "htmlparser": "1.7.6"
#   "soupselect": "0.2.0"
#
# Configuration:
#   None
#
# Commands:
#   hubot invisible bread - The latest invisible bread
#
# Author:
#   gkoo

htmlparser = require "htmlparser"
Select     = require("soupselect").select

module.exports = (robot) ->
  getComic = (msg, url) ->
    msg.http(url)
        .get() (err, res, body) ->
          handler = new htmlparser.DefaultHandler()
          parser = new htmlparser.Parser(handler)
          parser.parseComplete(body)

          img = Select handler.dom, "#comic-1 img"
          comic = img[0].attribs

          msg.send comic.title if comic.title
          msg.send comic.src

  robot.respond /invisible bread$/i, (msg) ->
    getComic(msg, "http://invisiblebread.com")

  # need to figure out how to follow redirects
  #robot.respond /invisible bread random$/i, (msg) ->
    #msg.http("http://invisiblebread.com/?randomcomic&nocache=1")
        #.get() (err, res, body) ->
          #msg.send "err"
          #msg.send err
          #msg.send "res"
          #msg.send JSON.stringify(res)
