mongoose = require 'mongoose'
thunkify = require 'thunkify'

mongoose.plugin (schema) ->
  schema.method 'persist', ->
    (cb) => @save cb
  schema.method 'destroy', ->
    (cb) => @remove cb

opts =
  server:
    auto_reconnect: false
    socketOption:
      keepAlive: true

Youke  = mongoose.createConnection 'root:123456@127.0.0.1:27017/youke', opts
Scrm   = mongoose.createConnection 'root:123456@127.0.0.1:27017/mae_analysis', opts
Tenant = mongoose.createConnection 'root:123456@127.0.0.1:27017/dev_wx_mae', opts

for db in [Youke, Scrm, Tenant]
  db.on 'error', (err) ->
    console.log err, db

module.exports =
  # dev
  Youke  : Youke
  Scrm   : Scrm
  Tenant : Tenant

  Types  : mongoose.Schema.Types
  Schema : mongoose.Schema

  ObjectId: mongoose.Types.ObjectId