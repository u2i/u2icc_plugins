{CompositeDisposable} = require 'atom'

module.exports = UpsideDown =
  _upsideDownIsActive: false

  activate: ->
    @_start()

  _start: ->
    if @_upsideDownIsActive then return
    console.log 'UpsideDown started!'
    @_upsideDownIsActive = true
    @_flipIt()

  _flipIt: ->
    document.querySelector('body').style['transform'] = 'rotateZ(180deg)'

  deactivate: ->
    @_stop()

  _stop: ->
    console.log 'UpsideDown stopped!'
    unless @_upsideDownIsActive then return

    @_resetUpsideDown()
    @_upsideDownIsActive = false
    @_handler = null

  _resetUpsideDown: ->

    document.querySelector('body').style['transform'] = 'rotateZ(180deg)'
    console.log "Reset Upside Down"

  serialize: ->
    isActive: @_upsideDownIsActive
