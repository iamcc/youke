app.controller 'orgCtrl', ($scope, $modalInstance, org, type) ->
  $scope.pOrg = angular.copy org
  $scope.org  = if type is '添加' then {} else org
  $scope.type = type

  $scope.ok = ->
    $modalInstance.close $scope.org
  $scope.cancel = ->
    $modalInstance.dismiss 'cancel'