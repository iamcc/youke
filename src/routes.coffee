module.exports = (app) ->
  config = require './config'
  jwt    = require('koa-jwt')
  Tenant = require './models/tenant'
  auth   = require './apis/auth'

  app.get '/test/admin', ->*
    t = yield Tenant.findOne({TID: '5236b51da8b3ac3bcf000020', ModuleID: 11}).exec()

    user =
      tid   : '5236b51da8b3ac3bcf000020'
      tname : '精准分众网络'
      name  : 'Admin'
      role  : config.admin_role

    token = jwt.sign user, config.jwt_secret, {expiresInMinutes: 200}
    @body =
      token : token
      user  : user

  app.get '/api/login/:mobile', auth.sites
  app.post '/api/login', auth.login
  app.get '/api/forget', auth.forget
  app.post '/api/logout', auth.check, auth.logout
  app.post '/api/upload', auth.check, require './apis/upload'
  app.get '/api/public/:id', require './apis/public'

  app.all '/api/:controller/:id?', auth.check, require('./apis')

  app.use ->*
    @type = 'html'
    @body = require('fs').readFileSync __dirname+'/../static/index.html'