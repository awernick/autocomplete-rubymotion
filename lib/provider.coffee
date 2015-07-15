fs = require 'fs'
path = require 'path'

module.exports =
  selector: '.source.ruby'
  disableForSelector: '.source.ruby .comment'

  getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
    completions = []

    if isCompletingFunction = @isCompletingFunction({scopeDescriptor})
      completions = completions.concat(@getMethodCompletions({scopeDescriptor, prefix}))

    if isCompletingConstant = @isCompletingConstant({scopeDescriptor})
      completions = completions.concat(@getConstantCompletions({prefix}))

    completions
    # @getConstructCompletions(request)

  # getConstructCompletions: (request) ->
  #   return


  loadProperties: ->
    @functions = {}
    fs.readFile path.resolve(__dirname, '..', 'completions.json'), (error, content) =>
      {@functions, @methods, @constants, @classes} = JSON.parse(content) unless error?
      return

  isCompletingFunction: ({scopeDescriptor}) ->
    scopes = scopeDescriptor.getScopesArray()
    return hasScope(scopes, 'meta.function.method')

  isCompletingConstant: ({scopeDescriptor}) ->
    scopes = scopeDescriptor.getScopesArray()
    return hasScope(scopes, 'support.class.ruby') || hasScope(scopes, 'variable.other.constant.ruby')

  getCompletions: ({prefix}) ->
    completions = []
    for constant, type of @constants when stringContains(prefix, constant)
      completions.push(@buildConstantCompletion(prefix, constant))
    completions

  getMethodCompletions: ({scopeDescriptor, prefix}) ->
    completions = []
    for method, {args} of @methods when stringContains(prefix, method)
      completions.push(@buildMethodCompletion(prefix, method, args))
    completions

  getConstantCompletions: ({prefix}) ->
    completions = []
    for constant, type of @constants when stringContains(prefix, constant)
      completions.push(@buildConstantCompletion(prefix, constant))
    completions

  buildMethodCompletion: (prefix, method, args) ->
    temp = method.split(':')
    snippet = ''
    i = 0
    for key of args
      snippet += "#{temp[i]}"
      snippet += if i == 0 then '(' else ': '
      snippet += "${#{i + 1}:#{key}}"
      snippet += if i+1 == Object.keys(args).length then ')' else ', '
      i++

    type: 'method'
    snippet: snippet
    displayText: method
    replacementPrefix: prefix

  buildConstantCompletion: (prefix, constant) ->
    type: 'constant'
    text: "#{constant}"
    displayText: constant
    replacementPrefix: prefix

# Helpers
hasScope = (scopesArray, scope) ->
  if scopesArray.indexOf(scope) isnt -1
    true
  else
    selected = scopesArray.filter (value) ->
      value.indexOf(scope) isnt -1
    return selected.length > 0

stringContains = (prefix, text) ->
  text.replace(/\W/g, '').toLowerCase().indexOf(prefix.toLowerCase()) == 0

  # scopesArray.indexOf(scope) isnt -1
