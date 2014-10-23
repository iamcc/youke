app.controller 'roleCtrl', ($scope, $modalInstance, type, editRole) ->
  $scope.type = type
  if editRole then $scope.role = editRole
  else
    $scope.role =
      name : ''
      mark : ''
      permission :
        onlineSales : false
        pickClient  :
          checked   : false
          numPerDay : 0
          wbbDays   : 15
          ybbDays   : 15
          gjzDays   : 15
        assignClient :
          checked : false
          protect : false
        shareClient : false

  $scope.save   = -> $modalInstance.close $scope.role
  $scope.cancel = -> $modalInstance.dismiss 'cancel'