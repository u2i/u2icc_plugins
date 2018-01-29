{CompositeDisposable} = require 'atom'

module.exports = BackspaceFight =
  _BackspaceFightIsActive: false
  _subscriptions: []
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

    _subscription = atom.workspace.observeTextEditors (editor) =>
      @_view = atom.views.getView editor
      @_editor = atom.views.getView editor
      @_listener = (event) => @_handleKeyDown editor, event
      @_view.addEventListener 'keydown', @_listener
      @_listeners.push [@_view, @_listener]
    @_subscriptions.push(_subscription)
    
    @_timer = setInterval =>
      _subscription = atom.workspace.observeTextEditors (editor) =>
        editor.moveToEndOfLine()
        editor.backspace()
      @_subscriptions.push(_subscription)
    , 1500

  _handleKeyDown: (editor, event) ->
    @_resetCounter event

  _resetCounter: ->
    console.log 'reset counter'
    clearInterval @_timer 
    @_timer = setInterval =>
      _subscription = atom.workspace.observeTextEditors (editor) =>
        editor.moveToEndOfLine()
        editor.backspace()
      @_subscriptions.push(_subscription)
    , 1500


    # editors = document.querySelectorAll '.editor.is-focused'
    # for editor in editors
      # editor.style['font-size'] = @_randomNum(80) + 'px'

  deactivate: ->
    @_stop()

  _stop: ->
    console.log 'BackspaceFight stopped!'
    unless @_BackspaceFightIsActive then return
    @_BackspaceFightIsActive = false
    clearInterval @_timer
    for subscription in @_subscriptions
      subscription.dispose()
    @_subscriptions = []
    for [view, listener] in @_listeners
      view.removeEventListener 'keydown', listener
    @_listeners = []

  serialize: ->
    isActive: @_BackspaceFightIsActive
