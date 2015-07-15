fs   = require 'fs'
path = require 'path'
exec = require('child_process').exec

{SelectListView} = require 'atom-space-pen-views'

class RubyMotionSelectListView extends SelectListView

  initialize: ->
    super
    @list.addClass 'mark-active'
    @setItems @getSupportFiles()
    @initialized = true
    atom.config.observe 'autocomplete-rubymotion.supportFileDir',
      ({newVal, oldVal}) => @buildMotionPath()

  viewForItem: (version) ->
    element = document.createElement 'li'
    element.textContent = version
    element

  selectItemView: (view) ->
    super
    version = @getSelectedItem()

  confirmed: (version) ->
    @confirming = true
    script = path.resolve __dirname, '..', 'completion_generator.rb'
    support_dir = path.resolve @motion_path, version, 'Bridgesupport'
    exec "#{script} #{support_dir}", (err, stderr, stdout) ->
      throw err if err != null

    @cancel()
    @confirming = false

  cancelled: ->
    @panel?.destroy()

  attach: ->
    @panel ?= atom.workspace.addModalPanel(item: this)
    @selectItemView @list.find 'li:last'
    @selectItemView @list.find '.active'
    @focusFilterEditor()

  getSupportFiles: ->
    @buildMotionPath()
    @getDirectories(@motion_path)

  buildMotionPath: ->
    tmp = atom.config.get('autocomplete-rubymotion.supportFileDir')
    @motion_path = path.resolve(tmp, 'data/ios')

  getDirectories: (srcpath) ->
    fs.readdirSync(srcpath).filter (file) ->
      fs.statSync(path.join(srcpath, file)).isDirectory();

module.exports = RubyMotionSelectListView
