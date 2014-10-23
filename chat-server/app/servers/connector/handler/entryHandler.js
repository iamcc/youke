var jwt    = require('jsonwebtoken');
var async  = require('async');
var config = require('../../../../../lib/config');
var Code   = require('../../../../../shared/code');

module.exports = function(app) {
  return new Handler(app);
};

var Handler = function(app) {
  this.app = app;
};

Handler.prototype.entry = function(msg, session, next) {
  var app   = this.app;
  var token = msg.token;
  var sid   = app.get('serverId');
  var uid, tid;

  if(!token) return next(null, {code: Code.ENTRY.TOKEN_INVALID, msg: 'token is required'});

  var verify = function(cb) {
    jwt.verify(token, config.jwt_secret, cb);
  };
  var kick = function(decoded, cb) {
    uid = decoded._id;
    tid = decoded.tid;
    app.sessionService.kick(uid, cb);
  };
  var bind = function(cb) {
    session.bind(uid);
    session.set('tid', tid);
    session.on('closed', function(session) {
      if(!(session && session.uid)) return;
      app.rpc.chat.chatRemote.kick(session, uid, null);
    });
    session.pushAll(cb);
  };
  var add = function(cb) {
    app.rpc.chat.chatRemote.add(session, uid, sid, tid, cb);
  };
  var handleErr = function(err, next) {
    switch(err.name) {
      case 'TokenExpiredError': next(null, {code: Code.ENTRY.TOKEN_EXPIRE}); break;
      case 'JsonWebTokenError': next(null, {code: Code.ENTRY.TOKEN_INVALID, msg: err.message}); break;
      defalut: next(err, {code: Code.FAIL});
    }
  };

  async.waterfall([verify, kick, bind, add], function(err) {
    if(err) {
      handleErr(err, next);
      return app.sessionService.kickBySessionId(session.id);
    }
    next(null, {code: Code.OK, uid: uid});
  });
};