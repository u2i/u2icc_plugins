{CompositeDisposable} = require 'atom'

module.exports = Flashlight =
  _isActive: false
  _syntaxThemes: []

  _originalThemes: null
  _originalColor: ""
  _originalBackground: ""
  moveLight: null


  activate: ->
    @_start()

  _start: ->
    if @_isActive then return
    console.log 'Flashlight started!'
    @_isActive = true

    @_flashlightEditor()

  _flashlightEditor: ->
    css = document.createElement('style')
    css.type = 'text/css'
    css.id = 'flashlight'
    styles = '.editor .lines .line * { color: #000 !important; }'
    styles += ' .editor lines { background: transparent; }'
    styles += 'atom-text-editor .line.cursor-line {background: transparent !important;}'
    styles += ' .editor .highlights * { color: #000 !important; }'
    styles += ' .editor { color: #000 !important; background-color: #000; background-image: url(https://s3.amazonaws.com/coding.challenge/images/flashlight.png); background-repeat: no-repeat; }'
    styles += ' atom-text-editor.editor .selection .region { background-color: #000; }'
    css.appendChild( document.createTextNode(styles) )
    document.getElementsByTagName("head")[0].appendChild(css)

    setInterval () ->
      editor = document.querySelectorAll '.editor'
      lines = document.querySelector '.editor:nth-child(1) .lines'
      lines.style['background'] = "transparent"
      cont = lines.querySelector('div:first-child')
      cont.classList.add('thisCont')
      conts = document.querySelectorAll(".thisCont > div")
      i = 0
      while i < conts.length
        conts[i].style['background'] = 'transparent'
        i++
      editor[0].removeEventListener "mousemove", (e) ->
        editor[0].style['background-position'] = (e.layerX - 30)+"px "+ (e.layerY - 60)+"px"
      editor[0].addEventListener "mousemove", (e) ->
        editor[0].style['background-position'] = (e.layerX - 30)+"px "+ (e.layerY - 60)+"px"
    , 100

  _removeSyles: ->
    fl = document.getElementById "flashlight"
    document.getElementsByTagName("head")[0].removeChild(fl)

    editor = document.querySelectorAll '.editor'
    editor[0].removeEventListener "mousemove", ""

  deactivate: ->
    @_stop()

  _stop: ->
    console.log 'Flashlight stopped!'
    unless @_isActive then return
    @_removeSyles()
    @_isActive = false

  serialize: ->
    isActive: @_isActive
