app.controller 'handoverCtrl', ($scope, $modalInstance, Sales, sales) ->
  $scope.sales   = {}
  $scope.saleses = []

  Sales.query (data) ->
    $scope.saleses = data.filter (s) -> s._id isnt sales._id and s.status is 1

  $scope.ok = ->
    if cb then cb $scope.sales._id
    else Sales.handover {_id: sales._id}, {sales: $scope.sales._id}
    $modalInstance.close ''
  $scope.cancel = ->
    $modalInstance.dismiss ''