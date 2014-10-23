angular.module('app').directive 'ccTree', ($timeout) ->
  return {
    priority : 500
    restrict : 'EA'
    scope    :
      data         : '='
      selectedNode : '='
      onSelect     : '&'
    link : (scope, el, attrs) ->
      _findNode = (nodes, id) ->
        for node in nodes
          if node._id is id then return node
          if node.nodes
            n = _findNode node.nodes, id
            if n then return n
      onNodeSelected = (e, node) ->
        node = _findNode scope.data, node._id
        scope.onSelect() e, node
      opts =
        data           : angular.copy(scope.data)
        onNodeSelected : onNodeSelected
      $(el).treeview(opts)

      scope.$watch 'data', (val) ->
        opts =
          data : angular.copy(scope.data)
        $(el).treeview(opts)
        $timeout ->
          onNodeSelected {}, scope.data.selectedNode if scope.data and scope.data.selectedNode
        , 0
      , true
  }