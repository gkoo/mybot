# Description:
#   Interacts with the Google Maps API.
#
# Commands:
#   hubot map me <query> - Returns a map view of the area returned by `query`.

module.exports = (robot) ->

  robot.respond /directions from (.+) to (.+)/i, (msg) ->
    origin      = msg.match[1]
    destination = msg.match[2]
    key         = process.env.HUBOT_GOOGLE_API_KEY
    if !key
      msg.send "Please enter your Google API key in the environment variable HUBOT_GOOGLE_API_KEY."

    url         = "https://maps.googleapis.com/maps/api/directions/json"
    query       =
      key:         key
      origin:      origin
      destination: destination
      sensor:      false

    robot.http(url).query(query).get()((err, res, body) ->
      jsonBody = JSON.parse(body)
      route = jsonBody.routes[0]
      if !route
        msg.send "Error: No route found."
        return
      legs = route.legs[0]
      start = legs.start_address
      end = legs.end_address
      distance = legs.distance.text
      duration = legs.duration.text
      response = "Directions from #{start} to #{end}\n"
      response += "#{distance} - #{duration}\n\n"
      i = 1
      for step in legs.steps
        response += "#{i}. #{step.html_instructions} (#{step.distance.text})\n"
        i++
      msg.send response
    )

  robot.respond /(?:(satellite|terrain|hybrid)[- ])?map( me)? (.+)/i, (msg) ->
    mapType  = msg.match[1] or "roadmap"
    location = msg.match[3]
    mapUrl   = "http://maps.google.com/maps/api/staticmap?markers=" +
                escape(location) +
                "&size=400x400&maptype=" +
                mapType +
                "&sensor=false" +
                "&format=png" # So campfire knows it's an image
    url      = "http://maps.google.com/maps?q=" +
               escape(location) +
              "&hl=en&sll=37.0625,-95.677068&sspn=73.579623,100.371094&vpsrc=0&hnear=" +
              escape(location) +
              "&t=m&z=11"

    msg.send mapUrl
    msg.send url

