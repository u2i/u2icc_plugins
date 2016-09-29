{CompositeDisposable} = require 'atom'

module.exports = Touchpad =
  _isActive: false

  activate: ->
    @_start()

  _start: ->
    if @_isActive then return
    console.log 'Touchpad started!'
    @_isActive = true

  deactivate: ->
    @_stop()

  _stop: ->
    console.log 'Touchpad stopped!'
    unless @_isActive then return
    @_isActive = false

  serialize: ->
    isActive: @_isActive
