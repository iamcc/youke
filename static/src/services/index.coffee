angular.module 'app'
  .factory 'Sales', ($resource) ->
    $resource '/api/sales/:_id', {_id:'@id'}, {
      resetPassword:
        method: 'POST', params: {act: 'reset_password'}
      block:
        method: 'POST', params: {act: 'set_status', status: 0}
      active:
        method: 'POST', params: {act: 'set_status', status: 1}
      handover:
        method: 'POST', params: {act: 'handover'}
    }
  .factory 'Org', ($resource) ->
    $resource '/api/org/:_id', {_id:'@id'}, {
      getTree:
        method: 'GET', params: {tree: 1}, isArray: true
    }
  .factory 'Role', ($resource) ->
    $resource '/api/role/:_id', {_id:'@id'}
  .factory 'Client', ($resource) ->
    $resource '/api/client/:_id', {_id:'@id'}, {
      getSalesClients:
        method: 'GET', params: {_id: 'sales_clients'}
      getLogs:
        method: 'GET', params: {_id: 'get_logs'}
      getMessages:
        method: 'GET', params: {_id: 'get_messages'}, isArray: true
    }