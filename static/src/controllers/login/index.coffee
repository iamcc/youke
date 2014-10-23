app.config ($stateProvider) ->
  $stateProvider.state 'login', {
    url         : '/login?token'
    templateUrl : 'controllers/login/view.html'
    controller  : ($rootScope, $scope, $http, $state, $stateParams, $window, Sales) ->
      $rootScope.$emit 'init', $stateParams.token if $stateParams.token

      $rootScope.title = 'Login'
      # $scope.user =
      #   mobile   : ''
      #   password : ''
      # $scope.login = ->
      #   $http.post '/api/login', $scope.user
      #   .success (data) ->
      #     console.log data
  }