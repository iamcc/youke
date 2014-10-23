db = require('./db')

ChatMessageSchema = new db.Schema
  _id: db.Types.ObjectId
  tid: db.Types.ObjectId
  uid: db.Types.ObjectId
  toId: db.Types.ObjectId
  msg: String
  status: type: Number, enum: [-1, 0, 1, 2], default: 0 #-1=del, 0=offline, 1=received, 2=readed
  createdAt: type: Date, default: Date.now

module.exports = db.Youke.model 'ChatMessage', ChatMessageSchema, 'chat.message'
module.exports.Status =
  DELETED: -1,
  OFFLINE: 0,
  RECEIVED: 1,
  READED: 2