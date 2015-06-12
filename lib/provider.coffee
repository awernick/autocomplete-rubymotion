fs = require 'fs'
path = require 'path'

module.exports =
  selector: '.source.ruby'
  disableForSelector: '.source.ruby .comment'

  getSuggestions: (request) ->
    completions = null

    if @isCompletingMethod(request)
      completions = (@getMethodCompletions(request))
      
    completions

  loadProperties: ->
    @functions = {}
    fs.readFile path.resolve(__dirname, '..', 'completions.json'), (error, content) =>
      {@functions, @methods, @constants, @classes} = JSON.parse(content) unless error?
      return

  isCompletingMethod: ({scopeDescriptor}) ->
    scopes = scopeDescriptor.getScopesArray()
    scopes.indexOf('source.ruby') isnt -1

  getMethodCompletions: ({prefix}) ->
    return null unless prefix

    completions = []
    for methodSelector of @methods when isPrefix(prefix, methodSelector)
      completions.push(@buildMethodCompletion(methodSelector, prefix.substr(1)))
    completions

  buildMethodCompletion: (methodSelector, prefix) ->
    completion =
      text: methodSelector
      type: 'method'
      replacementPrefix: prefix

    completion


isPrefix = (prefix, selector) ->
  selector.substr(0, prefix.length).toLowerCase() is prefix.toLowerCase()
