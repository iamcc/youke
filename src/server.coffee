config = require './config'
app    = require('koa')()

app.use (next) ->*
  try
    yield next
  catch e
    console.log e

    @status = e.status or 500

    if e.name is 'ValidationError'
      @status = 400
      errs    = []
      for k, err of e.errors
        errs.push String(err)
      @body = errs.join(', ')

app.use (next) ->*
  @checkAdmin = ->
    @throw 403 if @user.role isnt config.admin_role

  @throwMsg = (code, msg) ->
    @body = msg
    @throw code

  yield next

app.use(require('koa-body')({multipart:true}))
app.use(require('koa-router')(app))
app.use(require('koa-static')(__dirname + '/../static'))

require('./routes')(app)

app.listen 3000