{CompositeDisposable} = require 'atom'

module.exports = MirrorMode =
  _isActive: false

  activate: ->
    @_start()

  _start: ->
    if @_isActive then return
    console.log 'MirrorMode started!'
    @_isActive = true
    @_mirrorEditor()

  _mirrorEditor: ->
    setTimeout () ->
      editors = document.querySelectorAll '.editor.is-focused'
      for editor in editors
        editor.style['transform'] = 'rotateY(180deg)'
    , 1500

  deactivate: ->
    @_stop()

  _stop: ->
    console.log 'MirrorMode stopped!'
    unless @_isActive then return
    @_resetMirrorMode()
    @_isActive = false

  _resetMirrorMode: ->
    editors = document.querySelectorAll '.editor'
    for editor in editors
      console.log "Reset Mirror Mode"
      editor.style['transform'] = 'rotateY(0deg)'

  serialize: ->
    isActive: @_isActive
