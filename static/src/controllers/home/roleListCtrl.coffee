app.controller 'roleListCtrl', ($scope, $modal, $modalInstance, $window, $rootScope, Role, showSalesModal) ->
  $scope.showSalesModal = showSalesModal

  $scope.editRole = (role) ->
    $scope.showRoleModal '编辑', role

  $scope.delRole = (idx, role) ->
    if $window.confirm "确认删除[#{role.name}]?"
      Role.remove _id: role._id, ->
        $rootScope.$emit 'getRoles'

  $scope.showRoleModal = (type, editRole) ->
    roleModal = $modal.open {
      size        : 'lg'
      templateUrl : 'controllers/home/roleModal.html'
      resolve     :
        type     : -> type
        editRole : -> editRole
      controller : 'roleCtrl'
    }
    roleModal.result.then (role) ->
      if role._id then p = Role.save _id: role._id, role
      else p = Role.save role

      p.$promise.then ->
        $rootScope.$emit 'getRoles'
        $rootScope.$emit 'reloadTree'

  $scope.cancel = -> $modalInstance.dismiss 'cancel'