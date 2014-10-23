module.exports = function(app) {
  return new Remote(app, app.get('chatService'));
};

var Remote = function(app, chatService) {
  this.app         = app;
  this.chatService = chatService;
};

Remote.prototype.add = function(uid, sid, channelName, cb) {
  var code = this.chatService.add(uid, sid, channelName);
  cb(null, code);
};

Remote.prototype.kick = function(uid, cb) {
  this.chatService.leave(uid);
  cb();
};