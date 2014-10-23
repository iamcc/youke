var g = require('gulp'),
    gp = require('gulp-load-plugins')()

g.task('clean', function() {
  return g.src(['static/index.html', 'static/dist/*'], {
      read: false
    })
    .pipe(gp.clean())
})

g.task('build:scripts', function() {
  return g.src('static/src/**/*.coffee')
    .pipe(gp.coffeeEs6({
      bare: true
    }).on('error', console.log))
    .pipe(gp.concat('app.js'))
    .pipe(gp.ngAnnotate())
    .pipe(gp.uglify())
    .pipe(gp.rev())
    .pipe(g.dest('static/dist'))
})

g.task('build:chat', function() {
  return g.src('static/src/chat.js')
    .pipe(gp.uglify())
    .pipe(gp.rev())
    .pipe(g.dest('static/dist'))
})

g.task('inject:chat', ['build:chat'], function() {
  return g.src('static/chat-src.html')
    .pipe(gp.inject(g.src('static/dist/chat-*', {read: false}), {ignorePath: 'static'}))
    .pipe(gp.htmlmin({collapseWhitespace: true}))
    .pipe(gp.rename('chat.html'))
    .pipe(g.dest('static'))
})

g.task('build:templates', function() {
  return g.src('static/src/**/*.html')
    .pipe(gp.htmlmin({
      collapseWhitespace: true
    }))
    .pipe(gp.ngtemplate({
      module: 'app.templates'
    }))
    .pipe(gp.concat('template.js'))
    .pipe(gp.uglify())
    .pipe(gp.rev())
    .pipe(g.dest('static/dist'))
})

g.task('build:styles', function() {
  return g.src('static/src/**/*.css')
    .pipe(gp.concat('app.css'))
    .pipe(gp.cssmin())
    .pipe(gp.rev())
    .pipe(g.dest('static/dist'))
})

g.task('inject:index', ['clean', 'build:scripts', 'build:templates', 'build:styles'], function() {
  return g.src('static/index-src.html')
    .pipe(gp.inject(g.src(['static/dist/*', '!static/dist/chat-*'], {
      read: false
    }), {
      ignorePath: 'static'
    }))
    .pipe(gp.htmlmin({
      collapseWhitespace: true
    }))
    .pipe(gp.rename('index.html'))
    .pipe(g.dest('static'))
})

g.task('build:server:scripts', function() {
  return g.src('src/**/*.coffee')
    .pipe(gp.coffeeEs6({
      bare: true
    }).on('error', console.log))
    .pipe(g.dest('lib'))
})

g.task('default', ['inject:index', 'inject:chat', 'build:server:scripts'], function() {
  g.watch(['static/*-src.html', 'static/src/**/*'], ['inject:index', 'inject:chat'])
  g.watch(['src/**/*.coffee'], ['build:server:scripts'])
})