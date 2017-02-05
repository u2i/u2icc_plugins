{CompositeDisposable} = require 'atom'

module.exports = MirrorMode =
  _mirrorModeIsActive: false

  activate: ->
    @_start()

  _start: ->
    if @_mirrorModeIsActive then return
    console.log 'MirrorMode started!'
    @_mirrorModeIsActive = true
    @_mirrorEditor()

  _mirrorEditor: ->
    document.querySelector('body').style['transform'] = 'rotateY(180deg)'

  deactivate: ->
    @_stop()

  _stop: ->
    console.log 'MirrorMode stopped!'
    unless @_mirrorModeIsActive then return
    @_resetMirrorMode()
    @_mirrorModeIsActive = false

  _resetMirrorMode: ->
    console.log "Reset Mirror Mode"
    document.querySelector('body').style['transform'] = 'rotateY(0deg)'

  serialize: ->
    isActive: @_mirrorModeIsActive
