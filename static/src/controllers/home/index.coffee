app.config ($stateProvider) ->
  $stateProvider.state 'home', {
    url         : '/'
    templateUrl : 'controllers/home/view.html'
    controller  : ($rootScope, $scope, $http, $modal, $window, $sanitize, $q, $timeout, Org, Sales, Role, Client) ->
      $rootScope.title    = 'Home Index'
      $scope.selectedNode = null
      $scope.orgSaleses   = []
      $scope.checkedAll   = false

      $rootScope.$on 'reloadTree', ->
        $scope.reloadTree()

      $scope.checkAll = ->
        $scope.checkedAll = !$scope.checkedAll
        $scope.orgSaleses.forEach (sales) -> sales.checked = $scope.checkedAll

      $scope.checkedSales = ->
        saleses           = $scope.orgSaleses.filter (sales) -> sales.checked
        $scope.checkedAll = $scope.orgSaleses.length and saleses.length is $scope.orgSaleses.length
        !saleses.length

      _concatSales = (node) ->
        stack   = if node then [node] else node.nodes
        saleses = []

        while n = stack.shift()
          saleses = saleses.concat n.saleses if n.saleses
          stack   = stack.concat n.nodes if n.nodes
        saleses

      $scope.selectNode = (e, node) ->
        $scope.selectedNode = node
        $scope.orgSaleses   = angular.copy _concatSales node
        $scope.$apply()

      $scope.delOrg = ->
        if not $scope.selectedNode._id then return alert '不能删除 '+$scope.selectedNode.text
        if $window.confirm "确认删除[#{$scope.selectedNode.text}]?"
          Org.delete _id: $scope.selectedNode._id, ->
            $rootScope.$emit 'reloadTree'
            $rootScope.$emit 'getOrgs'

      $scope.showOrgModal = (type)->
        if type is '修改' and not $scope.selectedNode._id then return alert '不能修改 '+$scope.selectedNode.text

        modal = $modal.open {
          templateUrl : 'controllers/home/orgModal.html'
          resolve     :
            org  : -> angular.copy $scope.selectedNode
            type : -> type
          controller : 'orgCtrl'
        }
        modal.result.then (rst) ->
          org = new Org {
            name : rst.text
          }

          if type is '添加'
            org.parent = $scope.selectedNode._id
            p = org.$save()
          else
            org.id = rst._id
            p = org.$save()

          p.then ->
            $rootScope.$emit 'getOrgs'
            $rootScope.$emit 'reloadTree'

        , (msg)->

      Org.getTree (orgs) ->
        $scope.tree = [{
          id    : null
          text  : $rootScope.myInfo.tname
          nodes : orgs
        }]
        $scope.selectedNode = $scope.tree[0]

      $scope.reloadTree = ->
        $scope.tree[0].nodes = Org.getTree ->
          $scope.tree.selectedNode = angular.copy $scope.selectedNode

      $scope.showRoleListModal = ->
        modal  = $modal.open {
          size        : 'lg'
          templateUrl : 'controllers/home/roleListModal.html'
          resolve     :
            showSalesModal : -> $scope.showSalesModal
          controller  : 'roleListCtrl'
        }

      $scope.showSalesModal = (type, sales, cb) ->
        modal = $modal.open {
          templateUrl : 'controllers/home/salesModal.html'
          resolve     :
            org : -> $scope.selectedNode
            type: -> type
            sales: -> sales
          controller : 'salesCtrl'
        }
        modal.result.then (sales) ->
          sales.org  = sales.org._id
          sales.role = sales.role._id
          Sales.save {_id: sales._id}, sales, (data) ->
            $rootScope.$emit 'reloadTree'
            $rootScope.$emit 'getRoles'
            cb?()

      $scope.resetPassword = ->
        modal = $modal.open
          templateUrl : 'controllers/home/reset.html'
          resolve     :
            saleses: -> $scope.orgSaleses.filter (sales) -> sales.checked
          controller: 'resetCtrl'

      $scope.blockSales = ->
        if $window.confirm '确定停用所选帐号？'
          saleses = $scope.orgSaleses.filter (sales) -> sales.checked
          angular.forEach saleses, (sales) ->
            do (sales) ->
              Sales.block {_id: sales._id}, {}, ->
                sales.status = 0
                $rootScope.$emit 'getRoles'

      $scope.activeSales = (sales) ->
        Sales.active {_id: sales._id}, {}, ->
          sales.status = 1
          $rootScope.$emit 'getRoles'

      $scope.delSales = ->
        if $window.confirm '确定删除所选帐号？'
          promises = []
          saleses  = $scope.orgSaleses.filter (sales) -> sales.checked
          angular.forEach saleses, (sales) ->
            promises.push Sales.remove({_id: sales._id}).$promise
          $q.all(promises).then ->
            $rootScope.$emit 'reloadTree'
            $rootScope.$emit 'getOrgs'
            $rootScope.$emit 'getRoles'

      $scope.showClients = (sales) ->
        modal = $modal.open
          size        : 'lg'
          templateUrl : 'controllers/home/clientList.html'
          resolve:
            sales: -> sales
            handoverClients: -> $scope.handoverClients
          controller  : 'clientListCtrl'

      $scope.handoverClients = (sales, cb) ->
        modal = $modal.open
          templateUrl : 'controllers/home/handover.html'
          resolve:
            sales: -> sales
          controller: 'handoverCtrl'
  }