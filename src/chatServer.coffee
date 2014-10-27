module.exports = (server, global) ->
    io    = require('socket.io')(server)
    redis = require 'socket.io-redis'

    io.adapter redis({host: 'localhost', port: 6379})

    io.on 'connect', (socket) ->
        socket.on 'set name', (name) ->
            delete global.users[socket.userName] if socket.userName
            socket.userName = name
            global.users[name] = socket
            io.emit 'users', Object.keys(global.users)

        socket.on 'msg', (name, msg) ->
            if global.users[name] then global.users[name].emit 'msg', msg
            else socket.emit 'msg', "user(#{name}) is offline"

        socket.on 'disconnect', ->
            delete global.users[socket.userName]
            io.emit 'users', Object.keys(global.users)
