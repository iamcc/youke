db   = require('./db')
Role = require './role'
Org  = require './organization'
pswd = require('pswd') {length: 32}

SalesSchema = new db.Schema {
  tid          : type: db.Types.ObjectId, required: true
  tname        : type: String, default: ''
  avatar       : type: String, default: ''
  name         : type: String, required: true
  mobile       : type: String, required: true, index: true, match: /\d{11}/
  passwordHash : type: String, required: true
  role         : type: db.Types.ObjectId, ref: 'Role'
  manager      : type: db.Types.ObjectId, ref: 'Sales'
  org          : type: db.Types.ObjectId, ref:'Organization', required: true, index: true
  status       : type: Number, enum: [0, 1, -1], default: 1
  forget       :
    code : String
    exp  : Date
  createdAt     : type: Date, default: Date.now
  lastLoginedAt : Date
  lastLoginedIP : String
  token         : String
  isPush: type: Boolean, default: true
}

# SalesSchema.index {mobile: 1, tid: 1, status: 1}, {unique: true}

SalesSchema.virtual 'password'
.get -> @_password
.set (v) ->
  @_password    = v
  @passwordHash = v

SalesSchema.virtual 'passwordConfirmation'
.get -> @_passwordConfirmation
.set (v) -> @_passwordConfirmation = v

SalesSchema.path 'passwordHash'
.validate (v) ->
  if @_password
    if @_password.length < 6 then @invalidate 'password', 'at least 6 characters.'
    if @_password isnt @_passwordConfirmation then @invalidate 'passwordConfirmation', 'must match confirmation.'
  if @isNew and not @_password then @invalidate 'password', 'required'
, null

SalesSchema.pre 'save', (next) ->
  if @_password
    pswd.hash @_password
    .then (hash) =>
      @passwordHash = hash
      next()
  else
    next()

SalesSchema.method {
  checkPassword : (pwd) -> pswd.compare pwd, @passwordHash
}

SalesSchema.post 'init', ->
  @oldRole = @role
  @oldOrg  = @org

SalesSchema.post 'save', ->
  if @oldRole and @role isnt @oldRole then Role.update {_id: @oldRole}, {$pull: saleses: @_id}, (err) -> console.log err if err
  if @oldOrg and @org isnt @oldOrg then Org.update {_id: @oldOrg}, {$pull: saleses: @_id}, (err) -> console.log err if err

  Role.update {_id: @role}, {$addToSet: saleses: @_id}, (err) -> console.log err if err
  Org.update {_id: @org}, {$addToSet: saleses: @_id}, (err) -> console.log err if err

module.exports = db.Youke.model 'Sales', SalesSchema, 'saleses'