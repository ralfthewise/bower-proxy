nconf = require('nconf')
nconf.argv().env().file({file: 'config.json'})
express = require('express')
http = require('http')
url = require('url')
GitRequest = require('./gitRequest')
BowerRequest = require('./bowerRequest')

class BowerServer
    constructor: () ->
        @httpRegExp = /^https?:\/\/[^\/]+(.*)/
        @datastore = require("./datastore/#{nconf.get('datastore')}")
        @app = express()
        @app.all('/git_cache*', @_proxyGitRequest)
        @app.get('/packages/:packageName', @_lookupPackage)
        @app.all('*', @_proxyBowerRequest)

    run: () ->
        @app.listen(3000)

    _proxyGitRequest: (incomingRequest, incomingResponse) =>
        gitRequest = new GitRequest(incomingRequest, incomingResponse)
        gitRequest.process().done()

    _lookupPackage: (incomingRequest, incomingResponse) =>
        @datastore.lookupPackageEntity(incomingRequest.params.packageName).then((entity) =>
            if entity? #TODO: check updatedAt
                console.log('Bower cache hit, sending response')
                incomingResponse.send(entity.data)
            else
                console.log('Bower cache miss, proxying upstream')
                @_fetchPackageAndCacheResults(incomingRequest, incomingResponse)
        , (error) =>
            console.log('Bower cache error, will try to proxy upstream to recover.', error)
            @_fetchPackageAndCacheResults(incomingRequest, incomingResponse)
        ).done()

    _fetchPackageAndCacheResults: (incomingRequest, incomingResponse) ->
        bowerRequest = new BowerRequest(incomingRequest, incomingResponse)
        bowerRequest.process().then((pkg, statusCode) =>
            if pkg.name? and pkg.url?
                entity = {name: pkg.name, originalUrl: pkg.url, data: pkg}
                pkg.url = pkg.url.replace('git://', 'https://')
                pkg.url = pkg.url.replace(@httpRegExp, "#{nconf.get('gitLocalPrefix')}/git_cache/#{pkg.name}")
                @datastore.savePackageEntity(entity).done()
                incomingResponse.send(pkg, statusCode)
            else
                console.log('Invalid Bower upstream response: ', pkg.name)
                incomingResponse.send({error: 'Invalid upstream response.', upstreamResponse: pkg}, 503)
        ).done()

    _proxyBowerRequest: (incomingRequest, incomingResponse) =>
        bowerRequest = new BowerRequest(incomingRequest, incomingResponse)
        bowerRequest.process().done()

module.exports = BowerServer
