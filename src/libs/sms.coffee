request = require 'request'
config  = require '../config'

reg     = /<string xmlns="http:\/\/tempuri.org\/">(.*)<\/string>/ig

module.exports =
  send: (mobile, content, cb) ->
    sn      = config.sms_sn
    pwd     = config.sms_pwd_md5
    content = escape "#{content} [微客通]"
    url     = "http://sdk105.entinfo.cn/webservice.asmx/gxmt?sn=#{sn}&pwd=#{pwd}&mobile=#{mobile}&content=#{content}&ext=&stime=&rrid="

    request url, (err, resp, body) ->
      code = reg.exec body
      if resp.statusCode isnt 200 or not code
        return cb? new Error('send msg error: ' + mobile ' , ' + resp.statusCode ' , ' + body)
      cb? null, code[1]