angular.module('archivist.build').controller(
  'BuildCodeListsController',
  [
    '$controller',
    '$scope',
    '$routeParams',
    '$location',
    '$filter',
    'Flash',
    'DataManager',
    'RealTimeListener',
    'RealTimeLocking',
    ($controller, $scope, $routeParams, $location, $filter, Flash, DataManager, RealTimeListener, RealTimeLocking)->

      $scope.title = 'Code Lists'
      $scope.instrument_options = {
        codes: true
      }

      $scope.reset = () ->
        console.log "reset called"
        if $routeParams.code_list_id?
          $scope.current = angular.copy $scope.instrument.CodeLists.select_resource_by_id parseInt $routeParams.code_list_id
          $scope.editMode = false
          RealTimeLocking.unlock({type: $scope.current.type, id: $scope.current.id})
        null

      $scope.after_instrument_loaded = ->
        get_count_from_used_by = (cl)->
          cl.count = cl.used_by.length
          cl
        $scope.sidebar_objs = (get_count_from_used_by obj for obj in $scope.instrument.CodeLists)
        if !DataManager.CodeResolver?
          DataManager.resolveCodes()

      $controller(
        'BaseBuildController',
        {
          $scope: $scope,
          $routeParams: $routeParams,
          $location: $location,
          Flash: Flash,
          DataManager: DataManager,
          RealTimeListener: RealTimeListener,
          RealTimeLocking: RealTimeLocking
        }
      )
  ]
)