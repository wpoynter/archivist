# This is a manifest file that'll be compiled into application.js, which will include all the files
# listed below.
#
# Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
# or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
#
# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# compiled file.
#
# Read Sprockets README (https:#github.com/rails/sprockets#sprockets-directives) for details
# about supported directives.
#
#= require jquery
#= require jquery_ujs
#= require jquery-ui/ui/jquery-1-7
#= require angular/angular
#= require angular-route/angular-route
#= require angular-messages/angular-messages
#= require angular-resource/angular-resource
#= require angular-rails-templates
#= require angular-bootstrap/ui-bootstrap-tpls
#= require angular-base64-upload
#= require angular-ui-sortable/sortable
#= require bootstrap-sass/assets/javascripts/bootstrap-sprockets
#= require socket.io-client/dist/socket.io
#= require angular-google-chart/ng-google-chart
#= require angular-tree-control/angular-tree-control
#= require angular-ui-tree/dist/angular-ui-tree
#= require angular-loading-overlay/dist/angular-loading-overlay
#= require angular-loading-overlay-spinjs/dist/angular-loading-overlay-spinjs
#= require angular-visjs/angular-vis
#= require vis/dist/vis
#= require angular-bootstrap-contextmenu/contextMenu
#
#= require lib
#= require sections
#= require_tree ./templates/

archivist = angular.module('archivist', [
  'templates',
  'ngRoute',
  'ui.bootstrap',
  'ui.sortable',
  'ui.tree',
  'googlechart',
  'treeControl',
  'bsLoadingOverlay',
  'bsLoadingOverlaySpinJs',
  'archivist.flash',
  'archivist.instruments',
  'archivist.datasets',
  'archivist.mapping',
  'archivist.build',
  'archivist.summary',
  'archivist.topics',
  'archivist.admin',
  'archivist.realtime',
  'archivist.users',
  'archivist.data_manager'
])

archivist.config([ '$routeProvider', '$locationProvider', '$rootScopeProvider',
  ($routeProvider, $locationProvider, $rootScopeProvider)->
    $routeProvider
      .when('/',
        templateUrl: 'index.html'
        controller: 'HomeController'
      )
    $locationProvider.html5Mode true
    $rootScopeProvider.digestTtl(14);
])

archivist.controller('RootController',
  [
    '$scope',
    '$location',
    'DataManager'
    'User',
  ($scope, $location, DataManager, User)->
    $scope.softwareName = 'Archivist'
    $scope.softwareVersion = window.app_version
    $scope.page ?= {}
    $scope.page['title'] = 'Home'
    $scope.isActive = (viewLocation) ->
      viewLocation == $location.path()

    $scope.user = new User(window.current_user_email)
    if $scope.user.email.length > 0
      $scope.user.sign_in()

    $scope.is_admin = ->
      $scope.user.is_admin()

    $scope.is_editor = ->
      $scope.user.is_editor()

    $scope.sign_out = ->
      $scope.user.sign_out().finally ->
        DataManager.clearCache()
])

archivist.controller('HomeController',
  [
    '$scope',
    'DataManager'
    ($scope, DataManager)->
      $scope.chart_one = {}
      $scope.chart_two = {}
      $scope.chart_three = {}
      $scope.chart_four = {}
      $scope.chart_one.type = $scope.chart_three.type = $scope.chart_four.type =  "ColumnChart"
      $scope.chart_two.type = "Histogram"
      $scope.instruments = DataManager.getInstruments {}, (res)->
        $scope.chart_one.data = {
          cols: [
            {
              id: "s",
              label: "Study",
              type: "string"
            },
            {
              id: "i",
              label: "Instruments",
              type: "number"
            }
          ]
        }
        $scope.chart_two.data = [
          [
            'Instrument',
            'Control Constructs'
          ]
        ]
        $scope.chart_three.data = {
          cols: [
            {
              id: "s",
              label: "Study",
              type: "string"
            },
            {
              id: "s",
              label: "Avg. Constructs Per Instrument",
              type: "number"
            }
          ]
        }
        $scope.chart_one.data['rows'] = []
        $scope.chart_three.data['rows'] = []
        data = {}
        for i in res
          if i.study of data
            data[i.study]['instruments'] += 1
            data[i.study]['ccs'] += i.ccs
          else
            data[i.study] =
              'instruments' : 1
              'ccs'         : i.ccs

          $scope.chart_two.data.push [
            i.title,
            i.ccs
          ]
        Object.sort(data)
        for s of data
          $scope.chart_one.data['rows'].push {
            c: [
              {v: s}, {v: data[s]['instruments']}
            ]
          }
          $scope.chart_three.data['rows'].push {
            c: [
              {v: s}, {v: data[s]['ccs'] / data[s]['instruments']}
            ]
          }
        $scope.studies = Object.keys data
      $scope.datasets = DataManager.getDatasets()
      console.log $scope

      $scope.chart_one.options =
        'title': 'Instruments'
        'legend':
          'position': 'none'
        'colors': ['#652C90']
      $scope.chart_two.options =
        'title': 'Control Construct Distribution'
        'legend':
          'position': 'none'
        'colors': ['#FBAF3F']
      $scope.chart_three.options =
        'title': 'Avg. Constructs per Instrument'
        'legend':
          'position': 'none'
        'colors': ['#00ADEF']
  ]
)

