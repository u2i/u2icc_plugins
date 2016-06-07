{CompositeDisposable} = require 'atom'

module.exports = MirrorMode =
  _isActive: false
  _handler: null

  activate: ->
    @_start()

  _start: ->
    if @_isActive then return
    console.log 'MirrorMode started!'
    @_isActive = true
    @_handler = (_) => @_mirrorEditor()

    document.addEventListener 'keyup', @_handler

  _mirrorEditor: ->
    editors = document.querySelectorAll '.editor.is-focused'
    for editor in editors
      editor.style['transform'] = 'rotateY(180deg)'

  deactivate: ->
    @_stop()

  _stop: ->
    console.log 'MirrorMode stopped!'
    unless @_isActive then return

    document.removeEventListener 'keyup', @_handler
    @_resetMirrorMode()
    @_isActive = false
    @_handler = null

  _resetMirrorMode: ->
    editors = document.querySelectorAll '.editor'
    for editor in editors
      console.log "Reset Mirror Mode"
      editor.style['transform'] = 'rotateY(0deg)'

  serialize: ->
    isActive: @_isActive
