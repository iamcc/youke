Org    = require '../models/organization'
Role   = require '../models/role'
Sales  = require '../models/sales'
config = require '../config'

module.exports =
  list: ->*
    @checkAdmin()
    tid  = @user.tid

    if @query.tree
      orgs = yield Org.find({tid: tid, parent: null}).sort({createdAt:1}).exec()
      orgs = yield loopOrg(orgs)
    else
      orgs  = yield Org.find({tid: tid}).sort({createdAt:1}).select({name: 1}).exec()

    @body = orgs
  create: ->*
    @checkAdmin()

    org        = new Org
    org.tid    = @user.tid
    org.name   = @request.body.name
    org.parent = @request.body.parent

    yield Org.create org
    
    @body = org
  update: ->*
    @checkAdmin()

    tid = @user.tid
    oid = @params.id
    org = yield Org.findOne({tid: tid, _id: oid}).exec()

    @throw 404 unless org

    update =
      name    : @request.body.name
      parent  : @request.body.parent or null
      updatedAt : Date.now()

    yield org.update(update).exec()
    @body = 1
  remove: ->*
    @checkAdmin()

    tid = @user.tid
    oid = @params.id
    org = yield Org.findOne({tid: tid, _id: oid}).populate({path: 'saleses', match: {status: $ne: -1}, options: {limit: 1}}).exec()

    @throw 404 unless org

    children = yield Org.count({parent: oid}).exec()
    @throwMsg 403, 'has sub organization or saleses' if children > 0 or org.saleses.length

    org.remove()
    @body = 1

#===========================================

loopOrg = (orgs) ->*
  i = 0
  yield Org.populate(orgs, {path: 'saleses', match: {status: $ne: -1}, select: 'name mobile avatar role org manager status'})
  for org in orgs
    yield Sales.populate(org.saleses, [
      {path: 'role', select: 'name'}
      {path: 'org', select: 'name'}
    ])
    orgs[i++] = org.toObject()
  for org in orgs
    org.text = org.name
    nodes    = yield Org.find({parent: org._id}).sort({createdAt:1}).exec()
    if nodes and nodes.length > 0
      org.nodes = nodes
      yield loopOrg(nodes)
  orgs