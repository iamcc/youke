var dispatcher = require('./dispatcher');

module.exports.getSidByUid = function(uid, app) {
  return (dispatcher.dispatch(uid, app.getServersByType('connector'))).id;
};