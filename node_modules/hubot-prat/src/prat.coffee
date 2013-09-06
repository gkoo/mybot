{Adapter,Robot,TextMessage,EnterMessage,LeaveMessage} = require 'hubot'

WebsocketClient = require('websocket').client
crypto     = require('crypto')
_u         = require('underscore')

class PratBot extends Adapter
  prepare_query_string: (params) ->
    str = ""
    keys = Object.keys(params)
    keys = _u.sortBy(keys, (key) -> return key)
    str += [key, '=', params[key]].join('') for key in keys
    return str

  generateSignature: (secret, method, path, body, params) ->
    body = if not body? then "" else body
    signature = secret + method.toUpperCase() + path + @prepare_query_string(params) + body
    hash = crypto.createHash('sha256').update(signature).digest()
    b64 = (new Buffer(hash)).toString('base64').substring(0, 43)
    b64 = b64.replace(/\+/g, '-').replace(/\//g, '_')
    b64 = b64.replace(/\//g, '_')

  run: ->
    expires = parseInt((new Date()).getTime()/1000) + 300
    params = { "api_key": process.env.HUBOT_PRAT_API_KEY, "expires": expires.toString() }
    params.signature = @generateSignature(process.env.HUBOT_PRAT_SECRET, "GET", "/eventhub", "", params)
    urlparams = []
    urlparams.push [prop, params[prop]].join('=') for prop of params
    @client = new WebsocketClient()
    @client.on 'connect', @.onConnect
    @client.connect process.env.HUBOT_PRAT_SERVER_URL + '?' + urlparams.join('&')

  onConnect: (connection) =>
    if !@connected
      @emit 'connected'
      @connected = true
    @connection = connection

    connection.on 'message', @onMessage
    connection.on 'error', @onError

  onError: (error) =>
    console.log("Connection Error: " + error.toString())

  onMessage: (message) =>
    msg = JSON.parse(message.utf8Data)
    if msg.action == 'publish_message' && msg?.data?.user?.username != process.env.HUBOT_PRAT_BOT_NAME
      msgText = @preprocessText msg.data.message

      # Check if hubot should join a room
      joinRegex = new RegExp("^#{@robot.name} join (.*)$", 'i')
      leaveRegex = new RegExp("^#{@robot.name} leave (.*)$", 'i')
      if match = msgText.match(joinRegex)
        @joinChannel(match[1])
      else if match = msgText.match(leaveRegex)
        @leaveChannel(match[1])
      else
        channel = msg.data.channel
        user = @robot.brain.userForId msg.data.user.username
        user.room = msg.data.channel

        @receive new TextMessage user, msgText

  joinChannel: (channel) =>
    channels = @robot.brain.get 'channels'
    channels ||= []
    joined = channels.indexOf(channel)
    if joined == -1
      outputJson =
        action: "join_channel"
        data:
          channel: channel

      channels.push(channel)
      @robot.brain.set('channels', channels)
      @sendJSON(outputJson)

  leaveChannel: (channel) =>
    channels = @robot.brain.get 'channels'
    channels ||= []
    index = channels.indexOf(channel)
    return if index == -1
    outputJson =
      action: "leave_channel"
      data:
        channel: channel

    channels.splice(index, 1)
    @robot.brain.set('channels', channels)
    @sendJSON(outputJson)

  preprocessText: (str) ->
    result = str
    if match = str.match(/^\/img\s+(.*)/)
      result = "#{@robot.name} image me #{match[1]}"
    else if match = str.match(/^\/animate\s+(.*)/)
      result = "#{@robot.name} animate me #{match[1]}"
    result

  sendJSON: (json) =>
    @connection.send(JSON.stringify(json))

  send: (envelope, messages...) ->
    for msg in messages
      @robot.logger.debug "Sending to #{envelope.room}: #{msg}"

      outputJson =
        action: "publish_message"
        data:
          message: msg
          channel: envelope.room

      @sendJSON(outputJson)

  reply: (envelope, messages...) ->
    for msg in messages
      @send envelope, "#{envelope.user.name}: #{msg}"

  close: ->
    # TODO: leave the chat
    console.log('close')

exports.use = (robot) ->
  new PratBot robot

