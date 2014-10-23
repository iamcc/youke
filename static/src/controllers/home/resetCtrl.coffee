app.controller 'resetCtrl', ($scope, $modalInstance, Sales, saleses) ->
  $scope.submiting = false
  $scope.sales =
    pwdType              : 'random'
    password             : ''
    passwordConfirmation : ''

  $scope.ok = ->
    ids = (saleses.map (sales) -> sales._id).join ','
    Sales.resetPassword {_id: ids}, $scope.sales, ->
      $modalInstance.close ''
    , -> $scope.submiting = false
  $scope.cancel = ->
    $modalInstance.dismiss ''