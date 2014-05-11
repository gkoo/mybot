# Description:
#   Grabs movie scores from Rotten Tomatoes
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_ROTTEN_TOMATOES_API_KEY
#
# Commands:
#   hubot rotten [me] <movie>
#   hubot rotten-top-[x] <movie> - the top x results for a movie query
#   hubot rotten-result-[x] <movie> - get the xth result for a movie query
#   hubot what's in theaters?
#   hubot what's coming out in theaters?
#   hubot what's coming out on (dvd|bluray)? - there is not a distinction between dvd and bluray
#
# Author:
#   mportiz08

class Rotten
  constructor: (@robot) ->
    @api_url = "http://api.rottentomatoes.com/api/public/v1.0"
    @api_key = process.env.HUBOT_ROTTEN_TOMATOES_API_KEY

  _links: (match, callback) =>
    return callback @__links[match] if @__links
    @send "#{@api_url}/lists.json", {},
      (err, res, body) =>
        @__links = JSON.parse(body).links
        callback @__links[match]

  _movie_links: (match, callback) =>
    return callback @__movie_links[match] if @__movie_links
    @_links 'movies',
      (link) =>
        @send link, {},
          (err, res, body) =>
            @__movie_links = JSON.parse(body).links
            callback @__movie_links[match]

  _dvd_links: (match, callback) =>
    return callback @__dvd_links[match] if @__dvd_links
    @_links 'dvds',
      (link) =>
        @send link, {},
          (err, res, body) =>
            @__dvd_links = JSON.parse(body).links
            callback @__dvd_links[match]

  in_theaters: (callback) =>
    @_movie_links 'in_theaters',
      (match) =>
        @send match,
          page_limit: 20
          country: 'us'
          (err, res, body) ->
            movies = JSON.parse(body).movies

            console.log(err)
            unless err? or movies?
              return callback("Couldn't find anything, sorry.")

            callback null, (new RottenMovie(movie) for movie in movies)

  upcoming: (type, callback) =>
    link_list = switch type
      when 'movies'
        @_movie_links
      when 'dvds'
        @_dvd_links
      else
        @_movie_links

    link_list 'upcoming',
      (match) =>
        @send match,
          page_limit: 20
          country: 'us'
          (err, res, body) ->
            movies = JSON.parse(body).movies

            unless err? or movies?
              return callback("Couldn't find anything, sorry.")

            callback null, (new RottenMovie(movie) for movie in movies)

  search: (query, callback) =>
    @send "#{@api_url}/movies.json",
      q: query
      page_limit: 1
      (err, res, body) ->
        response = JSON.parse(body)
        movie = response.movies?[0]

        console.log(err)
        console.log(response)
        unless err? or movie?
          return callback("Couldn't find anything, sorry.")

        callback null, new RottenMovie(movie)

    return

  searchMultiple: (query, numResults, callback) =>
    @send "#{@api_url}/movies.json",
      q: query
      page_limit: numResults
      (err, res, body) ->
        moviesArr = []
        movies = JSON.parse(body).movies
        for movie in movies
          moviesArr.push(new RottenMovie(movie))

        unless err? or movie?
          return callback("Couldn't find anything, sorry.")

        callback null, moviesArr

    return

  send: (url, options, callback) =>
    options.apikey = @api_key
    @robot.http(url).query(options).get()(callback)

class RottenMovie
  constructor: (@info) ->

  toDetailedString: ->
    "#{@info.title} (#{@info.year})\n" +
    "#{@info.runtime} min, #{@info.mpaa_rating}\n\n" +
    "Critics:\t" + "#{@info.ratings.critics_score}%" +
      "\t\"#{@info.ratings.critics_rating}\"\n" +
    "Audience:\t" + "#{@info.ratings.audience_score}%" +
      "\t\"#{@info.ratings.audience_rating}\"\n\n" +
    "#{@info.critics_consensus}"

  toReleaseString: ->
    "(#{@info.ratings.audience_score}%) #{@info.title}, #{@info.release_dates.dvd || @info.release_dates.theater}"

  toString: ->
    "(#{@info.ratings.audience_score}%) #{@info.title}"

  getPosterUrl: ->
    posters = @info.posters
    if posters
      return posters.detailed || posters.profile || posters.thumbnail || posters.original
    return null

  createResponse: ->
    posterUrl = @getPosterUrl()
    response = ""
    response += "#{posterUrl}\n" if posterUrl
    response += @toDetailedString()
    return response

module.exports = (robot) ->
  rotten = new Rotten robot

  robot.respond /rotten (me )?(.*)$/i, (message) ->
    rotten.search message.match[2], (err, movie) ->
      unless err?
        message.send movie.createResponse()
      else
        message.send err

  robot.respond /rotten-top-(\d+) (.*)$/i, (message) ->
    numResults = parseInt(message.match[1], 10)
    title = message.match[2]
    rotten.searchMultiple title, numResults, (err, movies) ->
      unless err?
        i = 0
        response = ""
        for movie in movies
          response += "#{i+1}. #{movie.toString()}\n"
          i++
        message.send response
      else
        message.send err

  robot.respond /rotten-result-(\d+) (.*)$/i, (message) ->
    numResults = parseInt(message.match[1], 10)
    title = message.match[2]
    rotten.searchMultiple title, numResults, (err, movies) ->
      unless err?
        if numResults > movies.length
          message.send "There weren't that many results for #{title}."
        else
          movie = movies[numResults-1]
          message.send movie.createResponse()
      else
        message.send err

  robot.respond /what(\')?s in theaters(\?)?$/i, (message) ->
    rotten.in_theaters (err, movies) ->
      unless err?
        message.send (movie.toString() for movie in movies).join("\n")
      else
        message.send err

  robot.respond /what(\')?s coming out ((on (dvd|blu(-)?ray))|(in theaters))(\?)?$/i, (message) ->
    type = if message.match[2] is 'in theaters' then 'movies' else 'dvds'
    rotten.upcoming type, (err, movies) ->
      unless err?
        message.send (movie.toReleaseString() for movie in movies).join("\n")
      else
        message.send err
