var Code = require('../../../../../shared/code');
var db = require('../../../../../lib/models/db');
var Message = require('../../../../../lib/models/chatMessage');
var Client = require('../../../../../lib/models/client');

module.exports = function(app) {
  return new Handler(app, app.get('chatService'));
};

var Handler = function(app, chatService) {
  this.app = app;
  this.chatService = chatService;
};

Handler.prototype.send = function(msg, session, next) {
  var msgId = new db.ObjectId;
  var param = {uid: session.uid, id: msgId, msg: msg.msg};

  Message.create({
    _id: msgId,
    tid: session.get('tid'),
    uid: session.uid,
    toId: msg.to,
    msg: msg.msg
  }, function(err, msg) {
    if(err) {
      console.error(err.stack);
    }
  });
  this.chatService.pushByUid(msg.to, param, function(err, code) {
    if(err) return next(err, {code: Code.FAIL});
    next(null, {code: code, id: msgId});
  });
};

Handler.prototype.receive = function(msg, session, next) {
  if(Array.isArray(msg.id)) {
    Message.update({_id:{$in:msg.id}}, {status: Message.Status.RECEIVED}, {multi: true}, function(err) {
      if(err) return next(err, {code: Code.FAIL});
      next(null, {code: Code.OK});
    });
  } else {
    Message.findByIdAndUpdate(msg.id, {status: Message.Status.RECEIVED}, function(err) {
      if(err) {
        console.error(err);
        return next(err, {code: Code.FAIL});
      }
      next(null, {code: Code.OK});
    });
  }
};

Handler.prototype.getOfflineMessages = function(msg, session, next) {
  var query = {toId: session.uid, status: Message.Status.OFFLINE};
  Message.find(query, function(err, docs) {
    if(err) return next(err, {code: Code.FAIL});
    next(null, {code: Code.OK, msgs: docs});
  })
};

Handler.prototype.askContact = function(msg, session, next) {
  this.chatService.pushByUid(msg.uid, session.uid, 'askContact', function(err, code) {
    if(err) return next(err, {code: Code.FAIL});
    next(null, {code: code});
  });
};

Handler.prototype.submitContact = function(msg, session, next) {
  var param = {uid: session.uid, name: msg.name, mobile: msg.mobile};
  var update = {Name: msg.name, Mobile: msg.mobile};
  Client.findByIdAndUpdate(session.uid, update, function(err) {
    if(err) return next(err, {code: Code.FAIL});
    this.chatService.pushByUid(msg.uid, param, 'submitContact', function(err, code) {
      if(err) console.error(err.stack);
      next(null, {code: code});
    });
  });
};

Handler.prototype.rejectContact = function(msg, session, next) {
  this.chatService.pushByUid(msg.uid, session.uid, 'rejectContact', function(err, code) {
    if(err) console.error(err.stack);
    next(null, {code: code});
  });
};