module.exports =
  instance: null

  activate: (@state) ->

  serialize: ->
    @state

  provideSpellCheck: ->
    require.resolve './project-checker.coffee'

  deactivate: ->
    return
