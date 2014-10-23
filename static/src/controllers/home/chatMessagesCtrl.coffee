app.controller 'chatMessageCtrl', ($scope, $modalInstance, Client, client) ->
  $scope.client = client
  param =
    sid: client.Sales
    cid: client._id
  $scope.messages = Client.getMessages param, (data) ->
    $scope.isLast = !data.length
  $scope.loadMore = ->
    param.lid = $scope.messages[0]._id
    Client.getMessages param, (data) ->
      $scope.isLast = !data.length
      $scope.messages = data.concat $scope.messages
  $scope.cancel = -> $modalInstance.dismiss null