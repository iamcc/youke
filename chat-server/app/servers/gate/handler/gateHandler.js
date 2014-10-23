var dispatcher = require('../../../utils/dispatcher');
var Code = require('../../../../../shared/code');

module.exports = function(app) {
  return new Handler(app);
};

var Handler = function(app) {
  this.app = app;
};

Handler.prototype.queryEntry = function(msg, session, next) {
  var connectors = this.app.getServersByType('connector');
  if(!(connectors && connectors.length)) return next(null, {code: Code.GATE.NO_SERVER});

  var res = dispatcher.dispatch(session.id, connectors);
  next(null, {code: Code.OK, host: res.host, port: res.clientPort});
};