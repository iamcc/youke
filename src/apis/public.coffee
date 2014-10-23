Sales  = require '../models/sales'
Client = require '../models/client'
jwt    = require 'koa-jwt'
https  = require 'https'

module.exports = ->*
  switch @params.id
    when 'saleses'
      @throw 400 unless (token = @query.token)

      try
        decoded = yield jwt.decode(token)
      catch e
        console.error e
        @throw 401

      saleses = yield Sales.find({tid: decoded.tid, status: 1}).select('name mobile avatar').exec()
      return @body =
        user: decoded
        saleses: saleses
    when 'test.chat'
      tid = '5236b51da8b3ac3bcf000020'
      appid = 'wx12982029cc4dd55c'
      appsecret = 'eeb3a8c92d92c2732ce33c6288ac8513'
      redirect_uri = encodeURIComponent 'http://dev.youke.aimapp.net/api/public/test.chat'
      auth_url = "https://open.weixin.qq.com/connect/oauth2/authorize?appid=#{appid}&redirect_uri=#{redirect_uri}&response_type=code&scope=snsapi_base&state=1#wechat_redirect"

      return @body = '...' if not @query.code and @query.state

      if @query.code
        get = (url) ->
          (cb) ->
            https.get url, (res) ->
              data = ''
              res.on 'data', (d) -> data += d
              res.on 'end', -> cb null, data
        data = JSON.parse yield get "https://api.weixin.qq.com/sns/oauth2/access_token?appid=#{appid}&secret=#{appsecret}&code=#{@query.code}&grant_type=authorization_code"
        client = yield Client.findOne({TID: tid, OpenId: data.openid}).exec()
        client = yield Client.create({TID: tid, OpenId: data.openid}) unless client
        param = _id: client._id, tid: client.TID, sid: client.Sales
        token = jwt.sign param, 'dev.youke.aimapp.net', {expireInMinutes: 60}
        @redirect '/chat.html?token='+token
      else
        @redirect auth_url