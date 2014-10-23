app.controller 'followRecordsCtrl', ($scope, $modalInstance, Client, client) ->
  $scope.client = client
  $scope.opts =
    page : 1
    num  : 5
  tranLog = (log) ->
    log.memo = log.memo or log.type is '交接' and "原跟踪人：#{log.sname2}" or ''
  $scope.followRecords = Client.getLogs {cid: client._id, p: $scope.opts.page, n: $scope.opts.num}, (data) ->
    data.data.forEach tranLog
  $scope.pageChanged = ->
    Client.getLogs {cid: client._id, p: $scope.opts.page, n: $scope.opts.num}, (data) -> 
      data.data.forEach tranLog
      $scope.followRecords = data
  $scope.cancel = -> $modalInstance.dismiss null