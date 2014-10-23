_         = require 'underscore'
thunkify  = require 'thunkify'
config    = require '../config'
Sales     = require '../models/sales'
Role      = require '../models/role'
Client    = require '../models/client'
ClientLog = require '../models/clientLog'
Org       = require '../models/organization'

module.exports =
  show: ->*
    switch @params.id
      when 'me'
        sales = @user if @user.role is config.admin_role
        sales ?= (
          yield Sales
            .findById @user._id
            .populate 'role', 'name'
            .populate 'org', 'name'
            .exec()
        ).toObject()
        if sales.role isnt config.admin_role
          clients = yield Client.find({Sales: @user._id}).exec()
          sales.client =
            total: clients.length
            follow: clients.filter((c)->c.Status is '跟进中').length
            sign: clients.filter((c)->c.Status is '已签约').length
        return @body = _.omit sales, 'passwordHash', 'forget', 'token'

    @checkAdmin()
    sales = yield Sales
      .findOne({tid: @user.tid, _id: @params.id, status: $ne: -1})
      .select '-passwordHash -forget'
      .populate([
        {path: 'role', select: 'name'}
        {path: 'org', select: 'name'}
      ])
      .exec()
    @throw 404 unless sales
    @body = sales
  list: ->*
    @checkAdmin()
    @body = yield Sales
      .find {tid: @user.tid, status: $ne: -1}
      .select 'name avatar org status'
      .populate 'org', 'name'
      .exec()
  create: ->*
    @checkAdmin()
    params = @request.body
    sales  = new Sales
      tid    : @user.tid
      tname  : @user.tname
      name   : params.name
      mobile : params.mobile
      role   : params.role
      org    : params.org

    params.password = params.passwordConfirmation = _random 6 if params.pwdType is 'random'

    sales.password             = params.password
    sales.passwordConfirmation = params.passwordConfirmation

    @throwMsg 400, 'mobile has existed' if (yield Sales.findOne({tid: @user.tid, mobile: params.mobile, status: $ne: -1}).exec())
    @throwMsg 400, 'role is not exists' unless (yield Role.findOne({tid: @user.tid, _id: params.role}).exec())
    @throwMsg 400, 'organization is not exists' unless (yield Org.findOne({tid: @user.tid, _id: params.org}).exec())

    yield sales.persist()
    @body = _.omit sales.toObject(), 'passwordHash', 'forget', 'token'
  update: ->*
    tid    = @user.tid
    sid    = @params.id
    act    = @query.act
    params = @request.body

    if @user.role isnt config.admin_role
      switch sid
        when 'save' then return yield updateBasic.call @
        when 'set_push' then return yield updatePush.call @

    @checkAdmin()

    return yield resetPassword.call @ if act is 'reset_password'

    sales = yield Sales.findOne({tid: tid, _id: sid, status: $ne: -1}).exec()
    if not sales then @throw 404

    switch act
      when 'set_status' then return yield setStatus.call @, sales
      when 'handover' then return yield handover.call @, sales

    @throwMsg 400, 'role has not found' unless (yield Role.findOne({tid: tid, _id: params.role}).exec())
    @throwMsg 400, 'organization has not found' unless (yield Org.findOne({tid: tid, _id: params.org}).exec())

    sales.name = params.name
    sales.role = params.role
    sales.org  = params.org

    yield sales.persist()
    @body = ''
  remove: ->*
    @throw 404 unless (sales = yield Sales.findOne({tid: @user.tid, _id: @params.id, status: $ne: -1}).exec())
    @throwMsg 403, 'clients is not empty' if (yield Client.findOne({TID: @user.tid, Sales: @params.id}).exec())
    sales.status = -1
    yield sales.persist()
    @body = ''

#=================================================================

_random = (len) -> (Math.random()+'').slice(-len)

updateBasic = ->*
  avatar = @request.body.avatar
  name = @request.body.name
  sales = yield Sales.findById(@user._id).exec()

  @throw 404 unless sales

  sales.avatar = avatar
  sales.name = name
  yield sales.persist()

  @body = 1

updatePush = ->*
  isPush = !!@request.body.isPush
  sales = yield Sales.findById(@user._id).exec()

  @throw 404 unless sales

  sales.isPush = isPush
  yield sales.persist()

  @body = 1

resetPassword = ->*
  ids    = @params.id.split ','
  params = @request.body

  if params.pwdType is 'random'
    params.password = params.passwordConfirmation = _random 6

  for id in ids
    sales = yield Sales.findById(id).exec()
    if sales
      sales.password             = params.password
      sales.passwordConfirmation = params.passwordConfirmation
      yield sales.persist()

  @body = 1

setStatus = (sales) ->*
  status = parseInt @query.status
  @throwMsg 403, 'not validate status' if status not in [0, 1]
  @throwMsg 403, 'clients is not empty' if status isnt 1 and (yield Client.findOne({TID: @user.tid, Sales: @params.id}).exec())
  sales.status = status
  yield sales.persist()
  @body = 1

handover = (sales) ->*
  @throwMsg 400, 'must be another sales' if @request.body.sales is @params.id
  @throwMsg 400, 'new sales has not found' if not (yield Sales.findOne({tid: @user.tid, _id: @request.body.sales, status: 1}).exec())

  query = TID: @user.tid, Sales: @params.id

  if @query.custom
    @throwMsg 400, 'client ids is required' unless @request.body.cids
    query._id = $in: @request.body.cids

  clients = yield Client.find(query).select('_id').exec()
  num     = yield Client.update(query, {Sales: @request.body.sales}, {multi: true}).exec()

  toSales = yield Sales.findById(@request.body.sales).select('name').exec()

  if num > 0 then clients.forEach (client) =>
    ClientLog.create {
      tid    : @user.tid
      cid    : client._id
      sid    : toSales._id
      sname  : toSales.name
      sid2   : sales._id
      sname2 : sales.name
      type   : '交接'
    }, (err) -> console.log 'handover', err if err
  @body = num