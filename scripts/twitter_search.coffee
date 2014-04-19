# Description:
#   Searches tweets on Twitter.
#
# Dependencies:
#   "twit": "1.1.6"
#   "underscore": "1.4.4"
#
# Configuration:
#   HUBOT_TWITTER_CONSUMER_KEY
#   HUBOT_TWITTER_CONSUMER_SECRET
#   HUBOT_TWITTER_ACCESS_TOKEN
#   HUBOT_TWITTER_ACCESS_TOKEN_SECRET
#
# Commands:
#   hubot twitter-search <query> - Search Twitter for a query
#
# Author:
#   gkoo
#

_ = require "underscore"
Twit = require "twit"
config =
  consumer_key: process.env.HUBOT_TWITTER_CONSUMER_KEY
  consumer_secret: process.env.HUBOT_TWITTER_CONSUMER_SECRET
  access_token: process.env.HUBOT_TWITTER_ACCESS_TOKEN
  access_token_secret: process.env.HUBOT_TWITTER_ACCESS_TOKEN_SECRET

module.exports = (robot) ->
  twit = undefined

  robot.respond /twitter-search (.+)/i, (msg) ->
    unless config.consumer_key
      msg.send "Please set the HUBOT_TWITTER_CONSUMER_KEY environment variable."
      return
    unless config.consumer_secret
      msg.send "Please set the HUBOT_TWITTER_CONSUMER_SECRET environment variable."
      return
    unless config.access_token
      msg.send "Please set the HUBOT_TWITTER_ACCESS_TOKEN environment variable."
      return
    unless config.access_token_secret
      msg.send "Please set the HUBOT_TWITTER_ACCESS_TOKEN_SECRET environment variable."
      return

    unless twit
      twit = new Twit config

    query = msg.match[1]
    msg.send "Searching Twitter for \"#{query}\"..."
    searchConfig =
      q: "#{query}",
      count: 5,
      lang: 'en',
      result_type: 'recent'

    twit.get 'search/tweets', searchConfig, (err, reply) ->
      return msg.send "Error retrieving tweets!" if err
      return msg.send "No results returned!" unless reply?.statuses?.length

      statuses = reply.statuses
      return_val = ''
      i = 0
      for status, i in statuses
        return_val += "**@#{status.user.screen_name}** #{status.text}\n"

      return msg.send return_val
