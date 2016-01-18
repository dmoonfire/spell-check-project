class Checker
  constructor: (@editor) ->
    console.log("initializing spell check en-us", @editor)

  deactivate: ->
    console.log("deactivating en-us")

module.exports = Checker
