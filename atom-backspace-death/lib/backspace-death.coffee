{CompositeDisposable} = require 'atom'
fs = require 'fs'
path = require 'path'
snip = ""

KEY_CODES =
  DELETING: [8, 46] # backspace, delete
  WITH_ALT: [68, 72] # d, h
  K: 75
  X: 88

module.exports = BackspaceDeath =
  _isActive: false
  _editorEventSubscription: null
  _listeners: []

  activate: ->
    @_start()

  _start: ->
    return if @_isActive
    @_isActive = true
    @_editorEventSubscription = atom.workspace.observeTextEditors (editor) =>
      view = atom.views.getView editor
      listener = (event) => @_handleKeyDown editor, event
      view.addEventListener 'keydown', listener
      @_listeners.push [view, listener]

    @_getSnippet()

  _provide: (fileExtension) ->
      snippetPath = path.join snippetDir, "snippet.#{fileExtension}"
      new Promise (resolve, reject) ->
        fs.readFile snippetPath, (err, content) ->
          if err
            resolve ''
          else
            resolve content.toString()

  _handleKeyDown: (editor, event) ->
    if @_deletesText event then @_obliterate editor

  _deletesText: (event) ->
    (event.keyCode in KEY_CODES.DELETING) or
      (event.keyCode in KEY_CODES.WITH_ALT and event.altKey) or
      (event.keyCode in KEY_CODES.WITH_ALT and event.ctrlKey) or
      (event.keyCode == KEY_CODES.K and event.ctrlKey) or
      (event.keyCode == KEY_CODES.X and event.metaKey)

  _getSnippet: ->

    fileExtension = document.querySelector('#language-choice-box select').value

    snippetDir = path.join __dirname, '../../atom-u2i-hackathon/codeSnippets'
    snippetPath = path.join snippetDir, "snippet.#{fileExtension}"

    fs.readFile snippetPath, (err, content) ->
      if err
        snip = "error"
      else
        snip = content.toString()

  

  _obliterate: (editor) ->

    @_getSnippet()

    editor.setText(snip)
    editor.getBuffer().clearUndoStack()
    try
      editor.save()
    catch _

  deactivate: ->
    @_stop()

  _stop: ->
    return unless @_isActive
    @_isActive = false
    @_editorEventSubscription?.dispose()
    for [view, listener] in @_listeners
      view.removeEventListener 'keydown', listener
    @_listeners = []

  serialize: ->
    isActive: @_isActive
