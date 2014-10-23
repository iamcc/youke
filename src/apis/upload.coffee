fs = require 'fs'

module.exports = ->*
  file = @request.body.files.file
  name = file.path.split('/').slice(-1)[0]
  ext  = file.name.split('.').slice(-1)[0]
  path = "#{__dirname}/../../static/uploads/#{name}.#{ext}"
  fs.rename file.path, path, (err) -> console.log err

  @body = "http://dev.youke.aimapp.net/uploads/#{name}.#{ext}"