nconf = require('nconf')
nconf.argv().env().file({file: 'config.json'})
path = require('path')
mkdirp = require('mkdirp')
NeDB = require('nedb')
Q = require('q')

class NedbDatastore
    constructor: () ->
        mkdirp.sync(path.dirname(nconf.get('nedb:datafile')))
        @db = new NeDB({filename: nconf.get('nedb:datafile'), autoload: true})

    savePackageEntity: (entity) =>
        deferred = Q.defer()
        entity.updatedAt = new Date()
        @db.update({name: entity.name}, entity, {upsert: true}, (err, numReplaced, upsert) ->
            if err? deferred.reject(err) else deferred.resolve(entity)
        )
        return deferred.promise

    lookupPackageEntity: (packageName) =>
        deferred = Q.defer()
        @db.findOne({name: packageName}, (err, pkg) ->
            if err? deferred.reject(err) else deferred.resolve(pkg)
        )
        return deferred.promise

module.exports = new NedbDatastore()
