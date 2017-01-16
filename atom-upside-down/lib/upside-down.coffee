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
    @_flipIt()

  _flipIt: ->
    setTimeout () ->
      editors = document.querySelectorAll '.editor'
      console.log editors
      for editor in editors
        console.log editor
        editor.style['transform'] = 'rotateX(180deg)'
    , 2000

  deactivate: ->
    @_stop()

  _stop: ->
    console.log 'UpsideDown stopped!'
    unless @_isActive then return

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
