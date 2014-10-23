angular.module 'app'
.directive 'uploader', ($http) ->
  restrict : 'A'
  scope    :
    onSuc : '&'
    onErr : '&'
  link : (scope, el, attrs) ->
    el.bind 'change', ->
      fd = new FormData
      fd.append 'file', el[0].files[0]

      $http.post attrs.url, fd, {
        transformRequest : angular.identity
        headers          : 'Content-type'   : undefined
      }
      .success scope.onSuc()
      .error scope.onErr()