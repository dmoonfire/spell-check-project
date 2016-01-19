spellchecker = require 'spellchecker'

class Checker
  spellchecker: null

  constructor: (@editor) ->
    console.log("initializing spell check en-us", @editor)
    console.log("spell", spellchecker)
    @spellchecker = new spellchecker.Spellchecker
    @spellchecker.setDictionary("en_US", spellchecker.getAvailableDictionaries())
    console.log("init'd", @spellchecker)

  deactivate: ->
    console.log("deactivating en-us")

module.exports = Checker
