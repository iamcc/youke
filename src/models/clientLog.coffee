db = require('./db')

ClientLogSchema = new db.Schema {
  tid       : db.Types.ObjectId
  cid       : db.Types.ObjectId
  sid       : db.Types.ObjectId
  sname     : String
  sid2      : db.Types.ObjectId
  sname2    : String
  type      : type: String
  memo      : String
  createdAt : type: Date, default: Date.now
}

ClientLogSchema.index {type: 1, createdAt: -1}

module.exports = db.Youke.model 'ClientLog', ClientLogSchema, 'client.log'