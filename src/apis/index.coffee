Sales  = require '../models/sales'
config = require '../config'

module.exports = ->*
  try
    controller = require('./' + @params.controller)
    id         = @params.id
    method     = @method.toLowerCase()
  catch e
    console.log e
    return @throw 404

  if @user.role isnt config.admin_role
    sales = yield Sales.findById(@user._id).select('status token').exec()
    token = @headers.authorization.split(' ')[1]
    @throw 401 unless sales.status is 1 and sales.token is token

  if method is 'get'
    action = if id then 'show' else 'list'
  else if method is 'post'
    action = if id then 'update' else 'create'
  else if method is 'delete' then action = 'remove'

  @throw 405 unless action and controller[action]

  yield controller[action].call @