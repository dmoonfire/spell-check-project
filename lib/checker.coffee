spellchecker = require 'spellchecker'

class Checker
  spellchecker: null

  constructor: (@editor) ->
    console.log("initializing spell check en-us", @editor)
    console.log("spell", spellchecker)
    @spellchecker = new spellchecker.Spellchecker
    console.log("dictionaries", spellchecker.getAvailableDictionaries())
    @spellchecker.setDictionary("en_US", "/usr/share/hunspell/")
    console.log("init'd", @spellchecker)

  deactivate: ->
    console.log("deactivating en-us")

  getMispellingRanges: (text) ->
    console.log("getMispellingRanges", text)
    @spellchecker.checkSpelling(text)

module.exports = Checker
