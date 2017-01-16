{CompositeDisposable} = require 'atom'

module.exports = RandomFontSize =
  _isActive: false
  _editorEventSubscription: null
  _listeners: []
  _view: null
  _listener: null

  activate: ->
    @_start()


  _start: ->
    return if @_isActive
    @_isActive = true
    @_editorEventSubscription = atom.workspace.observeTextEditors (editor) =>
      @_view = atom.views.getView editor
      @_listener = (event) => @_handleKeyDown editor, event
      @_view.addEventListener 'keydown', @_listener
      @_listeners.push [@_view, @_listener]

  _handleKeyDown: (editor, event) ->
    if @_changeFontSize event then @_obliterate editor

  _changeFontSize: ->
    editors = document.querySelectorAll '.editor.is-focused'
    for editor in editors
      editor.style['font-size'] = @_randomNum(80) + 'px'

  _randomNum: (max) ->
    Math.floor Math.random() * max

  deactivate: ->
    @_stop()

  _stop: ->
    console.log 'RandomFontSize stopped!'
    unless @_isActive then return

    @_view.removeEventListener 'keydown', @_listener
    @_resetFontSize()
    @_isActive = false
    @_handler = null

  _resetFontSize: ->
    editors = document.querySelectorAll '.editor'
    for editor in editors
      console.log "Reset"
      editor.style['font-size'] = '14px'

  serialize: ->
    isActive: @_isActive
