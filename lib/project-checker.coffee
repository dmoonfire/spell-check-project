class ProjectChecker
  ignores: []

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
    settings = @getProjectLanguages buffer
    settings != null

  providesSuggestions: (buffer) -> false
  providesAdding: (buffer) -> false

  check: (buffer, text) ->
    # If we don't have language settings, we don't do anything.
    settings = @getProjectLanguages buffer
    if not settings
      return {}

    ranges = []
    for ignoreRegex in @ignores
      textIndex = 0
      input = text
      while textIndex < text.length
        # See if the current string has a match against the regex.
        m = input.match ignoreRegex
        if not m
          break
        ranges.push {start: m.index + textIndex, end: m.index + textIndex + m[0].length }
        textIndex += m.index + textIndex + m[0].length
        input = input.substring (m.index + m[0].length)
    { correct: ranges }

  setIgnoreWords: (ignoreWords) ->
    @ignores = []
    if ignoreWords
      for ignore in ignoreWords
        @ignores.push @makeRegex ignore
    console.log(@getId() + ": ignore words ", @ignoreWords)

  getProjectLanguages: (buffer) ->
    [projectPath, relativePath] = atom.project.relativizePath(buffer.file.path)
    console.log "Checking project", projectPath, relativePath

  makeRegex: (input) ->
    m = input.match /^\/(.*)\/(\w*)$/
    if m
      # Build up the regex from the components. We can't handle "g" in the flags,
      # so quietly remove it.
      new RegExp m[1], m[2].replace("g", "")
    else
      # We want a case-insensitive search only if the input is in all lowercase.
      # We also use word boundaries as part of the search when they don't give
      # us terminators.
      flag = ""
      if input is input.toLowerCase()
        flag = "i"
      new RegExp ("\\b" + input + "\\b"), flag

module.exports = ProjectChecker