archivist.directive 'notices', ->
  {
    templateUrl: 'partials/notices.html'
  }

archivist.directive 'breadcrumb', ->
  {
    templateUrl: 'partials/breadcrumb.html'
  }

archivist.directive 'ngFileModel', [
  '$parse'
  ($parse) ->
    {
      restrict: 'A'
      link: (scope, element, attrs) ->
        model = $parse(attrs.ngFileModel)
        isMultiple = attrs.multiple
        modelSetter = model.assign
        element.bind 'change', ->
          values = []
          angular.forEach element[0].files, (item) ->
            values.push item

          scope.$apply ->
            if isMultiple
              modelSetter scope, values
            else
              modelSetter scope, values[0]

    }
]

archivist.run(['$rootScope', 'Flash', 'RealTimeConnection', 'bsLoadingOverlayService',
  ($rootScope, Flash, RealTimeConnection, bsLoadingOverlayService)->
    bsLoadingOverlayService.setGlobalConfig {
      templateUrl: 'bsLoadingOverlaySpinJs',
      activeClass: 'loading'
    }

    Array::unique = ->
      output = {}
      output[@[key]] = @[key] for key in [0...@length]
      value for key, value of output

    Array::select_resource_by_id = (ref_id)->
      (@[key] for key in [0...@length] when @[key].id == ref_id)[0]

    Array::get_index_by_id = (ref_id)->
      (key for key in [0...@length] when @[key].id == ref_id)[0]

    Array::select_resource_by_id_and_type = (ref_id, ref_type)->
      (@[key] for key in [0...@length] when @[key].id == ref_id and @[key].type == ref_type)[0]

    Array::get_index_by_id_and_type = (ref_id, ref_type)->
      (key for key in [0...@length] when @[key].id == ref_id and @[key].type == ref_type)[0]

    Array::clean = ->
      (val for val in @ when val? and val isnt '')

    Array::sort_by_property = (prop = 'label')->
      sorter = (a, b)->
        re = /([^-^_\d]+)|([^-^_\D]+)/
        a_pieces = a[prop].split(re).clean()
        b_pieces = b[prop].split(re).clean()
        limit = if a_pieces.length > b_pieces.length then b_pieces.length else a_pieces.length

        for i in [0...limit]
          a_pieces[i] = parseInt a_pieces[i] if !isNaN a_pieces[i]
          b_pieces[i] = parseInt b_pieces[i] if !isNaN b_pieces[i]
          if a_pieces[i] == b_pieces[i]
            continue
          if a_pieces[i] > b_pieces[i]
            return 1
          else
            return -1

        if a_pieces.length > b_pieces.length
          return 1
        if a_pieces.length < b_pieces.length
          return -1

        return 0

      return @concat().sort(sorter)

    Object.lower_everything = (obj)->
      target = {}
      for k of obj
        if obj.hasOwnProperty k
          if typeof k == "string"
            target[k.toLowerCase()] = if typeof obj[k] == 'string' then obj[k].toLowerCase() else obj[k]
          else
            target[k] = if typeof obj[k] == 'string' then obj[k].toLowerCase() else obj[k]
      target

    Object.sort = (obj)->
      newObj = {}
      Object.keys(obj).sort().forEach((v)->
        newObj[v] = obj[v]
      )
      newObj

    String::replaceAll = (search, replacement) ->
      target = this
      target.replace(new RegExp(search, 'g'), replacement)

    String::pascal_case_to_underscore = ->
      target = this
      target.replace(/([A-Z])/g, (x,y) -> "_"+y.toLowerCase()).replace /^_/, ''

    String::underscore_to_pascal_case = ->
      target = this.capitalizeFirstLetter()
      target.replace /_(.)/g, (x,y) -> y.toUpperCase()

    String::capitalizeFirstLetter = ->
      target = this
      target.charAt(0).toUpperCase() + target.slice(1)

    Flash.set_scope $rootScope

    $rootScope.publish_flash = ->
      Flash.publish($rootScope)

    $rootScope.$on('$routeChangeSuccess', ->
      $rootScope.publish_flash()
    )
    $rootScope.publish_flash()

    $rootScope.page = {title: 'Home'}

    $rootScope.realtimeStatus = false

    $rootScope.range = (i)->
      (num for num in [1..i])
])

archivist.filter 'capitalize', ->
  (input)->
    if (!!input) then input.charAt(0).toUpperCase() + input.substr(1).toLowerCase() else ''

archivist.filter 'prettytype', ->
  ref = {
    'ResponseDomainCode'      :     'Code',
    'ResponseDomainDatetime'  :     'Datetime',
    'ResponseDomainNumeric'   :     'Numeric',
    'ResponseDomainText'      :     'Text',
    'Category'                :     'Category',
    'Categories'              :     'Categories',
    'CodeList'                :     'Code List',
    'QuestionGrid'            :     'Grid',
    'QuestionItem'            :     'Item'
  }
  (input)->
    if input.charAt(input.length - 1) == 's'
      plural = true
      input = input.slice 0, -1
    else
      plural = false

    if plural
      ref[input] + 's'
    else
      ref[input]

archivist.directive 'convertToNumber', ->
  {
    require: 'ngModel'
    link: (scope, element, attrs, ngModel) ->
      ngModel.$parsers.push (val) ->
        parseInt val, 10
      ngModel.$formatters.push (val) ->
        '' + val
      return

  }
