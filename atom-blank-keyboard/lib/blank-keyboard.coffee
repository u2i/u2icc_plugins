{CompositeDisposable} = require 'atom'

module.exports = BlankKeyboard =
  _isActive: false

  activate: ->
    @_start()

  _start: ->
    if @_isActive then return
    console.log 'Blank Keyboard started!'
    @_isActive = true

  deactivate: ->
    @_stop()

  _stop: ->
    console.log 'Blank Keyboard stopped!'
    unless @_isActive then return
    @_isActive = false

  serialize: ->
    isActive: @_isActive
