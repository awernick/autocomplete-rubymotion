fs = require 'fs'
path = require 'path'

module.exports =
  selector: '.source.ruby'
  disableForSelector: '.source.ruby .comment'

  getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
    completions = []

    if isCompletingInheritedClass = @isCompletingInheritedClass({scopeDescriptor})
      completions = completions.concat(@getClassCompletions({prefix}))

    else if isCompletingConstant = @isCompletingConstant({scopeDescriptor})
      completions = completions.concat(@getClassCompletions({prefix}))
      completions = completions.concat(@getConstantCompletions({prefix}))
      completions = completions.concat(@getFunctionCompletions({prefix}))

    # else if isCompletingMethod = @isCompletingMethod({scopeDescriptor})
    #     completions = completions.concat(@getMethodCompletions({scopeDescriptor, prefix}))

    else
      # Add methods
      completions = completions.concat(@getMethodCompletions({scopeDescriptor, prefix}))

    completions.sort()
    # @getConstructCompletions(request)

  # getConstructCompletions: (request) ->
  #   return


  loadProperties: ->
    @functions = {}
    fs.readFile path.resolve(__dirname, '..', 'completions.json'), (error, content) =>
      {@functions, @methods, @constants, @classes} = JSON.parse(content) unless error?
      return

  isCompletingMethod: ({scopeDescriptor}) ->
    scopes = scopeDescriptor.getScopesArray()
    return hasScope(scopes, 'meta.function.method')

  isCompletingConstant: ({scopeDescriptor}) ->
    scopes = scopeDescriptor.getScopesArray()
    return hasScope(scopes, 'support.class.ruby') || hasScope(scopes, 'variable.other.constant.ruby')

  isCompletingInheritedClass: ({scopeDescriptor}) ->
    scopes = scopeDescriptor.getScopesArray()
    return hasScope(scopes, 'entity.other.inherited-class.ruby')

  # getCompletions: ({prefix}) ->
  #   completions = []
  #   for constant, type of @constants when stringContains(prefix, constant)
  #     completions.push(@buildConstantCompletion(prefix, constant))
  #   completions

  getMethodCompletions: ({scopeDescriptor, prefix}) ->
    completions = []
    for method, {args} of @methods when stringContains(prefix, method)
      completions.push(@buildMethodCompletion(prefix, method, args))
    completions

  getClassCompletions: ({prefix}) ->
    completions = []
    for klass in @classes when stringContains(prefix, klass)
      completions.push(@buildClassCompletion(prefix, klass))
    completions

  getConstantCompletions: ({prefix}) ->
    completions = []
    for constant, type of @constants when stringContains(prefix, constant)
      completions.push(@buildConstantCompletion(prefix, constant))
    completions

  getFunctionCompletions: ({prefix}) ->
    completions = []
    for func, {args} of @functions when stringContains(prefix, func)
      completions.push(@buildFunctionCompletion(prefix, func, args))
    completions

  buildFunctionCompletion: (prefix, func, args) ->
    snippet = "#{func.titleize}("
    i = 0
    for key of args
      snippet += "${#{i + 1}:#{key}}"
      snippet += if i+1 == Object.keys(args).length then ')' else ', '
      i++

    type: 'function'
    snippet: snippet
    displayText: func
    replacementPrefix: prefix

  buildClassCompletion: (prefix, klass) ->
    type: 'class'
    text: "#{klass.titleize()}"
    displayText: klass.titleize()
    replacementPrefix: prefix

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
    text: "#{constant.titleize()}"
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

String.prototype.titleize =  ->
  this.charAt(0).toUpperCase() + this.slice(1)
  # scopesArray.indexOf(scope) isnt -1
