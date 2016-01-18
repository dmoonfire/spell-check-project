module.exports =
  instance: null

  activate: (@state) ->
    Checker = require('./checker.coffee')
    @instance = new Checker state

  serialize: ->
    @state

  provideSpellCheck: ->
    @instance

  deactivate: ->
    @instance?.deactivate()
