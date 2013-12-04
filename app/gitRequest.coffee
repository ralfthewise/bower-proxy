nconf = require('nconf')
url = require('url')
nconf.argv().env().file({file: 'config.json'})

class GitRequest
    constructor: (@incomingRequest, @incomingResponse) ->

    process: () ->
        console.log('path: ', @incomingRequest.url)
        options =
            'GIT_PROJECT_ROOT': '/Users/tim/git_cache',
            'GIT_HTTP_EXPORT_ALL': 'true',
            'PATH_INFO': url.parse(@incomingRequest.url).pathname,
            'REQUEST_METHOD': @incomingRequest.route.method.toUpperCase()

        require('child_process').exec('git http-backend', {encoding: 'binary', maxBuffer: 81920*1024, env: options}, @_handleGitResponse)

    _handleGitResponse: (error, stdout, stderr) =>
        console.log('error: ', error) if error?

        buf = new Buffer(stdout, 'binary')
        console.log('response length: ', buf.length)
        statusHeader = buf.toString().match(/Status: ([0-9]+)/)
        if (statusHeader?)
            @incomingRequest.connection.write(new Buffer("HTTP/1.1 #{statusHeader[1]}\r\n", 'binary'))
        else
            @incomingRequest.connection.write(new Buffer("HTTP/1.1 200\r\n", 'binary'))
        @incomingRequest.connection.write(buf)
        @incomingRequest.connection.end()

module.exports = GitRequest
