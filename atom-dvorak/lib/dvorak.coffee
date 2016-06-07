{CompositeDisposable} = require 'atom'

module.exports = Dvorak =
  _isActive: false

  activate: ->
    @_start()

  _start: ->
    if @_isActive then return
    console.log 'Dvorak started!'
    @_isActive = true

  deactivate: ->
    @_stop()

  _stop: ->
    console.log 'Dvorak stopped!'
    unless @_isActive then return
    @_isActive = false

  serialize: ->
    isActive: @_isActive
