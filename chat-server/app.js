var pomelo = require('pomelo');
var jwt = require('jsonwebtoken');
var config = require('../lib/config');
var dispatcher = require('./app/utils/dispatcher');
var ChatService = require('./app/services/chatServices');
var app = pomelo.createApp();

app.set('name', 'chat');

// handler 热更新开关
app.set('serverConfig', {
  reloadHandlers: true
});

// remote 热更新开关
app.set('remoteConfig', {
  reloadRemotes: true
});

app.configure('development|production', function() {
  app.route('chat', function(session, msg, app, cb) {
    var chatServers = app.getServersByType('chat');
    if (!(chatServers && chatServers.length)) return cb(new Error('can not find chat servers.'));
    var res = dispatcher.dispatch(session.get('tid'), chatServers);
    cb(null, res.id);
  });
});

app.configure('development|production', 'chat', function() {
  app.set('chatService', new ChatService(app));
});

// app configuration
app.configure('production|development', 'connector', function() {
  app.set('connectorConfig', {
    connector: pomelo.connectors.sioconnector,
    //websocket, htmlfile, xhr-polling, jsonp-polling, flashsocket
    transports: ['websocket', 'xhr-polling'],
    heartbeats: true,
    closeTimeout: 60,
    heartbeatTimeout: 60,
    heartbeatInterval: 25,
    useDict: true,
  });
})

// start app
app.start();

process.on('uncaughtException', function(err) {
  console.error(' Caught exception: ' + err.stack);
});