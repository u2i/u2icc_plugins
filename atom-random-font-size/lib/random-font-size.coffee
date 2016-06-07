{CompositeDisposable} = require 'atom'

module.exports = RandomFontSize =
  _isActive: false
  _handler: null

  activate: ->
    @_start()

  _start: ->
    if @_isActive then return
    console.log 'RandomFontSize started!'
    @_isActive = true
    @_handler = (_) => @_changeFontSize()

    document.addEventListener 'keyup', @_handler

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

    document.removeEventListener 'keyup', @_handler
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
