fs = require 'fs'
path = require 'path'

module.exports =
  selector: '.source.ruby'
  disableForSelector: '.source.ruby .comment'

  getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
    return
    # @getConstructCompletions(request)

  getConstructCompletions: (request) ->
    return


  loadProperties: ->
    @functions = {}
    fs.readFile path.resolve(__dirname, '..', 'completions.json'), (error, content) =>
      {@functions, @methods, @constants, @classes} = JSON.parse(content) unless error?
      return
