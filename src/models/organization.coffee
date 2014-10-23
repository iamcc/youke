db = require './db'

OrgSchema = new db.Schema {
  tid       : type: db.Types.ObjectId, required: true, index: true
  name      : type: String, required: true
  parent    : type: db.Types.ObjectId, ref: 'Organization', index: true
  saleses   : [{type: db.Types.ObjectId, ref: 'Sales'}]
  createdAt : type: Date, default: Date.now
  updatedAt : type: Date, default: Date.now
}

OrgSchema.pre 'save', (next) ->
  db.Youke.model('Organization').findOne {tid: @tid, _id: @parent}, (err, doc) =>
    if not doc then @invalidate 'parent', 'not exists'
    next err

module.exports = db.Youke.model 'Organization', OrgSchema, 'organizations'