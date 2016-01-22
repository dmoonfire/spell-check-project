class ProjectChecker
  projects: {}

  constructor: ->
    console.log("activing " + @getId())

  deactivate: ->
    console.log("deactivating " + @getId())

  getId: -> "spell-check-project"
  getName: -> "Project Dictionary"
  getPriority: -> 25
  isEnabled: -> true
  getStatus: -> "Working correctly."
  providesSpelling: (buffer) ->
    project = @getProject buffer
    if not project or not project.valid
      false
    true
  providesSuggestions: (buffer) ->
    project = @getProject buffer
    if not project or not project.valid
      false
    true
  providesAdding: (buffer) -> false

  check: (buffer, text) ->
    # If we don't have language settings, we don't do anything.
    project = @getProject buffer
    if not project or not project.valid
      return {}

    # Make sure we have our regular expressions.
    if not project.ignores
      @setIgnores project

    # Check the words against the project's ignore list.
    ranges = []
    for ignore in project.ignores
      textIndex = 0
      input = text
      while textIndex < text.length
        # See if the current string has a match against the regex.
        m = input.match ignore.regex
        if not m
          break
        ranges.push {start: m.index + textIndex, end: m.index + textIndex + m[0].length }
        textIndex += m.index + textIndex + m[0].length
        input = input.substring (m.index + m[0].length)
    { correct: ranges }

  suggest: (buffer, word) ->
    # If we don't have language settings, we don't do anything.
    project = @getProject buffer
    if not project or not project.valid
      return {}

    # Make sure we have our regular expressions.
    if not project.ignores
      @setIgnores project

    # Go through and build up suggestions.
    natural = require "natural"

    # Gather up all the words that are within a given distance.
    s = []
    for ignore in project.ignores
      distance = natural.JaroWinklerDistance word, ignore.text
      if distance >= 0.9
        s.push { text: ignore.text, distance: distance }

    # Sort the results based on distance.
    keys = Object.keys(s).sort (key1, key2) ->
      value1 = s[key1]
      value2 = s[key2]
      if value1.distance != value2.distance
        return value1.distance - value2.distance
      return value1.text.localeCompare(value2.text)

    # Use the resulting keys to build up a list.
    results = []
    for key in keys
      results.push s[key].text
    results

  setIgnores: (project) ->
    project.ignores = []
    if project.json.ignoreWords
      for ignore in project.json.ignoreWords
        project.ignores.push @makeIgnore ignore

  makeIgnore: (input) ->
    m = input.match /^\/(.*)\/(\w*)$/
    if m
      # Build up the regex from the components. We can't handle "g" in the flags,
      # so quietly remove it.
      f = m[2].replace("g", "")
      r = new RegExp m[1], f
      { regex: r, text: m[1], flags: f }
    else
      # We want a case-insensitive search only if the input is in all lowercase.
      # We also use word boundaries as part of the search when they don't give
      # us terminators.
      f = ""
      if input is input.toLowerCase()
        f = "i"
      r = new RegExp ("\\b" + input + "\\b"), f
      { regex: r, text: input, flags: f }

  getProject: (buffer) ->
    # First see if we have the item already cached. If we do, then just use that.
    [projectPath, relativePath] = atom.project.relativizePath(buffer.file.path)
    if @projects.hasOwnProperty projectPath
      return @projects[projectPath]

    # We don't have it cached, so load the `language.json` into memory.
    path = require "path"
    fs = require "fs"

    try
      # See if the file doesn't exist. If it doesn't, then just cache and return
      # null value so we don't repeatedly try to load it again.
      languagePath = path.join projectPath, "language.json"
      languageStat = fs.lstatSync languagePath
      if not languageStat and not languageStat.isFile()
        @projects[projectPath] = { valid: false, json: null }
        return @projects[projectPath]

      # The file exists, so we need to load it into memory.
      console.log @getId() + ": loading " + languagePath
      jsonText = fs.readFileSync languagePath
      json = JSON.parse jsonText
      @projects[projectPath] = { valid: true, json: json }

      # Set up watching the file for changes.
      that = this
      @projects[projectPath].watcher = fs.watch languagePath, (ev, f) ->
        delete that.projects[projectPath]
    catch
      # lstatSync throws an exception, so just clear it out.
      @projects[projectPath] = { valid: false, json: null }
    return @projects[projectPath]

    # We have a `language.json`, so make sure it is loaded.
    console.log "Checking project", languagePath

module.exports = ProjectChecker
