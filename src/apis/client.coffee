Client    = require '../models/client'
ClientLog = require '../models/clientLog'
Sales     = require '../models/sales'
Timeline  = require '../models/timeline'
Message   = require '../models/chatMessage'
config    = require '../config'

module.exports =
  show: ->*
    switch @params.id
      when 'my' then return yield getMyClients.call @
      when 'search' then return yield searchClient.call @
      when 'timeline' then return yield getTimeline.call @
      when 'sales_clients' then return yield getSalesClients.call @
      when 'get_logs' then return yield getClientLogs.call @
      when 'get_messages' then return yield getMessages.call @

    client = yield getClient @params.id
    yield checkClient.call @, client

    @body = client

  list: ->*
    page  = @query.p or 1
    num   = @query.n or 10
    sort  = @query.s or '-LastActiveTime'
    query = TID: @user.tid, Sales: null, Mobile: {$exists: true, $ne: ''}

    @body =
      total : yield Client.count(query).exec()
      list  : yield Client
        .find(query)
        .select('Name FaceImageUrl LastActive LastActiveTime')
        .sort(sort)
        .skip((page-1)*num)
        .limit(num)
        .exec()

  update: ->*
    switch @params.id
      when 'pick' then return yield pickClient.call @
      when 'set_status' then return yield setStatus.call @

    client = yield getClient @params.id
    yield checkClient.call @, client

    body           = @request.body

    client.Name    = body.Name
    client.RealSex = body.RealSex
    client.Mobile  = body.Mobile
    client.Tags2   = body.Tags2
    client.Memo    = body.Memo

    yield client.persist()
    @body = client

#==================================

getClient = (id) ->
  return Client.findById(id).select('-PiwikVisitorIDs -Pages').exec()

checkClient = (client) ->*
  @throw 404 unless client?.Sales?.equals(@user._id)

getMyClients = ->*
  @body = yield Client
    .find({Sales: @user._id})
    .select('Name Mobile FaceImageUrl Status LastActiveTime')
    .exec()

searchClient = ->*
  @body = yield Client
    .find {TID: @user.tid, Sales: null, Mobile: $exists: true}
    .or [
      {Name   : new RegExp(@query.q, 'ig')}
      {Mobile : new RegExp(@query.q, 'ig')}
    ]
    .select('Name FaceImageUrl LastActive LastActiveTime')
    .limit @query.n or 25
    .exec()

getTimeline = ->*
  cid    = @query.cid
  p      = @query.p or 1
  n      = @query.n or 25
  client = yield getClient cid
  yield checkClient.call @, client

  @body = yield Timeline
    .find {TID: client.TID, OpenId: client.OpenId}
    .select '-_id Name Mobile AddTime Type PiwikData.Details.SpentTime PiwikData.Details.AddTime PiwikData.Details.Title PiwikData.OS Location'
    .sort '-_AddTime'
    .skip (p-1)*n
    .limit n
    .exec()

getSalesClients = ->*
  @checkAdmin()

  sid    = @query.sid
  p      = @query.p or 1
  n      = @query.n or 10
  query  = TID: @user.tid, Sales: sid
  fields = 'Name NickName FaceImageUrl Mobile Sex RealSex Sales Status'
  sort   = '-_id'

  @body =
    total : yield Client.count(query).exec()
    data  : yield Client.find(query).select(fields).sort(sort).skip((p-1)*n).limit(n).exec()

getClientLogs = ->*
  cid   = @query.cid
  p     = @query.p or 1
  n     = @query.n or 10
  query = cid: cid
  sort  = '-_id'

  if @user.role isnt config.admin_role
    client = yield getClient cid
    yield checkClient.call @, client
  else
    @checkAdmin()

  @body =
    total : yield ClientLog.count(query).exec()
    data  : yield ClientLog.find(query).sort(sort).skip((p-1)*n).limit(n).exec()

getMessages = ->*
  @checkAdmin()

  sid = @query.sid
  cid = @query.cid
  lid = @query.lid
  n = @query.n or 10
  query =
    $or: [
      {uid: sid, toId: cid}
      {uid: cid, toId: sid}
    ]
  query._id = $lt: lid if lid
  sort = '-_id'

  @body = (yield Message.find(query).sort(sort).limit(n).exec()).reverse()

pickClient = ->*
  cid  = @query.cid
  user = yield Sales.findById(@user._id).populate('role').exec()
  @throw 403 unless user.role.permission.pickClient.checked
  if (numPerDay = user.role.permission.pickClient.numPerDay) > 0
    now      = new Date
    today    = new Date now.getFullYear(), now.getMonth(), now.getDate()
    numToday = yield ClientLog.count({tid: user.tid, sid: user._id, type: '领取', createdAt: $gte: today}).exec()
    @throwMsg 403, "can only pick clients #{numPerDay} per-day" if numToday > numPerDay
  num = yield Client.update({TID: user.tid, _id: cid, Sales: null}, {Sales: user._id}).exec()
  if num > 0 then ClientLog.create {
      tid   : @user.tid
      sid   : @user._id
      sname : @user.name
      cid   : cid
      type  : '领取'
    }, ->
  @body = num

setStatus = ->*
  statusList = ['未报备', '已报备', '跟进中', '已签约', '无效客户']
  cid        = @query.cid
  status     = @query.status

  @throwMsg 400, 'status is required' unless status

  client    = yield Client.findById(cid).exec()
  oldStatus = client.Status

  oldIdx = statusList.indexOf oldStatus
  newIdx = statusList.indexOf status

  @throwMsg 400, "operation invalid" if oldIdx >= newIdx

  checkClient.call @, client
  client.Status = status
  yield client.persist()
  if status and oldStatus isnt status then ClientLog.create {
      tid   : @user.tid
      sid   : @user._id
      sname : @user.name
      cid   : cid
      type  : '状态'
      memo  : "#{oldStatus} => #{status}"
    }, ->
  @body = 1