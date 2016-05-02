class ProjectChecker
  projects: {}

  constructor: ->
    #console.log(@getId() + ": activing")
    return

  deactivate: ->
    #console.log(getId() + ": deactivating")
    return

  getId: -> "spell-check-project"
  getName: -> "Project Dictionary"
  getPriority: -> 25
  isEnabled: -> true
  getStatus: -> "Working correctly."
  providesSpelling: (args) ->
    project = @getProject args
    if not project or not project.valid
      false
    true
  providesSuggestions: (args) ->
    project = @getProject args
    if not project or not project.valid
      false
    true
  providesAdding: (args) ->
    project = @getProject args
    if not project or not project.valid
      false
    true

  check: (args, text) ->
    # If we don't have language settings, we don't do anything.
    project = @getProject args
    if not project or not project.valid
      return { }

    # Check the range for this dictionary.
    ranges = []
    checked = project.checker.check text
    for token in checked
      if token.status is 1
        ranges.push {start: token.start, end: token.end }
    { correct: ranges }

  checkArray: (args, words) ->
    project = @getProject args
    results = []
    if not project or not project.valid
      # We don't have a project settings, so everything is unknown.
      for word in words
        results.push null
    else
      # We have a project, so check each one directly.
      for word, index in words
        checked = project.checker.check word
        if checked[0].status is 1
          results.push true
        else
          results.push null

    # Return the results for the words, either all nulls or verified against the
    # project file.
    results

  suggest: (args, word) ->
    # If we don't have language settings, we don't do anything.
    project = @getProject args
    if not project or not project.valid
      return {}

    # Pass the suggestion request to the project which provides it in the
    # desired format.
    project.spelling.suggest word

  getAddingTargets: (args) ->
    [{sensitive: false, label: "Add to " + @getName()}]

  add: (args, target) ->
    # If we don't have language settings, then create a new one so
    # we can write it out.
    project = @getProject args
    if not project or not project.valid
      # Add the word to the new spelling manager.
      spellingManager = require "spelling-manager"
      project = { valid: true, json: {} }
      project.spelling = new spellingManager.TokenSpellingManager

      # Clear out the cache since we'll be rebuilding it after
      # the @saveProject.
      delete @projects[args.projectPath]

    # Add it to the dictionary.
    project.spelling.add target.word
    @saveProject args, project

  getProject: (args) ->
    # If there is no file, we can't find a project.
    if not args.projectPath
      return { valid: false, json: null }

    # First see if we have the item already cached. If we do, then just use that.
    if @projects.hasOwnProperty args.projectPath
      project = @projects[args.projectPath]
      return project

    # We don't have it cached, so load the `language.json` for this project root
    # so we can watch it.
    path = require "path"
    fs = require "fs"

    languagePath = path.join args.projectPath, "language.json"
    project = { valid: false, json: null }

    try
      # See if the file doesn't exist. If it doesn't, then just cache and return
      # null value so we don't repeatedly try to load it again.
      languageStat = fs.lstatSync languagePath
      if languageStat and languageStat.isFile()
        # The file exists, so we need to load it into memory.
        console.log @getId() + ": loading " + languagePath
        jsonText = fs.readFileSync languagePath
        json = JSON.parse jsonText
        project = { valid: true, json: json }

        # Set up watching the file for changes.
        that = this
        project.watcher = fs.watch languagePath, (ev, f) ->
          delete that.projects[args.projectPath]
    catch err
      # lstatSync throws an exception, so just clear it out.
      project = { valid: false, json: null, error: err }

    # Since we are creating it, we also need to set up the actual spelling. We do this
    # so (in theory) a project could then allow 'add to word' to be enabled for proejcts
    # that don't even have a file.
    spellingManager = require "spelling-manager"
    project.spelling = new spellingManager.TokenSpellingManager
    project.checker = new spellingManager.BufferSpellingChecker project.spelling

    # If we have a JSON and the known words, then add those words to the list.
    if project.json and project.json.knownWords
      project.spelling.add project.json.knownWords

    # Return the resulting project.
    @projects[args.projectPath] = project
    return project

  saveProject: (args, project) ->
    path = require "path"
    fs = require "fs"

    try
      # Create a combined list of all the words so we can write them out.
      project.json.knownWords = project.spelling.list()

      # Figure out the path and save the file. The file watcher will cause this
      # to reload.
      languagePath = path.join args.projectPath, "language.json"
      jsonText = JSON.stringify project.json, null, "\t"
      fs.writeFileSync languagePath, jsonText
    catch err
      console.error @getId(), "Could not save project file:", err

checker = new ProjectChecker()
module.exports = checker
