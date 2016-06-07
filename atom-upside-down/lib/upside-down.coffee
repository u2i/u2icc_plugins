{CompositeDisposable} = require 'atom'

module.exports = UpsideDown =
  _isActive: false
  _handler: null

  activate: ->
    @_start()

  _start: ->
    if @_isActive then return
    console.log 'UpsideDown started!'
    @_isActive = true
    @_handler = (_) => @_flipIt()

    document.addEventListener 'keyup', @_handler

  _flipIt: ->
    editors = document.querySelectorAll '.editor.is-focused'
    for editor in editors
      editor.style['transform'] = 'rotateX(180deg)'

  deactivate: ->
    @_stop()

  _stop: ->
    console.log 'UpsideDown stopped!'
    unless @_isActive then return

    document.removeEventListener 'keyup', @_handler
    @_resetUpsideDown()
    @_isActive = false
    @_handler = null

  _resetUpsideDown: ->
    editors = document.querySelectorAll '.editor'
    for editor in editors
      console.log "Reset Upside Down"
      editor.style['transform'] = 'rotateX(180deg)'

  serialize: ->
    isActive: @_isActive
