nconf = require('nconf')
express = require('express')
http = require('http')
url = require('url')
GitRequest = require('./gitRequest')
BowerRequest = require('./bowerRequest')
nconf.argv().env().file({file: 'config.json'})

class BowerServer
    constructor: () ->
        @app = express()
        @app.all('/git*', @_proxyGitRequest)
        @app.all('*', @_proxyBowerRequest)

    run: () ->
        @app.listen(3000)

    _proxyGitRequest: (req, res) =>
        gitRequest = new GitRequest(req, res)
        gitRequest.process()

    _proxyBowerRequest: (req, downstreamRes) =>
        bowerRequest = new BowerRequest(req, downstreamRes)
        bowerRequest.process()

module.exports = BowerServer
