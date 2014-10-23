app.controller 'clientListCtrl', ($scope, $modal, $modalInstance, Client, Sales, sales, handoverClients) ->
  $scope.opts =
    page : 1
    num  : 5
  $scope.sales       = sales
  $scope.clients     = Client.getSalesClients {sid: sales._id, p: $scope.opts.page, n: $scope.opts.num}
  $scope.pageChanged = ->
    Client.getSalesClients {sid: sales._id, p: $scope.opts.page, n: $scope.opts.num}, (data) ->
      $scope.clients = data
  $scope.handoverClients = ->
    handoverClients sales, (toSalesId) ->
      cids = $scope.clients.data
        .filter (c) -> c.checked
        .map (c) -> c._id
      Sales.handover {_id: sales._id, custom: 1}, {sales: toSalesId, cids: cids}, ->
        $scope.pageChanged()
  $scope.showFollowUpRecords = (client) ->
    modalRecord = $modal.open
      templateUrl : 'controllers/home/followRecords.html'
      resolve:
        client: -> client
      controller  : 'followRecordsCtrl'
  $scope.showChatMessages = (client) ->
    modalChat = $modal.open
      templateUrl: 'controllers/home/chatMessages.html'
      resolve:
        client: -> client
      controller: 'chatMessageCtrl'

  $scope.cancel = -> $modalInstance.dismiss null