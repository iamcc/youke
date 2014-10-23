angular.module 'app.templates', []

app = angular.module 'app', ['ngResource', 'ngSanitize', 'ui.router', 'ui.bootstrap', 'app.templates']

app.config ($urlRouterProvider, $httpProvider, $locationProvider) ->
  $locationProvider.html5Mode true
  $urlRouterProvider.otherwise '/login'
  $httpProvider.interceptors.push ($window, $q, $injector, $rootScope, $location) ->
    {
      request: (config) ->
        config.headers               = config.headers or {}
        config.headers.Authorization = 'Bearer ' + $window.sessionStorage.token if $window.sessionStorage.token
        return config
      responseError: (resp) ->
        if resp.status is 400 then alert JSON.stringify(resp.data)
        if resp.status is 401
          delete $window.sessionStorage.token
          delete $rootScope.myInfo
          $injector.get('$state').go 'login'
        if resp.status is 403 then alert JSON.stringify(resp.data)
        if resp.status is 500 then alert 'server error'
        return $q.reject resp
    }
app.run ($rootScope, $http, $window, $state, $location, Sales, Role, Org) ->
  $rootScope.g = {}

  $rootScope.$on 'init', (e, token) ->
    $window.sessionStorage.token = token
    getInfo ->
      $window.sessionStorage.token = token
      $state.go 'home'
  $rootScope.$on 'getRoles', ->
    $rootScope.g.roles = Role.query()
  $rootScope.$on 'getOrgs', ->
    $rootScope.g.orgs = Org.query()

  $rootScope.logout = ->
    delete $window.sessionStorage.token
    delete $rootScope.myInfo
    $http.get "/api/logout"
    $state.go 'login'

  getInfo = (cb) ->
    Sales.get {_id: 'me'}, (data) ->
      $rootScope.myInfo = data
      $rootScope.g      =
        roles : Role.query()
        orgs  : Org.query()
      cb?()
  getInfo()

window.onload = -> angular.bootstrap document, ['app']
