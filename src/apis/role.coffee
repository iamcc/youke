Role   = require '../models/role'
Sales  = require '../models/sales'
config = require '../config'

module.exports =
  list: ->*
    @checkAdmin()
    @body = yield Role
      .find({tid: @user.tid})
      .populate({path: 'saleses', select: 'name status', match: {status: $ne: -1}})
      .exec()
  show: ->*
    @checkAdmin()
    role = yield Role.find({tid: @user.tid, _id: @params.id}).exec()
    @throw 404 unless role

    @body = role
  create: ->*
    @checkAdmin()
    role            = new Role
    role.tid        = @user.tid
    role.name       = @request.body.name
    role.permission = @request.body.permission

    yield Role.create role
    @body = role
  update: ->*
    @checkAdmin()
    role = yield Role.findOne({tid: @user.tid, _id: @params.id}).exec()
    @throw 404 unless role

    update =
      name       : @request.body.name
      permission : @request.body.permission

    yield role.update(update).exec()
    @body = 1
  remove: ->*
    @checkAdmin()
    role = yield Role.findOne({tid: @user.tid, _id: @params.id}).populate({path: 'saleses', match: {status: $ne: -1}, options: {limit: 1}}).exec()
    @throw 404 unless role
    @throwMsg 403, 'has saleses' if role.saleses.length

    role.remove()
    @body = 1