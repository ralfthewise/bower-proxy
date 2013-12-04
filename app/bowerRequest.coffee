nconf = require('nconf')
http = require('http')
nconf.argv().env().file({file: 'config.json'})

class BowerRequest
    constructor: (@incomingRequest, @incomingResponse) ->

    process: () ->
        options =
            hostname: 'bower.herokuapp.com',
            port: 80,
            path: @incomingRequest.originalUrl,
            method: @incomingRequest.route.method.toUpperCase()

        console.log('Sending upstream request: ', options)
        req = http.request(options, @_handleBowerResponse)
        req.on('error', @_handleHttpError)
        req.end()

    _handleBowerResponse: (res) =>
        console.log("statusCode: ", res.statusCode)
        console.log("headers: ", res.headers)

        payload = ''
        res.on('data', (d) =>
            payload += d
            process.stdout.write(d)
        )

        res.on('end', () =>
            console.log('Upstream response: ', payload)
            @incomingResponse.send(payload, res.statusCode)
        )

    _handleHttpError: (e) =>
        console.log('Error: ', e)
        @incomingResponse.send(e.message)

module.exports = BowerRequest
