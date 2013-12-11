nconf = require('nconf')
nconf.argv().env().file({file: 'config.json'})
http = require('http')
Q = require('q')
lodash = require('lodash')

class BowerRequest
    constructor: (@incomingRequest, @incomingResponse, options = null) ->
        @options = lodash.extend({}, {sendResponse: true, sendError: true, parseResponse: true}, options)
        @deferred = Q.defer()

    process: () ->
        options =
            hostname: 'bower.herokuapp.com',
            port: 80,
            path: @incomingRequest.originalUrl,
            method: @incomingRequest.route.method.toUpperCase()

        console.log('Sending upstream Bower request: ', options)
        req = http.request(options, @_handleBowerResponse)
        req.on('error', @_handleHttpError)
        req.end()
        return @deferred.promise

    _handleBowerResponse: (res) =>
        console.log("Upstream Bower response status code: ", res.statusCode)
        console.log("Upstream Bower response headers: ", res.headers)

        payload = ''
        res.on('data', (d) =>
            payload += d
            process.stdout.write(d)
        )

        res.on('end', () =>
            console.log('Upstream Bower response content: ', payload)
            console.log(' ')
            @incomingResponse.send(payload, res.statusCode) if @options.sendResponse
            payload = JSON.parse(payload) if @options.parseResponse
            @deferred.resolve(payload, res.statusCode)
        )

    _handleHttpError: (e) =>
        console.log('Upstream Bower error: ', e)
        @incomingResponse.send(e.message) if @options.sendError
        @deferred.reject(e)

module.exports = BowerRequest
