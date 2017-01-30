{CompositeDisposable} = require 'atom'

module.exports = BackspaceFight =
  _BackspaceFightIsActive: false
  _editorEventSubscription: null
  _listeners: []
  _view: null
  _editor: null
  _listener: null
  _timer: null

  activate: ->
    @_start()

  _start: ->
    return if @_BackspaceFightIsActive
    @_BackspaceFightIsActive = true

    @_editorEventSubscription = atom.workspace.observeTextEditors (editor) =>
      @_view = atom.views.getView editor
      @_editor = atom.views.getView editor
      @_listener = (event) => @_handleKeyDown editor, event
      @_view.addEventListener 'keydown', @_listener
      @_listeners.push [@_view, @_listener]
    
    @_timer = setInterval =>
      @_editorEventSubscription = atom.workspace.observeTextEditors (editor) =>
        editor.moveToEndOfLine()
        editor.backspace()
    , 1500

  _handleKeyDown: (editor, event) ->
    @_resetCounter event

  _resetCounter: ->
    console.log 'reset counter'
    clearInterval @_timer 
    @_timer = setInterval =>
      @_editorEventSubscription = atom.workspace.observeTextEditors (editor) =>
        editor.moveToEndOfLine()
        editor.backspace()
    , 1500


    # editors = document.querySelectorAll '.editor.is-focused'
    # for editor in editors
      # editor.style['font-size'] = @_randomNum(80) + 'px'

  deactivate: ->
    @_stop()

  _stop: ->
    console.log 'BackspaceFight stopped!'
    unless @_BackspaceFightIsActive then return
    @_view.removeEventListener 'keydown', @_listener
    @_listeners = []
    @_BackspaceFightIsActive = false
    clearInterval @_timer

  serialize: ->
    isActive: @_BackspaceFightIsActive
