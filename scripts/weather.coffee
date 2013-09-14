# Description:
#   Returns weather information from Forecast.io with a sprinkling of Google maps.
#
# Configuration:
#   HUBOT_WEATHER_CELSIUS - Display in celsius
#   HUBOT_FORECAST_API_KEY - Forecast.io API Key
#
# Commands:
#   hubot weather <city> - Get the weather for a location.
#   hubot forecast <city> - Get the 3 day forecast for a location.
#
# Author:
#   markstory
#   mbmccormick
env = process.env

forecastIoUrl = 'https://api.forecast.io/forecast/' + process.env.HUBOT_FORECAST_API_KEY + '/'
googleMapUrl = 'http://maps.googleapis.com/maps/api/geocode/json'

lookupAddress = (msg, location, cb) ->
  msg.http(googleMapUrl).query(address: location, sensor: true)
    .get() (err, res, body) ->
      try
        body = JSON.parse body
        result = body.results[0]
        data =
          coords: result.geometry.location
          formattedAddress: result.formatted_address
      catch err
        err = "Could not find #{location}"
        return cb(msg, null, err)
      cb(msg, data, err)

lookupWeather = (msg, data, err) ->
  return msg.send err if err
  return msg.send "You need to set env.HUBOT_FORECAST_API_KEY to get weather data" if not env.HUBOT_FORECAST_API_KEY

  coords = data.coords
  url = forecastIoUrl + coords.lat + ',' + coords.lng

  msg.http(url).query(units: 'ca').get() (err, res, body) ->
    return msg.send 'Could not get weather data' if err
    try
      body = JSON.parse body
      current = body.currently
    catch err
      return msg.send "Could not parse weather data."
    humidity = (current.humidity * 100).toFixed 0
    temperature = getTemp(current.temperature)
    text = ""
    text += "Weather for #{data.formattedAddress}:\n" if data.formattedAddress
    text += "It is currently #{temperature} #{current.summary}, #{humidity}% humidity"
    msg.send text

lookupForecast = (msg, data, err) ->
  return msg.send err if err
  return msg.send "You need to set env.HUBOT_FORECAST_API_KEY to get weather data" if not env.HUBOT_FORECAST_API_KEY

  coords = data.coords

  url = forecastIoUrl + coords.lat + ',' + coords.lng
  msg.http(url).query(units: 'ca').get() (err, res, body) ->
    return msg.send 'Could not get weather forecast' if err
    try
      body = JSON.parse body
      forecast = body.daily.data
      today = forecast[0]
      tomorrow = forecast[1]
      dayAfter = forecast[2]
    catch err
      return msg.send 'Unable to parse forecast data.'
    text = ""
    text += "The weather for #{data.formattedAddress}:\n" if data.formattedAddress

    appendText = (text, data) ->
      dateToday = new Date(data.time * 1000)
      month = dateToday.getMonth() + 1
      day = dateToday.getDate()
      humidity = (data.humidity * 100).toFixed 0
      maxTemp = getTemp data.temperatureMax
      minTemp = getTemp data.temperatureMin

      text += "#{month}/#{day} - High of #{maxTemp}, low of: #{minTemp} "
      text += "#{data.summary} #{humidity}% humidity\n"
      text

    text = appendText text, today
    text = appendText text, tomorrow
    text = appendText text, dayAfter
    msg.send text

getTemp = (c) ->
  if env.HUBOT_WEATHER_CELSIUS
    return c.toFixed(0) + "ºC"
  return ((c * 1.8) + 32).toFixed(0) + "ºF"


module.exports = (robot) ->

  robot.respond /weather(?: me|for|in)?\s(.*)/i, (msg) ->
    location = msg.match[1]
    lookupAddress(msg, location, lookupWeather)

  robot.respond /forecast(?: me|for|in)?\s(.*)/i, (msg) ->
    location = msg.match[1]
    lookupAddress(msg, location, lookupForecast)
