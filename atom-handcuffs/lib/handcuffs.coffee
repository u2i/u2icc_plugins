{CompositeDisposable} = require 'atom'

module.exports = Handcuffs =
  _isActive: false

  activate: ->
    @_start()

  _start: ->
    if @_isActive then return
    console.log 'Handcuffs started!'
    @_isActive = true

  deactivate: ->
    @_stop()

  _stop: ->
    console.log 'Handcuffs stopped!'
    unless @_isActive then return
    @_isActive = false

  serialize: ->
    isActive: @_isActive
