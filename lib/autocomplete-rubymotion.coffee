provider = require './provider'
{CompositeDisposable} = require 'atom'

module.exports =
  activate: ->
    provider.loadProperties()
    @disposables = new CompositeDisposable
    @disposables.add atom.commands.add 'atom-workspace', "RubyMotion: Generate Snippets", @createSelectListView

  createSelectListView: ->
    RubyMotionSelectListView = require './rubymotion-select-list-view'
    rubyMotionSelectListView = new RubyMotionSelectListView @
    rubyMotionSelectListView.attach()

  getProvider: -> provider

  config:
    supportFileDir:
      title: 'RubyMotion Install Folder'
      description: 'This is used to generate the completions for methods, constants, etc...'
      type: 'string'
      default: '/Library/RubyMotion/'
