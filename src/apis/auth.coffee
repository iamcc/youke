jwt    = require('koa-jwt')
Sales  = require '../models/sales'
config = require '../config'
_      = require 'underscore'
sms    = require '../libs/sms'

module.exports =
  check : jwt({secret: config.jwt_secret})
  login : ->*
    @throw 400 unless @request.body

    sales = yield Sales.findOne {
      tid    : @request.body.tid
      mobile : @request.body.mobile
      status : 1
    }
    .exec()
    @throw 401 unless sales and (yield sales.checkPassword @request.body.password)

    user  = _.pick sales, '_id', 'name', 'tid', 'role'
    token = jwt.sign user, config.jwt_secret, {expiresInMinutes: config.jwt_expires}

    sales.update({
      lastLoginedAt : Date.now()
      lastLoginedIP : @headers['x-real-ip'] or @ip
      token         : token
    }).exec()

    @body =
      token : token
      exp   : user.exp
  logout : ->*
    Sales.update({_id: @user._id}, {token: null}, ->) if @user.role isnt config.admin_role
    @body = 1
  sites : ->*
    @body = (yield Sales.find({mobile: @params.mobile}).select('-_id tid tname').exec())
  forget : ->*
    code   = (Math.random()+'').slice(-6)
    exp    = ~~(Date.now()/1000) + 5*60
    tid    = @query.tid
    mobile = @query.mobile
    sales  = yield Sales.findOne({tid: tid, mobile: mobile, status: 1}).exec()

    @throw 404 unless sales

    if @query.code
      @throwMsg 400, 'code not match' unless sales.forget and @query.code is sales.forget.code
      @throwMsg 400, 'code has expired' if ~~(Date.now()/1000) > sales.forget.exp
      sales.password             = @query.pwd
      sales.passwordConfirmation = @query.pwd
      sales.forget               = null
      sales.token                = null
      yield sales.persist()
      return @body = 1

    sales.forget =
      code : code
      exp  : exp

    yield sales.persist()
    sms.send mobile, "验证码：#{code}，5分钟内有效。"
    @body = 1