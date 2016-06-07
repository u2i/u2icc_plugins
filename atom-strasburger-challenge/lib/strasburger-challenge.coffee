{CompositeDisposable} = require 'atom'

module.exports = Strassburger =
  _isActive: false
  _handler: null

  activate: ->
    @_start()

  _start: ->
    if @_isActive then return
    console.log 'Strassburger started!'
    @_isActive = true
    @_includeKarol()

    # document.addEventListener 'keyup', @_handler

  _includeKarol: ->
    karolek = document.querySelectorAll '#karolek'
    if !karolek.length
      editor = document.querySelector '.workspace'
      editor.style['opacity'] = '0.7'
      container = document.createElement("div")
      container.id = "karolek"
      container.style['position'] = 'fixed'
      container.style['width'] = '100%'
      container.style['height'] = '100%'
      container.style['top'] = '0'
      container.style['z-index'] = '-10'
      iframe = document.createElement("iframe")
      container.appendChild(iframe)
      iframe.frameborder = "0"
      iframe.height = "100%"
      iframe.width = "100%"
      iframe.src = "https://www.youtube.com/embed/h2J-xwgtCag?autoplay=1&controls=0&showinfo=0&autohide=1"
      document.querySelector("body").appendChild(container)

  deactivate: ->
    @_stop()

  _stop: ->
    console.log 'Strassburger stopped!'
    unless @_isActive then return

    # document.removeEventListener 'keyup', @_handler
    @_resetKarol()
    @_isActive = false
    @_handler = null

  _resetKarol: ->
    editors = document.querySelectorAll '.editor'
    for editor in editors
      console.log "Reset Strassburger"
      editor.style['opacity'] = '1'


  serialize: ->
    isActive: @_isActive
