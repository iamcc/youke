app.controller 'salesCtrl', ($scope, $modalInstance, $rootScope, Sales, org, sales, type) ->
  $scope.type   = type
  $scope.errMsg = ''

  $scope.roles = angular.copy $rootScope.g.roles
  $scope.orgs  = angular.copy $rootScope.g.orgs

  if type is '编辑'
    $scope.sales = Sales.get _id: sales._id, ->
      $scope.sales.role = (role for role in $scope.roles when role._id is $scope.sales.role?._id)[0]
      $scope.sales.org  = (org for org in $scope.orgs when org._id is $scope.sales.org?._id)[0]
  else
    $scope.sales  =
      name     : ''
      mobile   : ''
      role     : sales?.role
      pwdType  : 'random'
      password : ''
      org      : org
    $scope.sales.role = (role for role in $scope.roles when role._id is $scope.sales.role?._id)[0]
    $scope.sales.org  = (org for org in $scope.orgs when org._id is $scope.sales.org?._id)[0]

  $scope.ok = (form)->
    return if form.$invalid
    $modalInstance.close $scope.sales
  $scope.cancel = ->
    $modalInstance.dismiss 'cancel'