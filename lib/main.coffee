module.exports =
  instance: null

  activate: (@state) ->
    ProjectChecker = require('./project-checker.coffee')
    @instance = new ProjectChecker

  serialize: ->
    @state

  provideSpellCheck: ->
    @instance

  deactivate: ->
    @instance?.deactivate()
