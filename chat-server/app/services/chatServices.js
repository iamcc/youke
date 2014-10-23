var Code = require('../../../shared/code');

var Service = function(app) {
  this.users = {};
  this.app = app;
};

module.exports = Service;

Service.prototype.add = function(uid, sid, channelName) {
  var channel = this.app.get('channelService').getChannel(channelName, true);
  if(!channel) {
    return Code.CHAT.CHANNEL_CREATE;
  }
  channel.add(uid, sid);
  this.users[uid] = {uid: uid, sid: sid, chn: channelName};
  return Code.OK;
};

Service.prototype.leave = function(uid) {
  var channel;
  var user = this.users[uid];

  if(!!user && !!(channel = this.app.get('channelService').getChannel(user.chn))) {
    channel.leave(uid, user.sid);
  }
  delete this.users[uid];
};

Service.prototype.pushByChannel = function(channelName, msg, event, cb) {
  if(typeof(event) == 'function') {
    cb = event;
    event = 'chat';
  }
  var channel = this.app.get('channelService').getChannel(channelName);
  if(!channel) {
    return cb(null, Code.CHAT.CHANNEL_NOT_EXISTS);
  }
  channel.pushMessage(event, msg, cb);
};

Service.prototype.pushByUid = function(uid, msg, event, cb) {
  if(typeof(event) == 'function') {
    cb = event;
    event = 'chat';
  }
  var user = this.users[uid];
  if(!user) {
    return cb(null, Code.CHAT.USRE_OFFLINE);
  }
  this.app.get('channelService').pushMessageByUids(event, msg, [user], function(err, res) {
    cb(err, res.length && Code.FAIL || Code.OK);
  });
};