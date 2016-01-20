spellchecker = require 'spellchecker'

class Checker
  spellchecker: null
  id: "en-US"

  constructor: (@editor) ->
    @spellchecker = new spellchecker.Spellchecker
    success = @spellchecker.setDictionary("en_US", "/usr/share/hunspell/")
    # TODO Need to identify that this has an error if we had one.

  deactivate: ->
    console.log("deactivating en-us")

  getMispelledRanges: (text) ->
    @spellchecker.checkSpelling(text)

module.exports = Checker
